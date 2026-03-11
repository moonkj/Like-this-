import Flutter
import UIKit

/// Like This 카메라 채널 — AVFoundation 실제 구현
final class LikeThisCamera: NSObject {

    static var shared: LikeThisCamera?

    private let cameraChannel: FlutterMethodChannel
    private let filterChannel: FlutterMethodChannel
    private let bwEngine = MFBWEngine()
    private var cameraSession: MFCameraSession?
    private let textureRegistry: FlutterTextureRegistry

    private init(messenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry) {
        self.textureRegistry = textureRegistry
        cameraChannel = FlutterMethodChannel(name: "com.likethis/camera_engine", binaryMessenger: messenger)
        filterChannel = FlutterMethodChannel(name: "com.likethis/filter_engine", binaryMessenger: messenger)
        super.init()
        setupHandlers()
    }

    static func setup(messenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry) {
        shared = LikeThisCamera(messenger: messenger, textureRegistry: textureRegistry)
    }

    private func setupHandlers() {
        cameraChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "initialize":
                let args = call.arguments as? [String: Any]
                let front = args?["frontCamera"] as? Bool ?? false
                let session = MFCameraSession(
                    bwEngine: self.bwEngine,
                    registry: self.textureRegistry,
                    frontCamera: front
                )
                self.cameraSession = session
                session.start { textureId in result(textureId) }
            case "dispose":
                self.cameraSession?.stop()
                self.cameraSession = nil
                result(nil)
            case "flipCamera":
                self.cameraSession?.flipCamera()
                result(nil)
            case "pauseSession":
                self.cameraSession?.pause()
                result(nil)
            case "resumeSession":
                self.cameraSession?.resume()
                result(nil)
            case "capturePhoto":
                self.cameraSession?.capturePhoto { path in result(path) }
            case "setExposure":
                let ev = (call.arguments as? [String: Any])?["ev"] as? Double ?? 0.0
                self.cameraSession?.setExposure(Float(ev))
                result(nil)
            case "setZoom":
                let zoom = (call.arguments as? [String: Any])?["zoom"] as? Double ?? 1.0
                self.cameraSession?.setZoom(Float(zoom))
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        filterChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            let args = call.arguments as? [String: Any]
            switch call.method {
            case "loadLUT":
                if let path = args?["assetPath"] as? String {
                    self.bwEngine.loadLUT(assetPath: path)
                }
                result(nil)
            case "updateParams":
                let lutIntensity = Float((args?["lutIntensity"] as? Double) ?? 1.0)
                let grain        = Float((args?["grain"]        as? Double) ?? 0.0)
                let contrast     = Float((args?["contrast"]     as? Double) ?? 0.0)
                let exposure     = Float((args?["exposure"]     as? Double) ?? 0.0)
                let lightLeak    = Float((args?["lightLeak"]    as? Double) ?? 0.0)
                let vignette     = Float((args?["vignette"]     as? Double) ?? 0.0)
                self.bwEngine.updateParams(
                    lutIntensity: lutIntensity, grain: grain, contrast: contrast,
                    exposure: exposure, lightLeak: lightLeak, vignette: vignette
                )
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
