import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/camera_state.dart';
import '../../../core/models/filter_model.dart';
import '../providers/camera_provider.dart';
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
  bool _showFilterBar = false;
  bool _showIntensityPanel = false;

  // ── 모드 ─────────────────────────────────────────────────────────────────
  bool _isVideoMode = false;
  bool _isComparing = false;

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
  VoidCallback? _routeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeListener == null) {
      _routeListener = _onRouteChanged;
      GoRouter.of(context).routerDelegate.addListener(_routeListener!);
    }
  }

  @override
  void dispose() {
    if (_routeListener != null) {
      GoRouter.of(context).routerDelegate.removeListener(_routeListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    _tapTimer?.cancel();
    _indicatorTimer?.cancel();
    _filterNameTimer?.cancel();
    _zoomTimer?.cancel();
    ref.read(cameraProvider.notifier).dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    final notifier = ref.read(cameraProvider.notifier);
    if (path == '/') {
      notifier.resumeSession();
    } else {
      notifier.pauseSession();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(cameraProvider.notifier);
    if (state == AppLifecycleState.paused) notifier.pauseSession();
    if (state == AppLifecycleState.resumed) notifier.resumeSession();
  }

  // ── 제스처 ───────────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _baseZoom = _currentZoom;
    _lastFocalPoint = d.focalPoint;
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
      // 단일 손가락 드래그 → 노출/대비
      final delta = d.focalPoint - _lastFocalPoint!;
      if (delta.dy.abs() > delta.dx.abs()) {
        ref.read(cameraProvider.notifier).adjustExposure(delta.dy);
        setState(() => _showExposureIndicator = true);
      } else {
        ref.read(cameraProvider.notifier).adjustContrast(delta.dx);
        setState(() => _showContrastIndicator = true);
      }
      _resetIndicatorTimer();
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
    setState(() => _isComparing = false);
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
                      top: 0, left: 0, right: 0,
                      bottom: _showIntensityPanel ? 100 : 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _onTap,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                      ),
                    ),

                  // 상단 바
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: _buildTopBar(camState),
                  ),

                  // 우측 플로팅 버튼
                  Positioned(
                    right: 12, bottom: 80,
                    child: _buildSideButtons(camState),
                  ),

                  // 필터 강도 바
                  if (_showIntensityPanel)
                    Positioned(
                      bottom: 20, left: 16, right: 16,
                      child: _buildIntensityBar(camState),
                    ),

                  // Exposure 인디케이터
                  Positioned(
                    left: 16, top: 0, bottom: 0,
                    child: Center(
                      child: ExposureIndicator(
                        exposure: camState.exposure,
                        visible: _showExposureIndicator,
                      ),
                    ),
                  ),

                  // Contrast 인디케이터
                  Positioned(
                    bottom: 16, left: 0, right: 0,
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
                    const Positioned.fill(
                      child: _CompareSplitOverlay(),
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

    Widget preview = ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 3, height: 4,
          child: Texture(textureId: camState.textureId!),
        ),
      ),
    );

    if (camState.isFront) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: preview,
      );
    }
    return preview;
  }

  Widget _buildTopBar(CameraState camState) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Colors.transparent],
        ),
      ),
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
          onTap: _cycleTimer,
          child: Container(
            width: 44, height: 44,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const Icon(Icons.timer_outlined,
                    color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 12),

        // 필터 강도
        _SideCircleButton(
          icon: Icons.tune,
          active: _showIntensityPanel,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showIntensityPanel = !_showIntensityPanel);
          },
        ),
        const SizedBox(height: 12),

        // 비교 — 길게 눌러서 원본 표시
        GestureDetector(
          onLongPressStart: (_) => _startCompare(),
          onLongPressEnd: (_) => _stopCompare(),
          onTap: () => HapticFeedback.selectionClick(),
          child: Container(
            width: 44, height: 44,
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
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 설정
        _SideCircleButton(
          icon: Icons.settings_outlined,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildIntensityBar(CameraState camState) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.tune, color: AppColors.textSecondary, size: 15),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: AppColors.silver,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.white,
                overlayColor: AppColors.silver.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: camState.filterIntensity,
                onChanged: (v) =>
                    ref.read(cameraProvider.notifier).setFilterIntensity(v),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${(camState.filterIntensity * 100).round()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
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
                  ? BeautyPanel(
                      key: const ValueKey('beauty'),
                      visible: true,
                      onChanged: (mode, intensity) {
                        final n = ref.read(cameraProvider.notifier);
                        switch (mode) {
                          case BeautyMode.soft:
                            n.setGrain(5.0 * (1 - intensity));
                          case BeautyMode.glow:
                            n.setLightLeak(intensity * 30);
                          case BeautyMode.silky:
                            n.setGrain(2.0);
                            n.setVignette(intensity * 10);
                        }
                      },
                    )
                  : _showFilterBar
                      ? FilterScrollBar(
                          key: const ValueKey('filter'),
                          filters: BWFilters.all,
                          selectedId: camState.activeFilter.id,
                          onFilterSelected: (f) =>
                              ref.read(cameraProvider.notifier).setFilter(f),
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
                      _BottomIconButton(
                        icon: Icons.photo_library_outlined,
                        onTap: () => context.push('/gallery'),
                      ),
                      const SizedBox(width: 12),
                      _BottomIconButton(
                        icon: Icons.auto_awesome_outlined,
                        active: _showFilterBar,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showFilterBar = !_showFilterBar;
                            if (_showFilterBar) _showBeautyPanel = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 셔터 / 동영상 셔터
                _isVideoMode
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

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _BottomIconButton(
                        icon: Icons.auto_fix_high,
                        active: _showBeautyPanel,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showBeautyPanel = !_showBeautyPanel;
                            if (_showBeautyPanel) _showFilterBar = false;
                          });
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
    required this.onTap,
    this.size = 22,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
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
      child: Icon(icon, color: Colors.white, size: size),
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

// ── 비교 모드 분할 오버레이 ───────────────────────────────────────────────────

class _CompareSplitOverlay extends StatelessWidget {
  const _CompareSplitOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 중앙 분할선
        Center(
          child: Container(
            width: 1.5,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        // 중앙 핸들
        Center(
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
        // BEFORE 레이블 (왼쪽)
        Positioned(
          top: 14, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'BEFORE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        // AFTER 레이블 (오른쪽)
        Positioned(
          top: 14, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'AFTER',
              style: TextStyle(
                color: AppColors.silver,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
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
