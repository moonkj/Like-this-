import 'filter_model.dart';

/// 카메라 활성 상태
enum CameraStatus {
  uninitialized,
  initializing,
  ready,
  capturing,
  recording,
  error,
}

/// 카메라 렌즈 방향
enum CameraLens { front, back }

/// 플래시 모드
enum FlashMode { off, on, auto }

/// 카메라 전체 상태 모델
class CameraState {
  const CameraState({
    this.status = CameraStatus.uninitialized,
    this.lens = CameraLens.back,
    this.textureId,
    this.activeFilter = BWFilters.pureThis,
    this.filterIntensity = 1.0,
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.grain = 20.0,
    this.lightLeak = 0.0,
    this.vignette = 15.0,
    this.dust = 0.0,
    this.bloom = 0.0,
    this.flashMode = FlashMode.off,
    this.zoom = 1.0,
    this.errorMessage,
  });

  final CameraStatus status;
  final CameraLens lens;
  final int? textureId;
  final FilterModel activeFilter;

  /// 필터 강도 슬라이더 (0.0 ~ 1.0)
  final double filterIntensity;

  /// 수직 스와이프로 조절 (-100 ~ +100)
  final double exposure;

  /// 수평 스와이프로 조절 (-100 ~ +100)
  final double contrast;

  /// 그레인 강도 (0 ~ 100)
  final double grain;

  /// 빛 번짐 강도 (0 ~ 100)
  final double lightLeak;

  /// 비네팅 강도 (0 ~ 100)
  final double vignette;

  /// 먼지 텍스처 강도 (0 ~ 100) — Film Dust 전용
  final double dust;

  /// 하이라이트 번짐 강도 (0 ~ 100) — Silver Glow 전용
  final double bloom;

  /// 플래시 모드
  final FlashMode flashMode;

  /// 현재 줌 배율 (1.0 ~ 8.0)
  final double zoom;

  final String? errorMessage;

  bool get isReady => status == CameraStatus.ready;
  bool get isRecording => status == CameraStatus.recording;
  bool get isFront => lens == CameraLens.front;

  CameraState copyWith({
    CameraStatus? status,
    CameraLens? lens,
    int? textureId,
    FilterModel? activeFilter,
    double? filterIntensity,
    double? exposure,
    double? contrast,
    double? grain,
    double? lightLeak,
    double? vignette,
    double? dust,
    double? bloom,
    FlashMode? flashMode,
    double? zoom,
    String? errorMessage,
  }) => CameraState(
    status: status ?? this.status,
    lens: lens ?? this.lens,
    textureId: textureId ?? this.textureId,
    activeFilter: activeFilter ?? this.activeFilter,
    filterIntensity: filterIntensity ?? this.filterIntensity,
    exposure: exposure ?? this.exposure,
    contrast: contrast ?? this.contrast,
    grain: grain ?? this.grain,
    lightLeak: lightLeak ?? this.lightLeak,
    vignette: vignette ?? this.vignette,
    dust: dust ?? this.dust,
    bloom: bloom ?? this.bloom,
    flashMode: flashMode ?? this.flashMode,
    zoom: zoom ?? this.zoom,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
