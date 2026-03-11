import AVFoundation
import Flutter
import UIKit

/// Like This 카메라 세션 — B&W 엔진 파이프라인 통합
final class MFCameraSession: NSObject {

    private let captureSession = AVCaptureSession()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private let photoOutput    = AVCapturePhotoOutput()
    private let sessionQueue   = DispatchQueue(label: "com.likethis.camera.session", qos: .userInteractive)

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
            let pos: AVCaptureDevice.Position = self.isFront ? .front : .back
            if let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
               let inp = try? AVCaptureDeviceInput(device: dev),
               self.captureSession.canAddInput(inp) {
                self.captureSession.addInput(inp)
                self.currentDevice = dev
            }
            self.fixVideoOrientation()
            self.captureSession.commitConfiguration()
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

    func capturePhoto(completion: @escaping (String?) -> Void) {
        photoCaptureCompletion = completion
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

    func startRecording() {
        // MFVideoRecorder 연동은 별도 구현 — 현재 stub
    }

    func stopRecording(completion: @escaping (String?) -> Void) {
        completion(nil)
    }

    // MARK: - Private Setup

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

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

        fixVideoOrientation()
        captureSession.commitConfiguration()
    }

    private func fixVideoOrientation() {
        guard let conn = videoOutput.connection(with: .video) else { return }
        if conn.isVideoOrientationSupported { conn.videoOrientation = .portrait }
        if conn.isVideoMirroringSupported   { conn.isVideoMirrored = isFront }
    }

    /// 첫 프레임 도착 시 출력 버퍼 풀 생성
    private func makeOutputPool(matching pixelBuffer: CVPixelBuffer) {
        guard outputBufferPool == nil else { return }
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        let attrs: NSDictionary = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey:  w,
            kCVPixelBufferHeightKey: h,
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension MFCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let rawBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bwEngine.detectFaces(in: rawBuffer)
        makeOutputPool(matching: rawBuffer)
        let processed = bwEngine.buildImage(from: rawBuffer)
        imageLock.lock()
        latestProcessedImage = processed
        imageLock.unlock()
        if registeredTextureId >= 0 {
            textureRegistry.textureFrameAvailable(registeredTextureId)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension MFCameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        defer { photoCaptureCompletion = nil }
        guard error == nil, let data = photo.fileDataRepresentation(),
              let ciInput = CIImage(data: data) else {
            photoCaptureCompletion?(nil); return
        }

        // B&W 엔진 적용
        let processed = bwEngine.buildImage(from: ciInput)
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
