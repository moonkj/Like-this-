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

/// 카메라 전체 상태 모델
class CameraState {
  const CameraState({
    this.status = CameraStatus.uninitialized,
    this.lens = CameraLens.back,
    this.textureId,
    this.activeFilter = BWFilters.pureThis,
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.grain = 20.0,
    this.lightLeak = 0.0,
    this.vignette = 15.0,
    this.errorMessage,
  });

  final CameraStatus status;
  final CameraLens lens;
  final int? textureId;
  final FilterModel activeFilter;

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

  final String? errorMessage;

  bool get isReady => status == CameraStatus.ready;
  bool get isRecording => status == CameraStatus.recording;
  bool get isFront => lens == CameraLens.front;

  CameraState copyWith({
    CameraStatus? status,
    CameraLens? lens,
    int? textureId,
    FilterModel? activeFilter,
    double? exposure,
    double? contrast,
    double? grain,
    double? lightLeak,
    double? vignette,
    String? errorMessage,
  }) => CameraState(
    status: status ?? this.status,
    lens: lens ?? this.lens,
    textureId: textureId ?? this.textureId,
    activeFilter: activeFilter ?? this.activeFilter,
    exposure: exposure ?? this.exposure,
    contrast: contrast ?? this.contrast,
    grain: grain ?? this.grain,
    lightLeak: lightLeak ?? this.lightLeak,
    vignette: vignette ?? this.vignette,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
