import AVFoundation
import Flutter
import UIKit

/// Like This 카메라 세션 — AVFoundation 실제 구현
final class MFCameraSession: NSObject {

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.likethis.camera.session", qos: .userInteractive)

    private var currentDevice: AVCaptureDevice?
    private var isFront: Bool

    private let bwEngine: MFBWEngine
    private let textureRegistry: FlutterTextureRegistry
    private var registeredTextureId: Int64 = -1
    private var latestPixelBuffer: CVPixelBuffer?

    private var photoCaptureCompletion: ((String?) -> Void)?

    init(bwEngine: MFBWEngine, registry: Any, frontCamera: Bool) {
        self.bwEngine = bwEngine
        self.textureRegistry = registry as! FlutterTextureRegistry
        self.isFront = frontCamera
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

    func pause() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func resume() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func flipCamera() {
        isFront.toggle()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            let position: AVCaptureDevice.Position = self.isFront ? .front : .back
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let input = try? AVCaptureDeviceInput(device: device),
               self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.currentDevice = device
            }
            self.fixVideoOrientation()
            self.captureSession.commitConfiguration()
        }
    }

    func setExposure(_ ev: Float) {
        guard let device = currentDevice else { return }
        let lo = device.minExposureTargetBias
        let hi = device.maxExposureTargetBias
        let clamped = min(max(ev, lo), hi)
        try? device.lockForConfiguration()
        device.setExposureTargetBias(clamped, completionHandler: nil)
        device.unlockForConfiguration()
    }

    func setZoom(_ zoom: Float) {
        guard let device = currentDevice else { return }
        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 6.0)
        let clamped = min(max(CGFloat(zoom), 1.0), maxZoom)
        try? device.lockForConfiguration()
        device.videoZoomFactor = clamped
        device.unlockForConfiguration()
    }

    func capturePhoto(completion: @escaping (String?) -> Void) {
        photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Private

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        let position: AVCaptureDevice.Position = isFront ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        currentDevice = device

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        fixVideoOrientation()
        captureSession.commitConfiguration()
    }

    private func fixVideoOrientation() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = isFront
        }
    }
}

// MARK: - FlutterTexture

extension MFCameraSession: FlutterTexture {
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let buffer = latestPixelBuffer else { return nil }
        return Unmanaged.passRetained(buffer)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension MFCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestPixelBuffer = pixelBuffer
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
        guard error == nil, let data = photo.fileDataRepresentation() else {
            photoCaptureCompletion?(nil)
            return
        }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            photoCaptureCompletion?(url.path)
        } catch {
            photoCaptureCompletion?(nil)
        }
    }
}
