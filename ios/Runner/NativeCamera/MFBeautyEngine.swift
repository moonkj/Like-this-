import Foundation
import Vision
import CoreImage

/// Like This 뷰티 엔진 — VisionKit 얼굴 인식 + CIFilter 기반 피부 보정
final class MFBeautyEngine {

    enum BeautyMode: String {
        case soft        // 피부 결 부드럽게
        case glow        // 은은한 광채
        case silky       // 셀카용 매끈
        case faceBright  // 얼굴 밝기 전용
        case shadowLift  // 다크서클·입 주변 리프트
        case skinFocus   // 배경 어둡게, 얼굴 강조
        case softDepth   // 배경 블러, 인물 선명
    }

    private var faceObservations: [VNFaceObservation] = []
    private var faceRequest: VNDetectFaceRectanglesRequest?
    private let sequenceRequestHandler = VNSequenceRequestHandler()

    init() {
        faceRequest = VNDetectFaceRectanglesRequest()
    }

    // MARK: - 얼굴 인식

    func detectFaces(in pixelBuffer: CVPixelBuffer) {
        guard let request = faceRequest else { return }
        try? sequenceRequestHandler.perform(
            [request],
            on: pixelBuffer,
            orientation: .leftMirrored
        )
        faceObservations = request.results ?? []
    }

    // MARK: - Beauty 효과 적용

    func apply(to image: CIImage, mode: BeautyMode, intensity: Float) -> CIImage {
        switch mode {
        case .soft:        return applySoftSkin(image, intensity: intensity)
        case .glow:        return applyGlowMono(image, intensity: intensity)
        case .silky:       return applySilky(image, intensity: intensity)
        case .faceBright:  return applyFaceBrightness(image, intensity: intensity)
        case .shadowLift:  return applyShadowLift(image, intensity: intensity)
        case .skinFocus:   return applySkinFocus(image, intensity: intensity)
        case .softDepth:   return applySoftDepth(image, intensity: intensity)
        }
    }

    // MARK: - Soft Skin: 저주파 블러로 피부 결만 살짝 부드럽게

    private func applySoftSkin(_ image: CIImage, intensity: Float) -> CIImage {
        let blurRadius = Double(intensity) * 8.0
        guard let blurred = CIFilter(
            name: "CIGaussianBlur",
            parameters: [kCIInputImageKey: image, kCIInputRadiusKey: blurRadius]
        )?.outputImage else { return image }

        let mask = faceMask(for: image, softEdge: 20)
        guard let mix = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBackgroundImageKey: blurred,
                kCIInputMaskImageKey: mask
            ]
        )?.outputImage else { return image }
        return mix.cropped(to: image.extent)
    }

    // MARK: - Glow Mono: 하이라이트 주변 소프트 글로우

    private func applyGlowMono(_ image: CIImage, intensity: Float) -> CIImage {
        let bloom = Double(intensity) * 1.5
        guard let glow = CIFilter(
            name: "CIBloom",
            parameters: [
                kCIInputImageKey: image,
                kCIInputRadiusKey: 8.0,
                kCIInputIntensityKey: bloom
            ]
        )?.outputImage else { return image }
        return glow.cropped(to: image.extent)
    }

    // MARK: - Silky: 미드톤 대비 낮추기 + 밝기 보정

    private func applySilky(_ image: CIImage, intensity: Float) -> CIImage {
        let lift = Double(intensity) * 0.18
        guard let toned = CIFilter(
            name: "CIToneCurve",
            parameters: [
                kCIInputImageKey: image,
                "inputPoint0": CIVector(x: 0.0,  y: lift),
                "inputPoint1": CIVector(x: 0.25, y: 0.25 + lift),
                "inputPoint2": CIVector(x: 0.5,  y: 0.5  + lift * 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.75),
                "inputPoint4": CIVector(x: 1.0,  y: 0.97)
            ]
        )?.outputImage else { return image }
        return toned.cropped(to: image.extent)
    }

    // MARK: - Face Brightness: 얼굴 영역만 밝기 올리기

    func applyFaceBrightness(_ image: CIImage, intensity: Float) -> CIImage {
        let boost = Double(intensity) * 0.35
        guard let brightened = CIFilter(
            name: "CIColorControls",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBrightnessKey: boost,
                kCIInputContrastKey: 1.0,
                kCIInputSaturationKey: 0.0
            ]
        )?.outputImage else { return image }

        guard !faceObservations.isEmpty else { return brightened.cropped(to: image.extent) }
        let mask = faceMask(for: image, softEdge: 30)
        guard let blended = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: brightened,
                kCIInputBackgroundImageKey: image,
                kCIInputMaskImageKey: mask
            ]
        )?.outputImage else { return image }
        return blended.cropped(to: image.extent)
    }

    // MARK: - Shadow Lift: 다크서클·입 주변 저명도 영역 대비 감소

    func applyShadowLift(_ image: CIImage, intensity: Float) -> CIImage {
        let lift = Double(intensity) * 0.06
        guard let lifted = CIFilter(
            name: "CIToneCurve",
            parameters: [
                kCIInputImageKey: image,
                "inputPoint0": CIVector(x: 0.0,  y: lift),
                "inputPoint1": CIVector(x: 0.2,  y: 0.2 + lift * 0.8),
                "inputPoint2": CIVector(x: 0.5,  y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.75),
                "inputPoint4": CIVector(x: 1.0,  y: 1.0)
            ]
        )?.outputImage else { return image }
        return lifted.cropped(to: image.extent)
    }

    // MARK: - Skin Focus: 배경 어둡게, 얼굴 정상

    func applySkinFocus(_ image: CIImage, intensity: Float) -> CIImage {
        let darken = -(Double(intensity) * 0.15)
        guard let darkBg = CIFilter(
            name: "CIColorControls",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBrightnessKey: darken,
                kCIInputContrastKey: 1.0,
                kCIInputSaturationKey: 0.0
            ]
        )?.outputImage else { return image }

        guard !faceObservations.isEmpty else { return darkBg.cropped(to: image.extent) }
        let mask = faceMask(for: image, softEdge: 40)
        guard let blended = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBackgroundImageKey: darkBg,
                kCIInputMaskImageKey: mask
            ]
        )?.outputImage else { return image }
        return blended.cropped(to: image.extent)
    }

    // MARK: - Soft Depth: 배경만 소프트 블러

    func applySoftDepth(_ image: CIImage, intensity: Float) -> CIImage {
        let blurRadius = Double(intensity) * 6.0
        guard let blurred = CIFilter(
            name: "CIGaussianBlur",
            parameters: [kCIInputImageKey: image, kCIInputRadiusKey: blurRadius]
        )?.outputImage else { return image }

        guard !faceObservations.isEmpty else { return blurred.cropped(to: image.extent) }
        let faceMaskImg = faceMask(for: image, softEdge: 50)
        guard let invertedMask = CIFilter(
            name: "CIColorInvert",
            parameters: [kCIInputImageKey: faceMaskImg]
        )?.outputImage else { return image }

        guard let blended = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: blurred,
                kCIInputBackgroundImageKey: image,
                kCIInputMaskImageKey: invertedMask
            ]
        )?.outputImage else { return image }
        return blended.cropped(to: image.extent)
    }

    // MARK: - 얼굴 영역 마스크 생성

    private func faceMask(for image: CIImage, softEdge: CGFloat) -> CIImage {
        let extent = image.extent
        var maskImage = CIImage(color: .black).cropped(to: extent)

        for face in faceObservations {
            let faceBounds = CGRect(
                x: face.boundingBox.origin.x * extent.width,
                y: face.boundingBox.origin.y * extent.height,
                width: face.boundingBox.size.width * extent.width,
                height: face.boundingBox.size.height * extent.height
            ).insetBy(dx: -softEdge, dy: -softEdge)

            guard let oval = CIFilter(
                name: "CIRadialGradient",
                parameters: [
                    "inputCenter": CIVector(x: faceBounds.midX, y: faceBounds.midY),
                    "inputRadius0": min(faceBounds.width, faceBounds.height) * 0.4,
                    "inputRadius1": max(faceBounds.width, faceBounds.height) * 0.55,
                    "inputColor0": CIColor.white,
                    "inputColor1": CIColor.black
                ]
            )?.outputImage?.cropped(to: extent) else { continue }

            maskImage = CIFilter(
                name: "CIAdditionCompositing",
                parameters: [
                    kCIInputImageKey: oval,
                    kCIInputBackgroundImageKey: maskImage
                ]
            )?.outputImage?.cropped(to: extent) ?? maskImage
        }

        return maskImage
    }
}
