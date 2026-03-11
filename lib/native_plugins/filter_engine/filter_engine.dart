import 'package:flutter/services.dart';

/// B&W 필터 렌더링 엔진 MethodChannel 브릿지
/// iOS: Core Image + Metal / Android: OpenGL Shader
class FilterEngine {
  static const MethodChannel _channel =
      MethodChannel('com.likethis/filter_engine');

  /// LUT 파일 로드 (.cube 포맷)
  static Future<void> loadLUT(String lutAssetPath) async {
    await _channel.invokeMethod<void>(
      'loadLUT',
      {'assetPath': lutAssetPath},
    );
  }

  /// 필터 적용 파라미터 업데이트
  /// [lutIntensity] 0.0~1.0, [grain/vignette/lightLeak/dust/bloom] 0~100, [contrast/exposure] -100~100
  static Future<void> updateParams({
    required double lutIntensity,
    required double grain,
    required double contrast,
    required double exposure,
    required double lightLeak,
    required double vignette,
    double dust = 0.0,
    double bloom = 0.0,
  }) async {
    await _channel.invokeMethod<void>('updateParams', {
      'lutIntensity': lutIntensity,
      'grain':        grain / 100.0,
      'contrast':     contrast / 100.0,
      'exposure':     exposure / 100.0,
      'lightLeak':    lightLeak / 100.0,
      'vignette':     vignette / 100.0,
      'dust':         dust / 100.0,
      'bloom':        bloom / 100.0,
    });
  }

  /// 현재 프레임을 캡처하여 파일로 저장
  static Future<String?> captureProcessedFrame() async {
    return _channel.invokeMethod<String>('captureProcessedFrame');
  }
}
