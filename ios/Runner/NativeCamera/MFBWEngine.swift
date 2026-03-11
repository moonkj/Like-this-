import CoreImage
import Foundation

/// Like This B&W 렌더링 엔진 — CoreImage 기반 실제 구현
/// 각 필터의 톤 커브 + 개별 효과 (Grain, Vignette, Bloom, Dust, PaperTone) 처리
final class MFBWEngine {

    let context: CIContext

    // 현재 활성 상태
    private(set) var activeFilterId: String = "bw_pure"
    // 모두 0.0~1.0 정규화 스케일 (Dart에서 /100 후 전송)
    private var _lutIntensity: Float = 1.0
    private var _grain: Float = 0.0   // 초기화 전 효과 없음
    private var _contrast: Float = 0.0
    private var _exposure: Float = 0.0
    private var _lightLeak: Float = 0.0
    private var _vignette: Float = 0.0 // 초기화 전 효과 없음

    // LUT 캐시: filterId → Float32 RGBA 데이터
    private var lutCache: [String: Data] = [:]
    private var lutSize: Int = 17

    init() {
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
            .useSoftwareRenderer: false,
        ]
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device, options: options)
        } else {
            context = CIContext(options: options)
        }
    }

    // MARK: - Public API

    func loadLUT(assetPath: String) {
        let filename = URL(fileURLWithPath: assetPath).lastPathComponent
        let filterId = String(filename.prefix(filename.count - 5)) // drop .cube
        activeFilterId = filterId
        guard lutCache[filterId] == nil else { return }
        let fullPath = Bundle.main.bundlePath + "/flutter_assets/" + assetPath
        if let data = parseCubeFile(at: fullPath) {
            lutCache[filterId] = data
        }
    }

    private var _dust: Float = 0.0
    private var _bloom: Float = 0.0
    private var _compareMode: Bool = false

    func updateParams(lutIntensity: Float, grain: Float, contrast: Float,
                      exposure: Float, lightLeak: Float, vignette: Float,
                      dust: Float = 0.0, bloom: Float = 0.0) {
        _lutIntensity = lutIntensity
        _grain = grain
        _contrast = contrast
        _exposure = exposure
        _lightLeak = lightLeak
        _vignette = vignette
        _dust = dust
        _bloom = bloom
    }

    func setCompareMode(_ enabled: Bool) {
        _compareMode = enabled
    }

    /// CIImage 빌드 — 프리뷰용 (CVPixelBuffer)
    func buildImage(from pixelBuffer: CVPixelBuffer) -> CIImage {
        buildImage(from: CIImage(cvPixelBuffer: pixelBuffer))
    }

    /// CIImage 빌드 — 캡처용 (CIImage 직접)
    func buildImage(from input: CIImage) -> CIImage {
        let processed = buildProcessed(from: input)
        if _compareMode {
            return makeSplitImage(original: input, processed: processed)
        }
        return processed
    }

    private func buildProcessed(from input: CIImage) -> CIImage {
        let bwBase = toBW(input)
        let toned  = applyTone(bwBase)
        let blended = blend(from: bwBase, to: toned, amount: CGFloat(_lutIntensity))
        var image = applyExposureContrast(blended)
        image = applyEffects(image)
        return image.cropped(to: input.extent)
    }

    /// 비교 모드: 왼쪽 절반 = 원본 컬러, 오른쪽 절반 = B&W 필터 적용
    private func makeSplitImage(original: CIImage, processed: CIImage) -> CIImage {
        let extent = original.extent
        let midX   = extent.midX
        let leftRect  = CGRect(x: extent.minX, y: extent.minY,
                               width: midX - extent.minX, height: extent.height)
        let rightRect = CGRect(x: midX, y: extent.minY,
                               width: extent.maxX - midX, height: extent.height)
        let leftHalf  = original.cropped(to: leftRect)
        let rightHalf = processed.cropped(to: rightRect)
        guard let comp = CIFilter(name: "CISourceOverCompositing") else { return original }
        comp.setValue(rightHalf, forKey: kCIInputImageKey)
        comp.setValue(leftHalf,  forKey: kCIInputBackgroundImageKey)
        return comp.outputImage?.cropped(to: extent) ?? original
    }

    /// 두 이미지 선형 블렌드 (CIDissolveTransition)
    private func blend(from base: CIImage, to target: CIImage, amount: CGFloat) -> CIImage {
        guard amount < 0.99 else { return target }
        guard amount > 0.01 else { return base }
        guard let f = CIFilter(name: "CIDissolveTransition") else { return target }
        f.setValue(base,   forKey: kCIInputImageKey)
        f.setValue(target, forKey: kCIInputTargetImageKey)
        f.setValue(amount, forKey: kCIInputTimeKey)
        return f.outputImage ?? target
    }

    func render(_ image: CIImage, to pixelBuffer: CVPixelBuffer) {
        context.render(image, to: pixelBuffer,
                       bounds: image.extent,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    // MARK: - B&W 변환 (채널 믹서)

    private func toBW(_ image: CIImage) -> CIImage {
        guard let f = CIFilter(name: "CIColorMatrix") else { return image }
        let lum = CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
        f.setValue(image, forKey: kCIInputImageKey)
        f.setValue(lum,   forKey: "inputRVector")
        f.setValue(lum,   forKey: "inputGVector")
        f.setValue(lum,   forKey: "inputBVector")
        f.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        f.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        return f.outputImage ?? image
    }

    // MARK: - 톤 커브 (LUT 또는 CIToneCurve 폴백)

    private func applyTone(_ image: CIImage) -> CIImage {
        // LUT 캐시가 있으면 CIColorCube 사용
        if let data = lutCache[activeFilterId] {
            guard let f = CIFilter(name: "CIColorCube") else { return applyToneCurve(image) }
            f.setValue(image,   forKey: kCIInputImageKey)
            f.setValue(lutSize, forKey: "inputCubeDimension")
            f.setValue(data as NSData, forKey: "inputCubeData")
            return f.outputImage ?? applyToneCurve(image)
        }
        return applyToneCurve(image)
    }

    /// LUT 없을 때 사용하는 CIToneCurve 근사
    private func applyToneCurve(_ image: CIImage) -> CIImage {
        guard let f = CIFilter(name: "CIToneCurve") else { return image }
        f.setValue(image, forKey: kCIInputImageKey)

        let pts: [(CGFloat, CGFloat)]

        switch activeFilterId {
        case "bw_noir":
            // 강한 S-커브: 짙은 블랙, 밝은 하이라이트
            pts = [(0.0, 0.0), (0.20, 0.07), (0.50, 0.50), (0.80, 0.93), (1.0, 1.0)]
        case "bw_soft":
            // 연필 소묘: 컨트라스트 완화, 블랙 리프트
            pts = [(0.0, 0.04), (0.25, 0.27), (0.50, 0.52), (0.75, 0.76), (1.0, 0.94)]
        case "bw_2k":
            // 2000년대 디카: 플랫, 블랙 살짝 들림
            pts = [(0.0, 0.03), (0.25, 0.26), (0.50, 0.50), (0.75, 0.75), (1.0, 0.96)]
        case "bw_dust":
            // 빈티지 필름: 페이디드, 무딘 하이라이트
            pts = [(0.0, 0.05), (0.25, 0.28), (0.50, 0.52), (0.75, 0.74), (1.0, 0.93)]
        case "bw_glow":
            // 물광: 미드톤 살짝 밝게, 하이라이트 유지
            pts = [(0.0, 0.00), (0.25, 0.27), (0.50, 0.55), (0.75, 0.81), (1.0, 1.00)]
        case "bw_paper":
            // 인쇄물: 블랙 살짝, 하이라이트 살짝 감소
            pts = [(0.0, 0.01), (0.25, 0.24), (0.50, 0.50), (0.75, 0.77), (1.0, 0.97)]
        case "bw_porcelain":
            // 뷰티: 섀도 리프트, 미드톤 밝게
            pts = [(0.0, 0.06), (0.25, 0.32), (0.50, 0.60), (0.75, 0.82), (1.0, 1.00)]
        case "bw_silky":
            // 셀카 뷰티: 전체적으로 부드럽고 밝게
            pts = [(0.0, 0.05), (0.25, 0.30), (0.50, 0.55), (0.75, 0.76), (1.0, 0.93)]
        default: // bw_pure: 화사하고 깨끗
            pts = [(0.0, 0.00), (0.25, 0.24), (0.50, 0.52), (0.75, 0.78), (1.0, 1.00)]
        }

        f.setValue(CIVector(x: pts[0].0, y: pts[0].1), forKey: "inputPoint0")
        f.setValue(CIVector(x: pts[1].0, y: pts[1].1), forKey: "inputPoint1")
        f.setValue(CIVector(x: pts[2].0, y: pts[2].1), forKey: "inputPoint2")
        f.setValue(CIVector(x: pts[3].0, y: pts[3].1), forKey: "inputPoint3")
        f.setValue(CIVector(x: pts[4].0, y: pts[4].1), forKey: "inputPoint4")
        return f.outputImage ?? image
    }

    // MARK: - 제스처 기반 노출 / 대비

    private func applyExposureContrast(_ image: CIImage) -> CIImage {
        guard abs(_exposure) > 0.01 || abs(_contrast) > 0.01 else { return image }
        guard let f = CIFilter(name: "CIColorControls") else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        // _exposure: -1.0 ~ +1.0 → brightness -0.5 ~ +0.5
        f.setValue(Double(_exposure) * 0.5, forKey: kCIInputBrightnessKey)
        // _contrast: -1.0 ~ +1.0 → scale 0.5 ~ 1.5
        f.setValue(1.0 + Double(_contrast) * 0.5, forKey: kCIInputContrastKey)
        f.setValue(0.0, forKey: kCIInputSaturationKey)
        return f.outputImage ?? image
    }

    // MARK: - 효과

    private func applyEffects(_ image: CIImage) -> CIImage {
        var out = image
        if _vignette > 0.01 { out = applyVignette(out) }
        if _grain > 0.01    { out = applyGrain(out) }
        // dust/bloom: 파라미터 강도 우선, 없으면 필터 기본 적용
        let bloomIntensity = _bloom > 0.01 ? _bloom : (activeFilterId == "bw_glow" ? 0.3 : 0.0)
        let dustIntensity  = _dust  > 0.01 ? _dust  : (activeFilterId == "bw_dust" ? 0.4 : 0.0)
        if bloomIntensity > 0.01 { out = applyBloom(out, intensity: bloomIntensity) }
        if dustIntensity  > 0.01 { out = applyDust(out, intensity: dustIntensity) }
        if activeFilterId == "bw_paper" { out = applyPaperTone(out) }
        return out
    }

    private func applyVignette(_ image: CIImage) -> CIImage {
        guard let f = CIFilter(name: "CIVignette") else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        // _vignette: 0.0~1.0 (already normalized by Dart)
        f.setValue(Double(_vignette) * 2.5, forKey: kCIInputIntensityKey)
        f.setValue(1.5, forKey: kCIInputRadiusKey)
        return f.outputImage ?? image
    }

    private func applyGrain(_ image: CIImage) -> CIImage {
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return image }
        let cropped = noise.cropped(to: image.extent)
        guard let mono = CIFilter(name: "CIColorMatrix") else { return image }
        // _grain: 0.0~1.0 (already normalized by Dart)
        let n = CGFloat(_grain) * 0.18
        mono.setValue(cropped, forKey: kCIInputImageKey)
        mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputRVector")
        mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputGVector")
        mono.setValue(CIVector(x: n, y: 0, z: 0, w: 0), forKey: "inputBVector")
        mono.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        guard let grainImg = mono.outputImage else { return image }
        guard let blend = CIFilter(name: "CISoftLightBlendMode") else { return image }
        blend.setValue(grainImg, forKey: kCIInputImageKey)
        blend.setValue(image,    forKey: kCIInputBackgroundImageKey)
        return blend.outputImage ?? image
    }

    private func applyBloom(_ image: CIImage, intensity: Float = 0.65) -> CIImage {
        guard let f = CIFilter(name: "CIBloom") else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        f.setValue(22.0,  forKey: kCIInputRadiusKey)
        f.setValue(Double(intensity) * 2.0, forKey: kCIInputIntensityKey)
        return f.outputImage ?? image
    }

    private func applyDust(_ image: CIImage, intensity: Float = 0.4) -> CIImage {
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return image }
        guard let thresh = CIFilter(name: "CIColorThreshold") else { return image }
        thresh.setValue(noise.cropped(to: image.extent), forKey: kCIInputImageKey)
        // intensity가 높을수록 더 많은 먼지 (threshold 낮춤)
        thresh.setValue(1.0 - Double(intensity) * 0.08, forKey: "inputThreshold")
        guard let dots = thresh.outputImage else { return image }

        guard let alpha = CIFilter(name: "CIColorMatrix") else { return image }
        alpha.setValue(dots, forKey: kCIInputImageKey)
        alpha.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        alpha.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        alpha.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        alpha.setValue(CIVector(x: 0, y: 0, z: 0, w: Double(intensity) * 0.6), forKey: "inputAVector")
        guard let fadedDots = alpha.outputImage else { return image }

        guard let comp = CIFilter(name: "CISourceOverCompositing") else { return image }
        comp.setValue(fadedDots, forKey: kCIInputImageKey)
        comp.setValue(image,     forKey: kCIInputBackgroundImageKey)
        return comp.outputImage ?? image
    }

    private func applyPaperTone(_ image: CIImage) -> CIImage {
        // 약한 따뜻한 오프셋 (인쇄물 느낌)
        guard let f = CIFilter(name: "CIColorMatrix") else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        f.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        f.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        f.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        f.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        f.setValue(CIVector(x: 0.03, y: 0.02, z: -0.02, w: 0), forKey: "inputBiasVector")
        return f.outputImage ?? image
    }

    // MARK: - .cube 파일 파서

    private func parseCubeFile(at path: String) -> Data? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        var floats: [Float32] = []
        var size = 17
        for rawLine in content.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("LUT_3D_SIZE") {
                if let s = line.components(separatedBy: " ").last.flatMap({ Int($0) }) { size = s; lutSize = size }
                continue
            }
            if line.hasPrefix("DOMAIN") || line.hasPrefix("TITLE") { continue }
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 3,
                  let r = Float(parts[0]),
                  let g = Float(parts[1]),
                  let b = Float(parts[2]) else { continue }
            floats.append(r); floats.append(g); floats.append(b); floats.append(1.0)
        }
        let expected = size * size * size * 4
        guard floats.count == expected else { return nil }
        return Data(bytes: floats, count: floats.count * MemoryLayout<Float32>.size)
    }
}
