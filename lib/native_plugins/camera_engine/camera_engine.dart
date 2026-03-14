import 'package:flutter/services.dart';

/// 네이티브 카메라 엔진 MethodChannel 브릿지
/// iOS: AVFoundation + Metal / Android: CameraX + OpenGL
class CameraEngine {
  static const MethodChannel _channel =
      MethodChannel('com.likethis/camera_engine');

  /// 카메라 초기화 → textureId 반환
  static Future<int?> initialize({bool frontCamera = false}) async {
    final result = await _channel.invokeMethod<int>(
      'initialize',
      {'frontCamera': frontCamera},
    );
    return result;
  }

  /// 카메라 세션 종료
  static Future<void> dispose() async {
    await _channel.invokeMethod<void>('dispose');
  }

  /// 전/후면 카메라 전환
  static Future<void> flipCamera() async {
    await _channel.invokeMethod<void>('flipCamera');
  }

  /// 세션 일시 정지 (앱 백그라운드)
  static Future<void> pauseSession() async {
    await _channel.invokeMethod<void>('pauseSession');
  }

  /// 세션 재개
  static Future<void> resumeSession() async {
    await _channel.invokeMethod<void>('resumeSession');
  }

  /// 사진 촬영 → 저장된 파일 경로 반환
  static Future<String?> capturePhoto({required bool shutterSound}) async {
    return _channel.invokeMethod<String>('capturePhoto', {'shutterSound': shutterSound});
  }

  /// 노출 조절 (-2.0 ~ +2.0 EV)
  static Future<void> setExposure(double ev) async {
    await _channel.invokeMethod<void>('setExposure', {'ev': ev});
  }

  /// 줌 설정 (1.0 ~ maxZoom)
  static Future<void> setZoom(double zoom) async {
    await _channel.invokeMethod<void>('setZoom', {'zoom': zoom});
  }

  /// 플래시 모드 설정 ('off' | 'on' | 'auto')
  static Future<void> setFlash(String mode) async {
    await _channel.invokeMethod<void>('setFlash', {'mode': mode});
  }

  /// 동영상 녹화 시작 → 임시 파일 경로 반환 (녹화 완료 시)
  static Future<void> startRecording() async {
    await _channel.invokeMethod<void>('startRecording');
  }

  /// 동영상 녹화 중지 → 저장된 파일 경로 반환
  static Future<String?> stopRecording() async {
    return _channel.invokeMethod<String>('stopRecording');
  }

  /// 비교 모드 — true: 원본 프리뷰, false: 필터 적용 프리뷰
  static Future<void> setCompareMode(bool enable) async {
    await _channel.invokeMethod<void>('setCompareMode', {'enable': enable});
  }

  static Future<void> setSplitPosition(double position) async {
    await _channel.invokeMethod<void>('setSplitPosition', {'position': position});
  }

  /// 뷰티 모드 설정 ('none'|'soft'|'glow'|'silky'|'faceBright'|'shadowLift'|'skinFocus'|'softDepth')
  static Future<void> setBeauty(String mode, double intensity) async {
    await _channel.invokeMethod<void>('setBeauty', {
      'mode': mode,
      'intensity': intensity,
    });
  }

  /// 갤러리 이미지를 네이티브(CIImage)로 처리 후 JPEG 저장 — iOS 전용
  /// colorMatrix: Flutter ColorFilter.matrix와 동일한 4×5 행렬 (20개 double)
  /// vignette/grain/lightLeak/bloom: 0.0~1.0
  /// cropX/Y/W/H: 정규화 크롭 좌표 (top-left 기준, 기본값 0,0,1,1 = 전체)
  /// 반환: 저장된 JPEG 임시 파일 경로, 실패 시 null
  static Future<String?> processAndSaveImage({
    required String sourcePath,
    required List<double> colorMatrix,
    required double vignette,
    required double grain,
    required double lightLeak,
    required double bloom,
    required String outputPath,
    double cropX = 0.0,
    double cropY = 0.0,
    double cropW = 1.0,
    double cropH = 1.0,
  }) async {
    return _channel.invokeMethod<String>('processAndSaveImage', {
      'sourcePath': sourcePath,
      'colorMatrix': colorMatrix,
      'vignette': vignette,
      'grain': grain,
      'lightLeak': lightLeak,
      'bloom': bloom,
      'outputPath': outputPath,
      'cropX': cropX,
      'cropY': cropY,
      'cropW': cropW,
      'cropH': cropH,
    });
  }

  /// 동영상 프레임별 CIFilter 적용 후 저장 — iOS 전용
  /// colorMatrix: Flutter ColorFilter.matrix와 동일한 4×5 행렬 (20개 double)
  /// vignette/grain/lightLeak/bloom: 0.0~1.0
  /// 반환: 저장된 mp4 임시 파일 경로, 실패 시 null
  static Future<String?> processAndSaveVideo({
    required String sourcePath,
    required List<double> colorMatrix,
    required double vignette,
    required double grain,
    required double lightLeak,
    required double bloom,
    required String outputPath,
  }) async {
    return _channel.invokeMethod<String>('processAndSaveVideo', {
      'sourcePath': sourcePath,
      'colorMatrix': colorMatrix,
      'vignette': vignette,
      'grain': grain,
      'lightLeak': lightLeak,
      'bloom': bloom,
      'outputPath': outputPath,
    });
  }

  /// 동영상 크롭 — 정규화 좌표 (0~1) 기준
  /// 반환: 크롭된 동영상 파일 경로, 실패 시 null
  static Future<String?> cropVideo({
    required String inputPath,
    required String outputPath,
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    return _channel.invokeMethod<String>('cropVideo', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
  }
}
