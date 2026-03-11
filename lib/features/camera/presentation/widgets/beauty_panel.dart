import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Beauty Mode 효과 패널
enum BeautyMode {
  soft(       'Soft',        '피부 결 부드럽게'),
  glow(       'Glow',        '은은한 피부 광채'),
  silky(      'Silky',       '매끈한 셀카 톤'),
  faceBright( '얼굴 밝기',    '얼굴 영역만 밝게'),
  shadowLift( '다크서클',     '저명도 대비 완화'),
  skinFocus(  'Skin Focus',  '배경 어둡게, 얼굴 강조'),
  softDepth(  'Soft Depth',  '배경 블러, 인물 선명');

  const BeautyMode(this.label, this.description);
  final String label;
  final String description;
}

class BeautyPanel extends StatefulWidget {
  const BeautyPanel({
    super.key,
    required this.onChanged,
    required this.visible,
  });

  final void Function(BeautyMode mode, double intensity) onChanged;
  final bool visible;

  @override
  State<BeautyPanel> createState() => _BeautyPanelState();
}

class _BeautyPanelState extends State<BeautyPanel>
    with SingleTickerProviderStateMixin {
  BeautyMode _mode = BeautyMode.soft;
  double _intensity = 0.5;

  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    if (widget.visible) _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BeautyPanel old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      if (widget.visible) _anim.forward();
      else _anim.reverse();
    }
  }

  void _selectMode(BeautyMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _mode = mode);
    widget.onChanged(_mode, _intensity);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 모드 선택 탭 (가로 스크롤)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: BeautyMode.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final mode = BeautyMode.values[i];
                  final isSelected = mode == _mode;
                  return GestureDetector(
                    onTap: () => _selectMode(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.silver.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.silver
                              : AppColors.border,
                          width: isSelected ? 1.0 : 0.5,
                        ),
                      ),
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // 강도 슬라이더
            Row(
              children: [
                const Icon(Icons.lens_blur,
                    color: AppColors.textSecondary, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.silver,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.white,
                      overlayColor:
                          AppColors.silver.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _intensity,
                      onChanged: (v) {
                        setState(() => _intensity = v);
                        widget.onChanged(_mode, _intensity);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${(_intensity * 100).round()}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
