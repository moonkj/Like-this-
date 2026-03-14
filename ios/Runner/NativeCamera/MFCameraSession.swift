import AudioToolbox
import AVFoundation
import Flutter
import UIKit

/// Like This 카메라 세션 — B&W 엔진 파이프라인 통합
final class MFCameraSession: NSObject {

    private let captureSession = AVCaptureSession()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private let audioOutput    = AVCaptureAudioDataOutput()
    private let photoOutput    = AVCapturePhotoOutput()
    private let sessionQueue   = DispatchQueue(label: "com.likethis.camera.session", qos: .userInteractive)
    private let audioQueue     = DispatchQueue(label: "com.likethis.camera.audio", qos: .userInteractive)

    private var currentDevice: AVCaptureDevice?
    private var isFront: Bool

    let bwEngine: MFBWEngine
    private let textureRegistry: FlutterTextureRegistry
    private var registeredTextureId: Int64 = -1

    // 처리된 CIImage (sessionQueue 생산 / Flutter texture 소비)
    private let imageLock = NSLock()
    private var latestProcessedImage: CIImage?

    // 출력 CVPixelBuffer 풀
    private var outputBufferPool: CVPixelBufferPool?

    private var photoCaptureCompletion: ((String?) -> Void)?
    private var photoCapturePlaySound = false
    private var recordingPlaySound    = false
    private let videoRecorder = MFVideoRecorder()

    init(bwEngine: MFBWEngine, registry: Any, frontCamera: Bool) {
        self.bwEngine       = bwEngine
        self.textureRegistry = registry as! FlutterTextureRegistry
        self.isFront        = frontCamera
        super.init()
    }

    // MARK: - Session Control

    func start(completion: @escaping (Int64) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setupSession()
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                let id = self.textureRegistry.register(self)
                self.registeredTextureId = id
                completion(id)
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.registeredTextureId >= 0 else { return }
            self.textureRegistry.unregisterTexture(self.registeredTextureId)
            self.registeredTextureId = -1
        }
    }

    func pause() { sessionQueue.async { [weak self] in self?.captureSession.stopRunning() } }
    func resume() { sessionQueue.async { [weak self] in self?.captureSession.startRunning() } }

    func flipCamera() {
        isFront.toggle()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            // 비디오 입력 재추가
            let pos: AVCaptureDevice.Position = self.isFront ? .front : .back
            if let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
               let inp = try? AVCaptureDeviceInput(device: dev),
               self.captureSession.canAddInput(inp) {
                self.captureSession.addInput(inp)
                self.currentDevice = dev
            }
            // 오디오 입력 재추가 (removeInput으로 제거됐으므로)
            if let audioDev = AVCaptureDevice.default(for: .audio),
               let audioInp = try? AVCaptureDeviceInput(device: audioDev),
               self.captureSession.canAddInput(audioInp) {
                self.captureSession.addInput(audioInp)
            }
            self.captureSession.commitConfiguration()
            // commitConfiguration 이후에 connection이 확립됨 → rotation 적용
            self.fixVideoOrientation()
            // 기존 버퍼 풀 & 이전 프레임 리셋 (카메라 치수 변경에 대응)
            self.outputBufferPool = nil
            self.imageLock.lock()
            self.latestProcessedImage = nil
            self.imageLock.unlock()
        }
    }

    func setExposure(_ ev: Float) {
        guard let dev = currentDevice else { return }
        let clamped = min(max(ev, dev.minExposureTargetBias), dev.maxExposureTargetBias)
        try? dev.lockForConfiguration()
        dev.setExposureTargetBias(clamped, completionHandler: nil)
        dev.unlockForConfiguration()
    }

    func setZoom(_ zoom: Float) {
        guard let dev = currentDevice else { return }
        let maxZ = min(dev.activeFormat.videoMaxZoomFactor, 6.0)
        let z = min(max(CGFloat(zoom), 1.0), maxZ)
        try? dev.lockForConfiguration()
        dev.videoZoomFactor = z
        dev.unlockForConfiguration()
    }

    func capturePhoto(shutterSound: Bool, completion: @escaping (String?) -> Void) {
        photoCaptureCompletion = completion
        photoCapturePlaySound  = shutterSound
        if !shutterSound {
            // 시스템 자동 셔터음 억제: AVAudioSession 카테고리를 playback으로 전환
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func setFlash(mode: String) {
        guard let dev = currentDevice, dev.hasTorch else { return }
        try? dev.lockForConfiguration()
        switch mode {
        case "on":   dev.torchMode = .on
        case "auto": dev.torchMode = .auto
        default:     dev.torchMode = .off
        }
        dev.unlockForConfiguration()
    }

    func startRecording(shutterSound: Bool) {
        recordingPlaySound = shutterSound
        if shutterSound { AudioServicesPlaySystemSound(1117) } // begin-recording
        videoRecorder.startRecording()
    }

    func stopRecording(completion: @escaping (String?) -> Void) {
        if recordingPlaySound { AudioServicesPlaySystemSound(1118) } // end-recording
        videoRecorder.stopRecording(completion: completion)
    }

    // MARK: - Private Setup

    private func setupSession() {
        captureSession.beginConfiguration()
        // .photo = 고해상도 정방형 센서 전체 (FOV 넓음, 처리 부하 큼)
        // .hd1920x1080 = 16:9 표준 화각 (iOS 카메라앱 기본값과 유사)
        captureSession.sessionPreset = .hd1920x1080

        let pos: AVCaptureDevice.Position = isFront ? .front : .back
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
              let inp = try? AVCaptureDeviceInput(device: dev) else {
            captureSession.commitConfiguration(); return
        }
        currentDevice = dev
        if captureSession.canAddInput(inp)         { captureSession.addInput(inp) }

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }

        // ── 오디오 입력 + 출력 ──
        if let audioDev = AVCaptureDevice.default(for: .audio),
           let audioInp = try? AVCaptureDeviceInput(device: audioDev),
           captureSession.canAddInput(audioInp) {
            captureSession.addInput(audioInp)
        }
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        if captureSession.canAddOutput(audioOutput) { captureSession.addOutput(audioOutput) }

        fixVideoOrientation()
        captureSession.commitConfiguration()
    }

    private func fixVideoOrientation() {
        guard let conn = videoOutput.connection(with: .video) else { return }
        // iOS 17+ 에서 videoOrientation deprecated → videoRotationAngle 사용
        if #available(iOS 17.0, *) {
            if conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90   // portrait = 90°
            }
        } else {
            if conn.isVideoOrientationSupported { conn.videoOrientation = .portrait }
        }
        // 전면 카메라 미러는 네이티브에서만 처리 (Flutter Transform 없음)
        if conn.isVideoMirroringSupported { conn.isVideoMirrored = isFront }
    }

    /// 첫 프레임 도착 시 출력 버퍼 풀 생성 (처리된 이미지 기준 크기)
    private func makeOutputPool(width: Int, height: Int) {
        guard outputBufferPool == nil else { return }
        let attrs: NSDictionary = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey:  width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:],
        ]
        CVPixelBufferPoolCreate(nil, nil, attrs, &outputBufferPool)
    }
}

// MARK: - FlutterTexture

extension MFCameraSession: FlutterTexture {
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        imageLock.lock()
        let image = latestProcessedImage
        imageLock.unlock()
        guard let ciImage = image, let pool = outputBufferPool else { return nil }

        var outBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outBuffer) == kCVReturnSuccess,
              let buf = outBuffer else { return nil }
        bwEngine.render(ciImage, to: buf)
        return Unmanaged.passRetained(buf)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate + AVCaptureAudioDataOutputSampleBufferDelegate

extension MFCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // ── 오디오 버퍼 ──
        if output === audioOutput {
            videoRecorder.appendAudio(sampleBuffer: sampleBuffer)
            return
        }

        guard let rawBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bwEngine.detectFaces(in: rawBuffer)

        // connection 레벨 회전이 적용 안됐을 때(landscape 버퍼)를 CIImage 레벨에서 보정
        var inputImage = CIImage(cvPixelBuffer: rawBuffer)
        if inputImage.extent.width > inputImage.extent.height {
            inputImage = inputImage.oriented(.right)
        }
        makeOutputPool(width: Int(inputImage.extent.width), height: Int(inputImage.extent.height))
        let processed = bwEngine.buildImage(from: inputImage)
        imageLock.lock()
        latestProcessedImage = processed
        imageLock.unlock()
        if registeredTextureId >= 0 {
            textureRegistry.textureFrameAvailable(registeredTextureId)
        }
        if videoRecorder.isRecording {
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            var captureFrame = bwEngine.buildImageForCapture(from: inputImage)
            // 3:4 비율로 center-crop (세로 영상: 1080×1920 → 1080×1440)
            let ext = captureFrame.extent
            if ext.height > ext.width {
                let targetH = (ext.width * 4.0 / 3.0).rounded()
                let yOff    = ((ext.height - targetH) / 2.0).rounded()
                captureFrame = captureFrame.cropped(to: CGRect(
                    x: ext.origin.x, y: ext.origin.y + yOff,
                    width: ext.width, height: targetH
                ))
            }
            // origin을 (0,0)으로 정규화 — 픽셀버퍼 렌더링 오프셋 방지
            let o = captureFrame.extent.origin
            if o.x != 0 || o.y != 0 {
                captureFrame = captureFrame.transformed(by: CGAffineTransform(translationX: -o.x, y: -o.y))
            }
            videoRecorder.appendVideo(ciImage: captureFrame, context: bwEngine.context, at: pts)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension MFCameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        defer {
            photoCaptureCompletion = nil
            // 셔터음 억제를 위해 변경한 AudioSession 복구 (녹화용 playAndRecord)
            if !photoCapturePlaySound {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .mixWithOthers])
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
        guard error == nil, let data = photo.fileDataRepresentation() else {
            photoCaptureCompletion?(nil); return
        }

        // JPEG → CIImage. 비디오 스트림과 동일: 픽셀 크기로만 회전 여부 판단
        // (metadata orientation은 신뢰도가 낮음 — 이미 portrait인 경우 오회전 발생)
        var ciInput = CIImage(data: data) ?? CIImage.empty()
        if ciInput.extent.width > ciInput.extent.height {
            ciInput = ciInput.oriented(.right)   // landscape 센서 데이터만 회전
        }

        var processed = bwEngine.buildImageForCapture(from: ciInput)
        // 3:4 비율로 center-crop (사진: 1080×1920 → 1080×1440)
        let pExt = processed.extent
        if pExt.height > pExt.width {
            let targetH = (pExt.width * 4.0 / 3.0).rounded()
            let yOff    = ((pExt.height - targetH) / 2.0).rounded()
            processed = processed.cropped(to: CGRect(
                x: pExt.origin.x, y: pExt.origin.y + yOff,
                width: pExt.width, height: targetH
            ))
        }
        guard let cgImage = bwEngine.context.createCGImage(processed, from: processed.extent) else {
            photoCaptureCompletion?(nil); return
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.95) else {
            photoCaptureCompletion?(nil); return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try jpegData.write(to: url)
            photoCaptureCompletion?(url.path)
        } catch {
            photoCaptureCompletion?(nil)
        }
    }
}
