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

            // ── 갤러리 이미지 처리 후 저장 ───────────────────────────────────────
            case "processAndSaveImage":
                guard let args = call.arguments as? [String: Any],
                      let sourcePath  = args["sourcePath"]  as? String,
                      let matrixVals  = args["colorMatrix"]  as? [Double],
                      let outputPath  = args["outputPath"]  as? String,
                      matrixVals.count == 20
                else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
                    return
                }
                let vigIntensity   = Float((args["vignette"] as? Double) ?? 0.0)
                let grainIntensity = Float((args["grain"]    as? Double) ?? 0.0)
                let cropX = CGFloat((args["cropX"] as? Double) ?? 0.0)
                let cropY = CGFloat((args["cropY"] as? Double) ?? 0.0)
                let cropW = CGFloat((args["cropW"] as? Double) ?? 1.0)
                let cropH = CGFloat((args["cropH"] as? Double) ?? 1.0)
                let hasCrop = cropW < 0.999 || cropH < 0.999 || cropX > 0.001 || cropY > 0.001

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }

                    // 1. 이미지 로드 — UIImage가 HEIC/JPEG/PNG 및 EXIF 방향 자동 처리
                    guard let uiSrc = UIImage(contentsOfFile: sourcePath),
                          let cgSrc = uiSrc.cgImage else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "LOAD_FAILED", message: "Cannot load: \(sourcePath)", details: nil))
                        }
                        return
                    }
                    var processed = CIImage(cgImage: cgSrc)

                    // 2. ColorFilter 적용 (Flutter 4×5 행렬 → CIColorMatrix, bias /255)
                    let m = matrixVals
                    if let f = CIFilter(name: "CIColorMatrix") {
                        f.setValue(processed, forKey: kCIInputImageKey)
                        f.setValue(CIVector(x: m[0],  y: m[1],  z: m[2],  w: m[3]),  forKey: "inputRVector")
                        f.setValue(CIVector(x: m[5],  y: m[6],  z: m[7],  w: m[8]),  forKey: "inputGVector")
                        f.setValue(CIVector(x: m[10], y: m[11], z: m[12], w: m[13]), forKey: "inputBVector")
                        f.setValue(CIVector(x: m[15], y: m[16], z: m[17], w: m[18]), forKey: "inputAVector")
                        f.setValue(CIVector(x: m[4]/255, y: m[9]/255, z: m[14]/255, w: m[19]/255),
                                   forKey: "inputBiasVector")
                        if let out = f.outputImage { processed = out }
                    }

                    // 3. 비네팅
                    if vigIntensity > 0.01 {
                        if let f = CIFilter(name: "CIVignette") {
                            f.setValue(processed, forKey: kCIInputImageKey)
                            f.setValue(Double(vigIntensity) * 2.5, forKey: kCIInputIntensityKey)
                            f.setValue(1.5, forKey: kCIInputRadiusKey)
                            if let out = f.outputImage { processed = out }
                        }
                    }

                    // 4. 그레인
                    if grainIntensity > 0.01 {
                        if let noise = CIFilter(name: "CIRandomGenerator")?.outputImage {
                            let croppedNoise = noise.cropped(to: processed.extent)
                            if let mono = CIFilter(name: "CIColorMatrix") {
                                let n = CGFloat(grainIntensity) * 0.18
                                mono.setValue(croppedNoise, forKey: kCIInputImageKey)
                                mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputRVector")
                                mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputGVector")
                                mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputBVector")
                                mono.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
                                if let grainImg = mono.outputImage,
                                   let blend = CIFilter(name: "CISoftLightBlendMode") {
                                    blend.setValue(grainImg, forKey: kCIInputImageKey)
                                    blend.setValue(processed, forKey: kCIInputBackgroundImageKey)
                                    if let out = blend.outputImage { processed = out }
                                }
                            }
                        }
                    }

                    // 5. 크롭 (Flutter top-left Y → CIImage bottom-left Y 변환)
                    if hasCrop {
                        let ext = processed.extent
                        let ci_x = ext.origin.x + cropX * ext.width
                        let ci_y = ext.origin.y + (1.0 - cropY - cropH) * ext.height
                        processed = processed.cropped(to: CGRect(
                            x: ci_x, y: ci_y,
                            width: cropW * ext.width, height: cropH * ext.height
                        ))
                    }

                    // 6. JPEG 렌더링 & 저장
                    guard let cgOut = self.bwEngine.context.createCGImage(processed, from: processed.extent) else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "RENDER_FAILED", message: "createCGImage failed", details: nil))
                        }
                        return
                    }
                    guard let jpegData = UIImage(cgImage: cgOut).jpegData(compressionQuality: 0.92) else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "ENCODE_FAILED", message: "jpegData failed", details: nil))
                        }
                        return
                    }
                    let outURL = URL(fileURLWithPath: outputPath)
                    try? FileManager.default.removeItem(at: outURL)
                    do {
                        try jpegData.write(to: outURL)
                        DispatchQueue.main.async { result(outputPath) }
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
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
            case "setNoneMode":
                let enabled = args?["enabled"] as? Bool ?? false
                self.bwEngine.setNoneMode(enabled)
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
