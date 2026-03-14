import AVFoundation
import CoreImage

/// B&W 필터가 적용된 영상 + 오디오를 AVAssetWriter로 파일에 기록
final class MFVideoRecorder {

    private var assetWriter:  AVAssetWriter?
    private var videoInput:   AVAssetWriterInput?
    private var audioInput:   AVAssetWriterInput?
    private var adaptor:      AVAssetWriterInputPixelBufferAdaptor?
    private var startPTS:     CMTime?
    private var outputURL:    URL?

    private(set) var isRecording = false

    // MARK: - Control

    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        startPTS    = nil
        assetWriter = nil
        videoInput  = nil
        audioInput  = nil
        adaptor     = nil
        outputURL   = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
    }

    /// 처리된 B&W CIImage를 영상 트랙에 추가
    func appendVideo(ciImage: CIImage, context: CIContext, at presentationTime: CMTime) {
        guard isRecording else { return }

        // 첫 프레임 도착 시 writer 초기화
        if assetWriter == nil {
            setup(width: Int(ciImage.extent.width), height: Int(ciImage.extent.height))
        }

        guard let input = videoInput, input.isReadyForMoreMediaData,
              let adaptor = adaptor,
              let pool = adaptor.pixelBufferPool else { return }

        let pts: CMTime
        if let start = startPTS {
            pts = CMTimeSubtract(presentationTime, start)
        } else {
            startPTS = presentationTime
            pts = .zero
        }

        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
              let buf = pixelBuffer else { return }
        context.render(ciImage, to: buf, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        adaptor.append(buf, withPresentationTime: pts)
    }

    /// 오디오 샘플버퍼를 그대로 오디오 트랙에 추가
    func appendAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              assetWriter != nil,          // writer가 초기화된 이후에만
              let input = audioInput,
              input.isReadyForMoreMediaData else { return }

        guard let start = startPTS else { return }  // 비디오 첫 프레임 이후에만

        // 오디오 PTS 를 비디오 기준으로 오프셋
        var timing = CMSampleTimingInfo()
        guard CMSampleBufferGetSampleTimingInfo(sampleBuffer, at: 0, timingInfoOut: &timing) == noErr else { return }
        timing.presentationTimeStamp = CMTimeSubtract(timing.presentationTimeStamp, start)

        var adjusted: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(
            allocator: nil,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleBufferOut: &adjusted
        )
        if let buf = adjusted {
            input.append(buf)
        }
    }

    /// 녹화 종료. 완료 후 파일 경로(혹은 nil)를 콜백으로 전달
    func stopRecording(completion: @escaping (String?) -> Void) {
        guard isRecording else { completion(nil); return }
        isRecording = false

        guard let writer = assetWriter else { completion(nil); return }
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        let url = outputURL
        writer.finishWriting {
            if writer.status == .completed, let path = url?.path {
                completion(path)
            } else {
                completion(nil)
            }
        }
        assetWriter = nil
        videoInput  = nil
        audioInput  = nil
        adaptor     = nil
    }

    // MARK: - Private

    private func setup(width: Int, height: Int) {
        guard let url = outputURL,
              let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return }

        // ── 비디오 트랙 ──
        let videoSettings: [String: Any] = [
            AVVideoCodecKey:  AVVideoCodecType.h264,
            AVVideoWidthKey:  width,
            AVVideoHeightKey: height,
        ]
        let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        vInput.expectsMediaDataInRealTime = true

        let sourceAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey  as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
        let adp = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: vInput,
            sourcePixelBufferAttributes: sourceAttrs
        )

        // ── 오디오 트랙 ──
        let audioSettings: [String: Any] = [
            AVFormatIDKey:         kAudioFormatMPEG4AAC,
            AVSampleRateKey:       44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey:   128_000,
        ]
        let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        aInput.expectsMediaDataInRealTime = true

        writer.add(vInput)
        writer.add(aInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        assetWriter = writer
        videoInput  = vInput
        audioInput  = aInput
        adaptor     = adp
    }
}
