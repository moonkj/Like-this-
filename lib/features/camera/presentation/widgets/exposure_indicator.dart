import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// 수직 스와이프 시 표시되는 Exposure 인디케이터
class ExposureIndicator extends StatelessWidget {
  const ExposureIndicator({
    super.key,
    required this.exposure,
    required this.visible,
  });

  final double exposure; // -100 ~ +100
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final ev = (exposure / 50.0); // -2.0 ~ +2.0 EV
    final evText = ev >= 0 ? '+${ev.toStringAsFixed(1)}' : ev.toStringAsFixed(1);

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exposure > 5 ? Icons.wb_sunny : Icons.brightness_3,
              color: AppColors.silver,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'EV $evText',
              style: AppTypography.indicator,
            ),
          ],
        ),
      ),
    );
  }
}

/// 수평 스와이프 시 표시되는 Contrast 인디케이터
class ContrastIndicator extends StatelessWidget {
  const ContrastIndicator({
    super.key,
    required this.contrast,
    required this.visible,
  });

  final double contrast; // -100 ~ +100
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final normalized = (contrast + 100) / 200.0; // 0.0 ~ 1.0
    final label = contrast > 5
        ? '강렬하게'
        : contrast < -5
            ? '부드럽게'
            : '기본';

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.contrast, color: AppColors.silver, size: 14),
                const SizedBox(width: 6),
                Text('대비  $label', style: AppTypography.indicator),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: normalized,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.silver),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
