import AVFoundation
import CoreImage

/// B&W 필터가 적용된 영상을 AVAssetWriter로 파일에 기록
final class MFVideoRecorder {

    private var assetWriter:  AVAssetWriter?
    private var videoInput:   AVAssetWriterInput?
    private var adaptor:      AVAssetWriterInputPixelBufferAdaptor?
    private var startPTS:     CMTime?
    private var outputURL:    URL?
    private var stopCallback: ((String?) -> Void)?

    private(set) var isRecording = false

    // MARK: - Control

    /// 녹화 시작. 첫 프레임이 도착하면 실제로 writer 초기화 (lazy).
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        startPTS    = nil
        assetWriter = nil
        videoInput  = nil
        adaptor     = nil
        outputURL   = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
    }

    /// 처리된 CIImage를 영상 파일에 추가
    func append(ciImage: CIImage, context: CIContext, at presentationTime: CMTime) {
        guard isRecording else { return }

        // 첫 프레임 도착 시 writer 초기화
        if assetWriter == nil {
            let w = Int(ciImage.extent.width)
            let h = Int(ciImage.extent.height)
            setup(width: w, height: h)
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
        context.render(ciImage, to: buf)
        adaptor.append(buf, withPresentationTime: pts)
    }

    /// 녹화 종료. 완료 후 파일 경로(혹은 nil)를 콜백으로 전달
    func stopRecording(completion: @escaping (String?) -> Void) {
        guard isRecording else { completion(nil); return }
        isRecording = false

        guard let writer = assetWriter else { completion(nil); return }
        videoInput?.markAsFinished()
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
        adaptor     = nil
    }

    // MARK: - Private

    private func setup(width: Int, height: Int) {
        guard let url = outputURL,
              let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey:  AVVideoCodecType.h264,
            AVVideoWidthKey:  width,
            AVVideoHeightKey: height,
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true

        let sourceAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey  as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
        let adp = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourceAttrs
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        assetWriter = writer
        videoInput  = input
        adaptor     = adp
    }
}
