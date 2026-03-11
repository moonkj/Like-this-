import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';

/// 사진 편집 화면 — B&W 파라미터 슬라이더
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  double _exposure  = 0.0;   // -100 ~ +100
  double _contrast  = 0.0;   // -100 ~ +100
  double _grain     = 0.0;   //    0 ~ 100  (0으로 시작 — 카메라가 이미 적용)
  double _vignette  = 0.0;   //    0 ~ 100  (0으로 시작 — 카메라가 이미 적용)

  int _selectedSlider = 0;   // 현재 포커스된 슬라이더 인덱스
  bool _isSaving = false;

  final GlobalKey _previewKey = GlobalKey();

  // ── 저장 ────────────────────────────────────────────────────────────────────
  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _previewKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final fileName =
          'likethis_edit_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await PhotoManager.editor.saveImageWithPath(
        file.path,
        title: fileName,
      );

      HapticFeedback.lightImpact();
      if (context.mounted) context.pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장에 실패했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── B&W + Exposure + Contrast ColorFilter 매트릭스 ──────────────────────────
  ColorFilter _buildFilter() {
    final ev  = _exposure / 100.0 * 0.4;            // -0.4 ~ +0.4 오프셋
    final c   = 1.0 + _contrast / 100.0 * 0.8;     // 0.2 ~ 1.8 배율
    final bias = ev * 255 + (1.0 - c) * 127.5;     // 밝기 오프셋
    final r = 0.299 * c;
    final g = 0.587 * c;
    final b = 0.114 * c;
    return ColorFilter.matrix([
      r, g, b, 0, bias,
      r, g, b, 0, bias,
      r, g, b, 0, bias,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            SizedBox(height: topPad),

            // ── 상단 바 ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Text(
                    'EDIT',
                    style: TextStyle(
                      color: AppColors.silver,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : () => _save(context),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(AppColors.silver),
                            ),
                          )
                        : const Text(
                            '저장',
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── 이미지 프리뷰 ─────────────────────────────────────────────
            Expanded(
              child: RepaintBoundary(
                key: _previewKey,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    // 이미지 + B&W + 노출/대비
                    ColorFiltered(
                      colorFilter: _buildFilter(),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                    // 비네팅 오버레이 (이미지 영역 전체)
                    if (_vignette > 0)
                      Positioned.fill(
                        child: _VignetteOverlay(intensity: _vignette / 100),
                      ),
                    // 그레인 오버레이
                    if (_grain > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GrainPainter(intensity: _grain / 100),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── 슬라이더 탭 선택기 ────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SliderTab(label: '노출',   index: 0, selected: _selectedSlider == 0, onTap: (i) => setState(() => _selectedSlider = i)),
                  _SliderTab(label: '대비',   index: 1, selected: _selectedSlider == 1, onTap: (i) => setState(() => _selectedSlider = i)),
                  _SliderTab(label: '그레인', index: 2, selected: _selectedSlider == 2, onTap: (i) => setState(() => _selectedSlider = i)),
                  _SliderTab(label: '비네팅', index: 3, selected: _selectedSlider == 3, onTap: (i) => setState(() => _selectedSlider = i)),
                ],
              ),
            ),

            // ── 슬라이더 ─────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(24, 0, 24, botPad > 0 ? botPad : 16),
              child: Column(
                children: [
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 4),
                  _buildActiveSlider(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSlider() {
    switch (_selectedSlider) {
      case 0:
        return _BwSlider(
          label: '노출', value: _exposure, min: -100, max: 100,
          onChanged: (v) => setState(() => _exposure = v),
        );
      case 1:
        return _BwSlider(
          label: '대비', value: _contrast, min: -100, max: 100,
          onChanged: (v) => setState(() => _contrast = v),
        );
      case 2:
        return _BwSlider(
          label: '그레인', value: _grain, min: 0, max: 100,
          onChanged: (v) => setState(() => _grain = v),
        );
      case 3:
        return _BwSlider(
          label: '비네팅', value: _vignette, min: 0, max: 100,
          onChanged: (v) => setState(() => _vignette = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── 슬라이더 탭 ──────────────────────────────────────────────────────────────

class _SliderTab extends StatelessWidget {
  const _SliderTab({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap(index);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.silver : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}

// ── 비네팅 오버레이 ───────────────────────────────────────────────────────────

class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay({required this.intensity});

  final double intensity; // 0.0 ~ 1.0

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: intensity * 0.85),
          ],
          stops: const [0.35, 1.0],
        ),
      ),
    );
  }
}

// ── 그레인 페인터 ──────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.intensity});

  final double intensity; // 0.0 ~ 1.0

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final count = (size.width * size.height * intensity * 0.04).toInt();
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final bright = rng.nextBool();
      paint.color = (bright ? Colors.white : Colors.black)
          .withValues(alpha: 0.15 + rng.nextDouble() * intensity * 0.45);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.4 + rng.nextDouble() * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.intensity != intensity;
}

// ── B&W 슬라이더 ─────────────────────────────────────────────────────────────

class _BwSlider extends StatelessWidget {
  const _BwSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.silver,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.white,
              overlayColor: AppColors.silver.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
