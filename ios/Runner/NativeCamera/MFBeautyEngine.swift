import Foundation
import Vision
import CoreImage

/// Like This 뷰티 엔진 — VisionKit 얼굴 인식 + CIFilter 기반 피부 보정
final class MFBeautyEngine {

    enum BeautyMode {
        case soft    // 피부 결 부드럽게
        case glow    // 은은한 광채
        case silky   // 셀카용 매끈
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

    /// CIImage에 뷰티 효과 적용 (얼굴 마스크 기반)
    func apply(
        to image: CIImage,
        mode: BeautyMode,
        intensity: Float
    ) -> CIImage {
        switch mode {
        case .soft:  return applySoftSkin(image, intensity: intensity)
        case .glow:  return applyGlowMono(image, intensity: intensity)
        case .silky: return applySilky(image, intensity: intensity)
        }
    }

    // MARK: - Soft Skin: 저주파 블러로 피부 결만 살짝 부드럽게

    private func applySoftSkin(_ image: CIImage, intensity: Float) -> CIImage {
        let blurRadius = Double(intensity) * 3.0

        // 블러 레이어 (피부 결 smoothing)
        guard let blurred = CIFilter(
            name: "CIGaussianBlur",
            parameters: [kCIInputImageKey: image, kCIInputRadiusKey: blurRadius]
        )?.outputImage else { return image }

        // 원본과 블러를 intensity 비율로 믹스
        guard let mix = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBackgroundImageKey: blurred,
                kCIInputMaskImageKey: faceMask(for: image, softEdge: 20)
            ]
        )?.outputImage else { return image }

        return mix.cropped(to: image.extent)
    }

    // MARK: - Glow Mono: 하이라이트 주변 소프트 글로우

    private func applyGlowMono(_ image: CIImage, intensity: Float) -> CIImage {
        let bloom = Double(intensity) * 0.3

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
        let lift = Double(intensity) * 0.05
        let gamma = 1.0 + Double(intensity) * 0.15

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
