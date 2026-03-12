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
    this.isNoneFilter = false,
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.grain = 0.0,
    this.lightLeak = 0.0,
    this.vignette = 0.0,
    this.dust = 0.0,
    this.bloom = 0.0,
    this.flashMode = FlashMode.off,
    this.zoom = 1.0,
    this.beautyMode = 'none',
    this.beautyIntensity = 0.0,
    this.errorMessage,
    this.lastCapturedPath,
  });

  final CameraStatus status;
  final CameraLens lens;
  final int? textureId;
  final FilterModel activeFilter;

  /// 필터 강도 슬라이더 (0.0 ~ 1.0)
  final double filterIntensity;

  /// "없음" 버튼 선택 상태 — true이면 LUT 완전 비활성 (강도 슬라이더와 독립)
  final bool isNoneFilter;

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

  /// 뷰티 모드 ('none'|'soft'|'glow'|'silky'|'faceBright'|'shadowLift'|'skinFocus'|'softDepth')
  final String beautyMode;

  /// 뷰티 강도 (0.0 ~ 1.0)
  final double beautyIntensity;

  final String? errorMessage;

  /// 마지막 촬영 이미지 경로 (갤러리 썸네일용)
  final String? lastCapturedPath;

  bool get isReady => status == CameraStatus.ready;
  bool get isRecording => status == CameraStatus.recording;
  bool get isFront => lens == CameraLens.front;

  CameraState copyWith({
    CameraStatus? status,
    CameraLens? lens,
    int? textureId,
    FilterModel? activeFilter,
    double? filterIntensity,
    bool? isNoneFilter,
    double? exposure,
    double? contrast,
    double? grain,
    double? lightLeak,
    double? vignette,
    double? dust,
    double? bloom,
    FlashMode? flashMode,
    double? zoom,
    String? beautyMode,
    double? beautyIntensity,
    String? errorMessage,
    String? lastCapturedPath,
  }) => CameraState(
    status: status ?? this.status,
    lens: lens ?? this.lens,
    textureId: textureId ?? this.textureId,
    activeFilter: activeFilter ?? this.activeFilter,
    filterIntensity: filterIntensity ?? this.filterIntensity,
    isNoneFilter: isNoneFilter ?? this.isNoneFilter,
    exposure: exposure ?? this.exposure,
    contrast: contrast ?? this.contrast,
    grain: grain ?? this.grain,
    lightLeak: lightLeak ?? this.lightLeak,
    vignette: vignette ?? this.vignette,
    dust: dust ?? this.dust,
    bloom: bloom ?? this.bloom,
    flashMode: flashMode ?? this.flashMode,
    zoom: zoom ?? this.zoom,
    beautyMode: beautyMode ?? this.beautyMode,
    beautyIntensity: beautyIntensity ?? this.beautyIntensity,
    errorMessage: errorMessage ?? this.errorMessage,
    lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
  );
}
