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

  bool _showExposureIndicator = false;
  bool _showContrastIndicator = false;
  bool _showFilterName = false;
  bool _showBeautyPanel = false;    // 효과 패널
  bool _showFilterBar = false;      // 필터바 토글
  bool _showIntensityPanel = false; // 우측 사이드: 필터 강도
  bool _isVideoMode = false;

  int _tapCount = 0;
  Timer? _tapTimer;
  Timer? _indicatorTimer;
  Timer? _filterNameTimer;
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

  void _onVerticalDrag(DragUpdateDetails d) {
    ref.read(cameraProvider.notifier).adjustExposure(d.delta.dy);
    setState(() => _showExposureIndicator = true);
    _resetIndicatorTimer();
  }

  void _onHorizontalDrag(DragUpdateDetails d) {
    ref.read(cameraProvider.notifier).adjustContrast(d.delta.dx);
    setState(() => _showContrastIndicator = true);
    _resetIndicatorTimer();
  }

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
            // ── 상태바 영역 확보 (카메라는 상태바 아래에서 시작) ────────
            SizedBox(height: topPad),

            // ── 카메라 프리뷰: 3:4 비율 고정 ──────────────────────────
            AspectRatio(
              aspectRatio: 3.0 / 4.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(camState),

                  // 제스처
                  if (camState.isReady)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _onTap,
                      onVerticalDragUpdate: _onVerticalDrag,
                      onHorizontalDragUpdate: _onHorizontalDrag,
                    ),

                  // 상단 그라디언트 바 (카메라 기준 top=0)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: _buildTopBar(),
                  ),

                  // 우측 플로팅 버튼 — 강도 바 위쪽에 bottom 고정
                  Positioned(
                    right: 12,
                    bottom: 80,
                    child: _buildSideButtons(camState),
                  ),

                  // 필터 강도 가로 바 (카메라 하단)
                  if (_showIntensityPanel)
                    Positioned(
                      bottom: 20, left: 16, right: 16,
                      child: _buildIntensityBar(camState),
                    ),

                  // Exposure 인디케이터 (좌측)
                  Positioned(
                    left: 16,
                    top: 0, bottom: 0,
                    child: Center(
                      child: ExposureIndicator(
                        exposure: camState.exposure,
                        visible: _showExposureIndicator,
                      ),
                    ),
                  ),

                  // Contrast 인디케이터 (하단)
                  Positioned(
                    bottom: 16, left: 0, right: 0,
                    child: Center(
                      child: ContrastIndicator(
                        contrast: camState.contrast,
                        visible: _showContrastIndicator,
                      ),
                    ),
                  ),

                  // 필터명 오버레이
                  Center(
                    child: FilterNameOverlay(
                      filterName: camState.activeFilter.name,
                      visible: _showFilterName,
                    ),
                  ),
                ],
              ),
            ),

            // ── 하단 컨트롤 패널 (남은 공간 채움) ─────────────────────
            Expanded(child: _buildBottomPanel(camState, botPad)),
          ],
        ),
      ),
    );
  }

  // ── 카메라 프리뷰: BoxFit.cover로 화면 채움 ──────────────────────────

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

    // ── FittedBox(cover) + SizedBox(3,4) ──
    // 카메라 버퍼는 4:3(portrait). 화면이 더 좁을 때(세로 긺)
    // cover 방식으로 채우면 좌우가 약간 crop됨 — Like It과 동일
    Widget preview = ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 3,
          height: 4,
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

  // ── 상단 바 ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(
          top: 10, left: 16, right: 16, bottom: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SideCircleButton(icon: Icons.flash_off, size: 20, onTap: () {}),
          const Text(
            'LIKE THIS',
            style: TextStyle(
              color: AppColors.silver,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.5,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── 우측 플로팅 버튼 ─────────────────────────────────────────────

  Widget _buildSideButtons(CameraState camState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideCircleButton(icon: Icons.timer_outlined, onTap: () {}),
        const SizedBox(height: 12),
        _SideCircleButton(
          icon: Icons.tune,
          active: _showIntensityPanel,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showIntensityPanel = !_showIntensityPanel);
          },
        ),
        const SizedBox(height: 12),
        _SideCircleButton(icon: Icons.compare, onTap: () {}),
        const SizedBox(height: 12),
        _SideCircleButton(
          icon: Icons.settings_outlined,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  // ── 필터 강도 가로 바 ─────────────────────────────────────────────

  Widget _buildIntensityBar(CameraState camState) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.tune, color: AppColors.textSecondary, size: 14),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.silver,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.white,
                overlayColor: AppColors.silver.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: camState.filterIntensity,
                onChanged: (v) => ref.read(cameraProvider.notifier).setFilterIntensity(v),
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

  // ── 하단 패널 ─────────────────────────────────────────────────────

  Widget _buildBottomPanel(CameraState camState, double botPad) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 8),

          // 고정 116px 패널 영역: 필터바 / 효과 패널 / 빈 공간
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

          // 5버튼 행: [갤러리] [필터★] [셔터] [효과★] [플립]
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, botPad > 0 ? botPad : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측: 갤러리 + 필터
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
                // 중앙: 셔터
                ShutterButton(
                  isCapturing: camState.status == CameraStatus.capturing,
                  onTap: () => ref.read(cameraProvider.notifier).capturePhoto(),
                ),
                // 우측: 효과 + 플립
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

// ── 공통 위젯 ─────────────────────────────────────────────────────────────

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
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
