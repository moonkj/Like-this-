import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/camera_state.dart';
import '../../../core/models/filter_model.dart';
import '../providers/camera_provider.dart';
import '../../../native_plugins/camera_engine/camera_engine.dart';
import 'widgets/shutter_button.dart';
import 'widgets/filter_scroll_bar.dart';
import 'widgets/exposure_indicator.dart';
import 'widgets/filter_name_overlay.dart';
import 'widgets/beauty_panel.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {

  // ── 인디케이터 표시 플래그 ───────────────────────────────────────────────
  bool _showExposureIndicator = false;
  bool _showContrastIndicator = false;
  bool _showFilterName = false;
  bool _showZoomIndicator = false;

  // ── 패널 토글 ────────────────────────────────────────────────────────────
  bool _showBeautyPanel = false;
  bool _showFilterBar = true; // 기본값: 필터 바 열림
  bool _showIntensityPanel = false;

  // ── 모드 ─────────────────────────────────────────────────────────────────
  bool _isVideoMode = false;
  bool _isComparing = false;
  double _comparePosition = 0.5; // 분할선 위치 (0.0 = 좌, 1.0 = 우)

  // ── 타이머 ───────────────────────────────────────────────────────────────
  int _timerSeconds = 0;      // 0 = 꺼짐
  int _countdownValue = 0;
  bool _isCountingDown = false;

  // ── 줌 ───────────────────────────────────────────────────────────────────
  double _baseZoom = 1.0;
  double _currentZoom = 1.0;
  static const double _maxZoom = 8.0;
  Offset? _lastFocalPoint;

  // ── 탭 카운터 (더블탭 필터 사이클) ──────────────────────────────────────
  int _tapCount = 0;
  Timer? _tapTimer;
  Timer? _indicatorTimer;
  Timer? _filterNameTimer;
  Timer? _zoomTimer;
  Timer? _sideButtonTimer;
  bool _showSideButtons = true;
  Timer? _intensityPanelTimer;

  // 카메라 화면이 현재 최상단 route인지 추적
  // (false 이면 갤러리/에디터 등 위에 화면이 있음)
  bool _isCurrentRoute = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initialize();
    });
    _resetSideButtonTimer();
  }

  void _resetSideButtonTimer() {
    _sideButtonTimer?.cancel();
    if (!_showSideButtons) setState(() => _showSideButtons = true);
    _sideButtonTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showSideButtons = false);
    });
  }

  void _resetIntensityPanelTimer() {
    _intensityPanelTimer?.cancel();
    _sideButtonTimer?.cancel(); // 슬라이더 사용 중엔 사이드바도 유지
    _intensityPanelTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() {
        _showIntensityPanel = false;
        _showSideButtons = false; // intensity panel 타임아웃 시 사이드바도 같이 숨김
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute.isCurrent 는 _ModalScopeStatus InheritedWidget 에 의존하므로
    // 다른 화면이 push/pop 될 때마다 이 메서드가 반드시 호출됨 → 100% 신뢰
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent == _isCurrentRoute) return;
    _isCurrentRoute = isCurrent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isCurrentRoute) {
        ref.read(cameraProvider.notifier).resumeSession();
      } else {
        ref.read(cameraProvider.notifier).pauseSession();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapTimer?.cancel();
    _indicatorTimer?.cancel();
    _filterNameTimer?.cancel();
    _zoomTimer?.cancel();
    _sideButtonTimer?.cancel();
    _intensityPanelTimer?.cancel();
    ref.read(cameraProvider.notifier).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 카메라 화면이 현재 최상단일 때만 lifecycle 이벤트 처리
    // (_isCurrentRoute = false 이면 갤러리/에디터가 위에 있는 상태)
    if (!_isCurrentRoute) return;
    final notifier = ref.read(cameraProvider.notifier);
    if (state == AppLifecycleState.paused) notifier.pauseSession();
    if (state == AppLifecycleState.resumed) notifier.resumeSession();
  }

  // ── 제스처 ───────────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _baseZoom = _currentZoom;
    _lastFocalPoint = d.focalPoint;
    _resetSideButtonTimer();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2) {
      // 핀치 줌
      final newZoom = (_baseZoom * d.scale).clamp(1.0, _maxZoom);
      if ((newZoom - _currentZoom).abs() > 0.01) {
        setState(() {
          _currentZoom = newZoom;
          _showZoomIndicator = true;
        });
        ref.read(cameraProvider.notifier).setZoom(newZoom);
        _zoomTimer?.cancel();
        _zoomTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showZoomIndicator = false);
        });
      }
    } else if (_lastFocalPoint != null) {
      // 단일 손가락 드래그 (dead zone 6px 미만 무시)
      final delta = d.focalPoint - _lastFocalPoint!;
      if (delta.distance < 6) return;
      if (_isComparing && delta.dx.abs() > delta.dy.abs()) {
        // 비교 모드: 수평 스와이프 → 분할선 이동
        final screenW = context.size?.width ?? 300;
        final newPos = (_comparePosition + delta.dx / screenW).clamp(0.05, 0.95);
        setState(() { _comparePosition = newPos; });
        CameraEngine.setSplitPosition(newPos);
      } else if (delta.dy.abs() > delta.dx.abs()) {
        ref.read(cameraProvider.notifier).adjustExposure(delta.dy);
        setState(() { _showExposureIndicator = true; _showContrastIndicator = false; });
        _resetIndicatorTimer();
      } else if (!_isComparing) {
        ref.read(cameraProvider.notifier).adjustContrast(delta.dx);
        setState(() { _showContrastIndicator = true; _showExposureIndicator = false; });
        _resetIndicatorTimer();
      }
      _lastFocalPoint = d.focalPoint;
    }
  }

  void _onScaleEnd(ScaleEndDetails d) => _lastFocalPoint = null;

  void _resetIndicatorTimer() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() {
        _showExposureIndicator = false;
        _showContrastIndicator = false;
      });
    });
  }

  void _onTap() {
    _resetSideButtonTimer();
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 250), () {
      if (_tapCount >= 2) _cycleFilter();
      _tapCount = 0;
    });
  }

  Future<void> _cycleFilter() async {
    HapticFeedback.selectionClick();
    await ref.read(cameraProvider.notifier).cycleFilter();
    setState(() => _showFilterName = true);
    _filterNameTimer?.cancel();
    _filterNameTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showFilterName = false);
    });
  }

  // ── 플래시 ───────────────────────────────────────────────────────────────

  void _cycleFlash(FlashMode current) {
    HapticFeedback.selectionClick();
    final next = switch (current) {
      FlashMode.off  => FlashMode.on,
      FlashMode.on   => FlashMode.auto,
      FlashMode.auto => FlashMode.off,
    };
    ref.read(cameraProvider.notifier).setFlashMode(next);
  }

  IconData _flashIcon(FlashMode mode) => switch (mode) {
    FlashMode.off  => Icons.flash_off,
    FlashMode.on   => Icons.flash_on,
    FlashMode.auto => Icons.flash_auto,
  };

  // ── 타이머 ───────────────────────────────────────────────────────────────

  void _cycleTimer() {
    HapticFeedback.selectionClick();
    setState(() {
      _timerSeconds = switch (_timerSeconds) {
        0 => 3,
        3 => 5,
        5 => 10,
        _ => 0,
      };
    });
  }

  Future<void> _captureWithTimer() async {
    if (_isCountingDown) return;
    if (_timerSeconds == 0) {
      ref.read(cameraProvider.notifier).capturePhoto();
      return;
    }
    setState(() { _isCountingDown = true; _countdownValue = _timerSeconds; });
    for (int i = _timerSeconds; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() { _countdownValue = 0; _isCountingDown = false; });
    HapticFeedback.heavyImpact();
    ref.read(cameraProvider.notifier).capturePhoto();
  }

  // ── 비교 모드 ────────────────────────────────────────────────────────────

  void _startCompare() {
    setState(() => _isComparing = true);
    ref.read(cameraProvider.notifier).setCompareMode(true);
  }

  void _stopCompare() {
    setState(() { _isComparing = false; _comparePosition = 0.5; });
    ref.read(cameraProvider.notifier).setCompareMode(false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);
    final padding = MediaQuery.of(context).padding;
    final topPad = padding.top;
    final botPad = padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topPad),

            // ── 카메라 프리뷰 3:4 ───────────────────────────────────
            AspectRatio(
              aspectRatio: 3.0 / 4.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(camState),

                  // 제스처 영역 (강도 바 위)
                  // bottom: 100 = slider(bottom:20, h:56) + overlay_radius(20) + buffer(4)
                  if (camState.isReady)
                    Positioned(
                      top: 0, left: 0, right: 60, // 우측 60px 제외 (사이드 버튼 44+12+buffer)
                      bottom: _showIntensityPanel ? 100 : 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _onTap,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                      ),
                    ),

                  // 상단 바 (사이드 버튼과 함께 숨김)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: IgnorePointer(
                      ignoring: !_showSideButtons,
                      child: AnimatedOpacity(
                        opacity: _showSideButtons ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: _buildTopBar(camState),
                      ),
                    ),
                  ),

                  // 우측 플로팅 버튼 (5초 후 자동 숨김)
                  Positioned(
                    right: 12, bottom: 80,
                    child: IgnorePointer(
                      ignoring: !_showSideButtons,
                      child: AnimatedOpacity(
                        opacity: _showSideButtons ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: _buildSideButtons(camState),
                      ),
                    ),
                  ),

                  // 필터 강도 바
                  if (_showIntensityPanel)
                    Positioned(
                      bottom: 8, left: 16, right: 16,
                      child: _buildIntensityBar(camState),
                    ),

                  // Exposure 인디케이터 (왼쪽 하단, 강도 바 위)
                  Positioned(
                    left: 16,
                    bottom: _showIntensityPanel ? 58 : 24,
                    child: ExposureIndicator(
                      exposure: camState.exposure,
                      visible: _showExposureIndicator,
                    ),
                  ),

                  // Contrast 인디케이터 (강도 바 위)
                  Positioned(
                    bottom: _showIntensityPanel ? 58 : 16,
                    left: 0, right: 0,
                    child: Center(
                      child: ContrastIndicator(
                        contrast: camState.contrast,
                        visible: _showContrastIndicator,
                      ),
                    ),
                  ),

                  // 줌 뱃지
                  if (_showZoomIndicator)
                    Positioned(
                      top: 60, left: 0, right: 0,
                      child: Center(child: _ZoomBadge(zoom: _currentZoom)),
                    ),

                  // 필터명 오버레이
                  Center(
                    child: FilterNameOverlay(
                      filterName: camState.activeFilter.name,
                      visible: _showFilterName,
                    ),
                  ),

                  // 비교 모드 분할 오버레이
                  if (_isComparing)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _CompareSplitOverlay(
                          position: _comparePosition,
                          filterName: camState.activeFilter.name,
                        ),
                      ),
                    ),

                  // 타이머 카운트다운
                  if (_countdownValue > 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Center(
                          child: Text(
                            '$_countdownValue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 100,
                              fontWeight: FontWeight.w200,
                              letterSpacing: -4,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 녹화 중 REC 뱃지
                  if (camState.isRecording)
                    Positioned(
                      top: 12, right: 16,
                      child: _RecordingBadge(),
                    ),
                ],
              ),
            ),

            // ── 하단 패널 ────────────────────────────────────────────
            Expanded(child: _buildBottomPanel(camState, botPad)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraState camState) {
    if (camState.status == CameraStatus.error) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  camState.errorMessage ?? '카메라를 초기화할 수 없습니다.',
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (camState.textureId == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.silver),
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    // hd1920x1080 프리셋 → 세로 회전 후 1080×1920 (9:16)
    // FittedBox.cover 가 9:16 → 3:4 중앙 크롭 처리
    Widget preview = ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 9, height: 16,
          child: Texture(textureId: camState.textureId!),
        ),
      ),
    );

    // 전면 카메라 미러: 네이티브(Swift isVideoMirrored)에서만 처리
    return preview;
  }

  Widget _buildTopBar(CameraState camState) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 10),
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          // 플래시 버튼 — off/on/auto 순환
          GestureDetector(
            onTap: () => _cycleFlash(camState.flashMode),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: camState.flashMode != FlashMode.off
                    ? AppColors.silver.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
              child: Icon(
                _flashIcon(camState.flashMode),
                color: camState.flashMode == FlashMode.on
                    ? const Color(0xFFFFE066)
                    : Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSideButtons(CameraState camState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 타이머
        GestureDetector(
          onTap: () { _resetSideButtonTimer(); _cycleTimer(); },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerSeconds > 0
                  ? Colors.black.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color: _timerSeconds > 0 ? Colors.white : Colors.white24,
                width: _timerSeconds > 0 ? 1.5 : 0.5,
              ),
            ),
            child: _timerSeconds > 0
                ? Center(
                    child: Text(
                      '${_timerSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(height: 12),

        // 필터 강도
        _SideCircleButton(
          icon: Icons.tune,
          active: _showIntensityPanel,
          onTap: () {
            _resetSideButtonTimer();
            HapticFeedback.selectionClick();
            setState(() => _showIntensityPanel = !_showIntensityPanel);
            if (_showIntensityPanel) _resetIntensityPanelTimer();
            else { _intensityPanelTimer?.cancel(); _resetSideButtonTimer(); }
          },
        ),
        const SizedBox(height: 12),

        // 비교 — 탭으로 토글 (비교선 on/off)
        GestureDetector(
          onTap: () {
            _resetSideButtonTimer();
            HapticFeedback.selectionClick();
            if (_isComparing) _stopCompare(); else _startCompare();
          },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isComparing
                  ? AppColors.silver.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color: _isComparing ? AppColors.silver : Colors.white24,
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.compare,
              color: _isComparing ? AppColors.silver : Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 설정
        _SideCircleButton(
          icon: Icons.settings_outlined,
          onTap: () { _resetSideButtonTimer(); context.push('/settings'); },
        ),
      ],
    );
  }

  Widget _buildIntensityBar(CameraState camState) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.wb_sunny_outlined, color: AppColors.textSecondary, size: 14),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppColors.silver,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.white,
                overlayColor: AppColors.silver.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: camState.isNoneFilter ? 0.0 : camState.filterIntensity,
                // isNoneFilter일 때 슬라이더 비활성 — setFilter()로만 해제
                onChanged: camState.isNoneFilter ? null : (v) {
                  ref.read(cameraProvider.notifier).setFilterIntensity(v);
                  _resetIntensityPanelTimer();
                },
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(camState.filterIntensity * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(CameraState camState, double botPad) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 8),

          SizedBox(
            height: 116,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showBeautyPanel
                  ? const BeautyPanel(key: ValueKey('beauty'))
                  : _showFilterBar
                      ? FilterScrollBar(
                          key: const ValueKey('filter'),
                          filters: BWFilters.all,
                          selectedId: camState.activeFilter.id,
                          isNoneSelected: camState.isNoneFilter,
                          onNoneSelected: () => ref.read(cameraProvider.notifier).selectNone(),
                          onFilterSelected: (f) {
                            ref.read(cameraProvider.notifier).setFilter(f);
                          },
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),

          const SizedBox(height: 4),

          // 사진/동영상 탭
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeTab(
                label: '사진',
                selected: !_isVideoMode,
                onTap: () => setState(() => _isVideoMode = false),
              ),
              const SizedBox(width: 28),
              _ModeTab(
                label: '동영상',
                selected: _isVideoMode,
                onTap: () => setState(() => _isVideoMode = true),
              ),
            ],
          ),

          const Spacer(),

          // 5버튼 행
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, botPad > 0 ? botPad : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/gallery'),
                        child: _GalleryThumb(path: camState.lastCapturedPath),
                      ),
                      const SizedBox(width: 12),
                      _BottomIconButton(
                        icon: Icons.auto_awesome_outlined,
                        active: _showFilterBar,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() { _showFilterBar = true; _showBeautyPanel = false; });
                        },
                      ),
                    ],
                  ),
                ),

                // 셔터 / 동영상 셔터 (84px 고정으로 레이아웃 흔들림 방지)
                SizedBox(
                  width: 84, height: 84,
                  child: Center(
                    child: _isVideoMode
                        ? _VideoShutterButton(
                            isRecording: camState.isRecording,
                            onTap: () =>
                                ref.read(cameraProvider.notifier).toggleRecording(),
                          )
                        : ShutterButton(
                            isCapturing:
                                camState.status == CameraStatus.capturing ||
                                    _isCountingDown,
                            onTap: _captureWithTimer,
                          ),
                  ),
                ),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _BottomIconButton(
                        icon: Icons.auto_fix_high,
                        active: _showBeautyPanel,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() { _showBeautyPanel = true; _showFilterBar = false; });
                        },
                      ),
                      const SizedBox(width: 12),
                      _BottomIconButton(
                        icon: Icons.flip_camera_ios_outlined,
                        onTap: () =>
                            ref.read(cameraProvider.notifier).flipCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 줌 뱃지 ──────────────────────────────────────────────────────────────────

class _ZoomBadge extends StatelessWidget {
  const _ZoomBadge({required this.zoom});
  final double zoom;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24, width: 0.5),
    ),
    child: Text(
      '${zoom.toStringAsFixed(1)}×',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// ── 녹화 REC 뱃지 ─────────────────────────────────────────────────────────────

class _RecordingBadge extends StatefulWidget {
  @override
  State<_RecordingBadge> createState() => _RecordingBadgeState();
}

class _RecordingBadgeState extends State<_RecordingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _blink,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 5),
          Text(
            'REC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── 동영상 셔터 버튼 ─────────────────────────────────────────────────────────

class _VideoShutterButton extends StatelessWidget {
  const _VideoShutterButton({
    required this.isRecording,
    required this.onTap,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.heavyImpact();
      onTap();
    },
    child: SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 28 : 56,
            height: isRecording ? 28 : 56,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(isRecording ? 6 : 28),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────────────

class _SideCircleButton extends StatelessWidget {
  const _SideCircleButton({
    required this.icon,
    this.onTap,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.silver.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: active ? AppColors.silver : Colors.white24,
          width: 0.5,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 52, height: 52,
      child: Center(
        child: Icon(
          icon,
          color: active ? AppColors.silver : AppColors.textPrimary,
          size: 26,
        ),
      ),
    ),
  );
}

// ── 갤러리 썸네일 버튼 ────────────────────────────────────────────────────────

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52, height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: path != null
            ? Image.file(
                File(path!),
                width: 52, height: 52,
                fit: BoxFit.cover,
                cacheWidth: 104, cacheHeight: 104,
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.textPrimary, size: 26),
              ),
      ),
    );
  }
}

// ── 비교 모드 분할 오버레이 ───────────────────────────────────────────────────

class _CompareSplitOverlay extends StatelessWidget {
  const _CompareSplitOverlay({required this.position, required this.filterName});
  final double position;
  final String filterName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final x = constraints.maxWidth * position;
      return Stack(
        children: [
          // 분할선
          Positioned(
            left: x - 0.75,
            top: 0, bottom: 0,
            child: Container(
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          // 핸들
          Positioned(
            left: x - 16,
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
          // BEFORE 레이블 — 핸들 왼쪽 (right 기준으로 AFTER와 동일 간격)
          Positioned(
            right: constraints.maxWidth - (x - 16) + 8,
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '원본',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // AFTER 레이블 — 핸들 오른쪽
          Positioned(
            left: x + 16 + 8, // 핸들 오른쪽 가장자리 + 간격
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  filterName,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 4 : 0,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.silver,
          ),
        ),
      ],
    ),
  );
}
