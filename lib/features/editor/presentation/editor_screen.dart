import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  double _grain     = 20.0;  //    0 ~ 100
  double _vignette  = 15.0;  //    0 ~ 100

  int _selectedSlider = 0;   // 현재 포커스된 슬라이더 인덱스

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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();   // TODO: 실제 저장 로직 연결
                    },
                    child: const Text(
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
              child: ColorFiltered(
                colorFilter: _buildFilter(),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  width: double.infinity,
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
