import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/models/camera_state.dart';
import '../../../core/models/filter_model.dart';
import '../../../native_plugins/camera_engine/camera_engine.dart';
import '../../../native_plugins/filter_engine/filter_engine.dart';

/// 카메라 상태 Provider
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>(
  (ref) => CameraNotifier(),
);

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  // ── 초기화 ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    state = state.copyWith(status: CameraStatus.initializing);
    try {
      final textureId = await CameraEngine.initialize(
        frontCamera: state.lens == CameraLens.front,
      );
      // 활성 필터의 기본 파라미터로 상태 동기화 (초기 grain/vignette 불일치 방지)
      final f = state.activeFilter;
      state = state.copyWith(
        grain:     f.defaultGrain,
        vignette:  f.defaultVignette,
        lightLeak: f.defaultLightLeak,
        dust:      f.defaultDust,
        bloom:     f.defaultBloom,
      );
      await FilterEngine.setNoneMode(false);
      await _loadActiveFilter();
      await _syncFilterParams();
      state = state.copyWith(
        status: CameraStatus.ready,
        textureId: textureId,
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await CameraEngine.dispose();
    state = const CameraState();
    super.dispose();
  }

  Future<void> pauseSession() async => CameraEngine.pauseSession();
  Future<void> resumeSession() async => CameraEngine.resumeSession();

  // ── 제스처 인터랙션 ─────────────────────────────────────────────────────────

  /// 수직 스와이프 → Exposure 조절
  /// [delta] 위 = 음수(밝게), 아래 = 양수(어둡게)
  void adjustExposure(double deltaY) {
    const sensitivity = 0.15;
    final newExposure = (state.exposure - deltaY * sensitivity).clamp(-100.0, 100.0);
    state = state.copyWith(exposure: newExposure);
    CameraEngine.setExposure(newExposure / 50.0); // -2.0 ~ +2.0 EV
    unawaited(_syncFilterParams());
  }

  /// 수평 스와이프 → Contrast 조절
  /// [delta] 좌 = 음수(부드럽게), 우 = 양수(강렬하게)
  void adjustContrast(double deltaX) {
    const sensitivity = 0.15;
    final newContrast = (state.contrast + deltaX * sensitivity).clamp(-100.0, 100.0);
    state = state.copyWith(contrast: newContrast);
    unawaited(_syncFilterParams());
  }

  /// 더블탭 → 7종 필터 프리셋 순차 변경
  Future<void> cycleFilter() async {
    final nextFilter = BWFilters.next(state.activeFilter.id);
    await setFilter(nextFilter);
  }

  // ── 필터 제어 ────────────────────────────────────────────────────────────────

  Future<void> setFilter(FilterModel filter) async {
    state = state.copyWith(
      activeFilter:    filter,
      filterIntensity: filter.defaultIntensity,
      isNoneFilter:    false,
      grain:           filter.defaultGrain,
      vignette:        filter.defaultVignette,
      lightLeak:       filter.defaultLightLeak,
      dust:            filter.defaultDust,
      bloom:           filter.defaultBloom,
    );
    await FilterEngine.setNoneMode(false);
    await _loadActiveFilter();
    await _syncFilterParams();
  }

  /// "없음" 선택 — B&W 변환 포함 전체 파이프라인 바이패스 (원본 컬러)
  void selectNone() {
    state = state.copyWith(isNoneFilter: true);
    unawaited(FilterEngine.setNoneMode(true));
  }

  void setGrain(double value) {
    state = state.copyWith(grain: value.clamp(0.0, 100.0));
    _syncFilterParams();
  }

  void setLightLeak(double value) {
    state = state.copyWith(lightLeak: value.clamp(0.0, 100.0));
    _syncFilterParams();
  }

  void setVignette(double value) {
    state = state.copyWith(vignette: value.clamp(0.0, 100.0));
    _syncFilterParams();
  }

  void setDust(double value) {
    state = state.copyWith(dust: value.clamp(0.0, 100.0));
    _syncFilterParams();
  }

  void setBloom(double value) {
    state = state.copyWith(bloom: value.clamp(0.0, 100.0));
    _syncFilterParams();
  }

  void setExposure(double value) {
    final clamped = value.clamp(-100.0, 100.0);
    state = state.copyWith(exposure: clamped);
    CameraEngine.setExposure(clamped / 50.0);
    unawaited(_syncFilterParams());
  }

  void setContrast(double value) {
    state = state.copyWith(contrast: value.clamp(-100.0, 100.0));
    unawaited(_syncFilterParams());
  }

  void setFilterIntensity(double value) {
    state = state.copyWith(filterIntensity: value.clamp(0.0, 1.0));
    _syncFilterParams();
  }

  // ── 카메라 제어 ─────────────────────────────────────────────────────────────

  Future<void> flipCamera() async {
    await CameraEngine.flipCamera();
    final newLens = state.lens == CameraLens.back ? CameraLens.front : CameraLens.back;
    state = state.copyWith(lens: newLens);
  }

  Future<void> setFlashMode(FlashMode mode) async {
    state = state.copyWith(flashMode: mode);
    await CameraEngine.setFlash(mode.name); // 'off' | 'on' | 'auto'
  }

  Future<void> setZoom(double zoom) async {
    final clamped = zoom.clamp(1.0, 8.0);
    state = state.copyWith(zoom: clamped);
    await CameraEngine.setZoom(clamped);
  }

  Future<void> setCompareMode(bool enable) async {
    await CameraEngine.setCompareMode(enable);
  }

  Future<void> setBeauty(String mode, double intensity) async {
    state = state.copyWith(beautyMode: mode, beautyIntensity: intensity);
    await CameraEngine.setBeauty(mode, intensity);
  }

  Future<String?> capturePhoto({bool shutterSound = false}) async {
    if (!state.isReady) return null;
    state = state.copyWith(status: CameraStatus.capturing);
    try {
      final path = await CameraEngine.capturePhoto(shutterSound: shutterSound);
      state = state.copyWith(status: CameraStatus.ready);
      if (path != null) {
        // 썸네일 즉시 업데이트 (save 예외와 무관)
        state = state.copyWith(lastCapturedPath: path);
        try {
          await PhotoManager.editor.saveImageWithPath(
            path,
            title: 'LikeThis_${DateTime.now().millisecondsSinceEpoch}',
          );
        } catch (_) {}
      }
      return path;
    } catch (e) {
      state = state.copyWith(status: CameraStatus.ready);
      return null;
    }
  }

  Future<void> toggleRecording({bool shutterSound = false}) async {
    if (state.isRecording) {
      state = state.copyWith(status: CameraStatus.capturing);
      try {
        final path = await CameraEngine.stopRecording();
        state = state.copyWith(status: CameraStatus.ready);
        if (path != null) {
          final entity = await PhotoManager.editor.saveVideo(
            File(path),
            title: 'LikeThis_video_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (entity != null) {
            final Uint8List? thumbData = await entity.thumbnailDataWithSize(
              const ThumbnailSize.square(200),
            );
            if (thumbData != null) {
              final thumbFile = File(
                '${(await Directory.systemTemp.createTemp('lt_thumb')).path}/thumb.jpg',
              );
              await thumbFile.writeAsBytes(thumbData);
              state = state.copyWith(lastCapturedPath: thumbFile.path);
            }
          }
        }
      } catch (_) {
        state = state.copyWith(status: CameraStatus.ready);
      }
    } else {
      if (!state.isReady) return;
      await CameraEngine.startRecording(shutterSound: shutterSound);
      state = state.copyWith(status: CameraStatus.recording);
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<void> _loadActiveFilter() async {
    final lutPath = 'assets/luts/${state.activeFilter.lutFileName}';
    await FilterEngine.loadLUT(lutPath);
  }

  Future<void> _syncFilterParams() async {
    await FilterEngine.updateParams(
      lutIntensity: state.filterIntensity,
      grain:        state.grain,
      contrast:     state.contrast,
      exposure:     state.exposure,
      lightLeak:    state.lightLeak,
      vignette:     state.vignette,
      dust:         state.dust,
      bloom:        state.bloom,
    );
  }
}
