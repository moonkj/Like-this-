import AVFoundation
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

            // ── 플래시 ──────────────────────────────────────────────────────
            case "setFlash":
                let mode = (call.arguments as? [String: Any])?["mode"] as? String ?? "off"
                self.cameraSession?.setFlash(mode: mode)
                result(nil)

            // ── 동영상 녹화 ─────────────────────────────────────────────────
            case "startRecording":
                self.cameraSession?.startRecording()
                result(nil)
            case "stopRecording":
                self.cameraSession?.stopRecording { path in result(path) }

            // ── 비교 모드 ───────────────────────────────────────────────────
            case "setCompareMode":
                let enable = (call.arguments as? [String: Any])?["enable"] as? Bool ?? false
                self.bwEngine.setCompareMode(enable)
                result(nil)

            case "setSplitPosition":
                let pos = CGFloat((call.arguments as? [String: Any])?["position"] as? Double ?? 0.5)
                self.bwEngine.setSplitPosition(pos)
                result(nil)

            // ── 뷰티 모드 ────────────────────────────────────────────────────
            case "setBeauty":
                let mode      = (call.arguments as? [String: Any])?["mode"]      as? String ?? "none"
                let intensity = Float((call.arguments as? [String: Any])?["intensity"] as? Double ?? 0.0)
                self.bwEngine.setBeauty(mode: mode, intensity: intensity)
                result(nil)

            // ── 동영상 크롭 ─────────────────────────────────────────────────
            case "cropVideo":
                guard let args = call.arguments as? [String: Any],
                      let inputPath  = args["inputPath"]  as? String,
                      let outputPath = args["outputPath"] as? String,
                      let x = args["x"] as? Double,
                      let y = args["y"] as? Double,
                      let w = args["width"]  as? Double,
                      let h = args["height"] as? Double
                else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing crop arguments", details: nil))
                    return
                }
                let asset = AVURLAsset(url: URL(fileURLWithPath: inputPath))
                guard let track = asset.tracks(withMediaType: .video).first,
                      let exportSession = AVAssetExportSession(
                          asset: asset, presetName: AVAssetExportPresetHighestQuality)
                else {
                    result(FlutterError(code: "CROP_FAILED", message: "Cannot load video track", details: nil))
                    return
                }
                // 디바이스 회전 보정: preferredTransform → 실제 표시 크기 계산
                let naturalSize = track.naturalSize
                let transform   = track.preferredTransform
                let transformed = naturalSize.applying(transform)
                let displayW    = abs(transformed.width)
                let displayH    = abs(transformed.height)
                let cropRect = CGRect(
                    x: CGFloat(x) * displayW,
                    y: CGFloat(y) * displayH,
                    width:  CGFloat(w) * displayW,
                    height: CGFloat(h) * displayH
                )
                // 비디오 컴포지션 생성
                let composition = AVMutableVideoComposition()
                composition.renderSize = cropRect.size
                composition.frameDuration = CMTime(value: 1, timescale: 30)
                let layerInst = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
                let finalTransform = transform.concatenating(
                    CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
                )
                layerInst.setTransform(finalTransform, at: .zero)
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                instruction.layerInstructions = [layerInst]
                composition.instructions = [instruction]
                // 기존 파일 덮어쓰기 방지
                let outURL = URL(fileURLWithPath: outputPath)
                try? FileManager.default.removeItem(at: outURL)
                exportSession.outputURL        = outURL
                exportSession.outputFileType   = .mp4
                exportSession.videoComposition = composition
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        if exportSession.status == .completed {
                            result(outputPath)
                        } else {
                            result(FlutterError(
                                code: "EXPORT_FAILED",
                                message: exportSession.error?.localizedDescription,
                                details: nil
                            ))
                        }
                    }
                }

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
                let dust         = Float((args?["dust"]         as? Double) ?? 0.0)
                let bloom        = Float((args?["bloom"]        as? Double) ?? 0.0)
                self.bwEngine.updateParams(
                    lutIntensity: lutIntensity, grain: grain, contrast: contrast,
                    exposure: exposure, lightLeak: lightLeak, vignette: vignette,
                    dust: dust, bloom: bloom
                )
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
