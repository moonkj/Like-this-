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
  static Future<String?> capturePhoto() async {
    return _channel.invokeMethod<String>('capturePhoto');
  }

  /// 노출 조절 (-2.0 ~ +2.0 EV)
  static Future<void> setExposure(double ev) async {
    await _channel.invokeMethod<void>('setExposure', {'ev': ev});
  }

  /// 줌 설정 (1.0 ~ maxZoom)
  static Future<void> setZoom(double zoom) async {
    await _channel.invokeMethod<void>('setZoom', {'zoom': zoom});
  }
}
