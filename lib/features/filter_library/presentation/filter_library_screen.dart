import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/filter_model.dart';
import '../../camera/providers/camera_provider.dart';

/// 전체 필터 목록 화면 — 9종 B&W 필터 그리드
class FilterLibraryScreen extends ConsumerWidget {
  const FilterLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camState = ref.watch(cameraProvider);
    final topPad   = MediaQuery.of(context).padding.top;
    final botPad   = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            SizedBox(height: topPad),

            // ── 상단 바 ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const Text(
                    'FILTERS',
                    style: TextStyle(
                      color: AppColors.silver,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(width: 22), // 우측 균형
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // ── 필터 그리드 ──────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, botPad > 0 ? botPad : 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: BWFilters.all.length,
                itemBuilder: (context, index) {
                  final filter = BWFilters.all[index];
                  final isSelected = filter.id == camState.activeFilter.id;
                  return _FilterCard(
                    filter: filter,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(cameraProvider.notifier).setFilter(filter);
                      context.pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 필터 카드 ─────────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final FilterModel filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.silver : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 색상 스워치 (썸네일 대용)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: filter.fallbackColor),

                    // 이펙트 타입 뱃지
                    if (filter.enabledEffects.isNotEmpty)
                      Positioned(
                        top: 8, right: 8,
                        child: _EffectBadge(effects: filter.enabledEffects),
                      ),

                    // 선택 체크
                    if (isSelected)
                      Container(
                        color: Colors.black38,
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 필터명 + 설명
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filter.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.silver : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    filter.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이펙트 뱃지 ───────────────────────────────────────────────────────────────

class _EffectBadge extends StatelessWidget {
  const _EffectBadge({required this.effects});

  final List<BWEffectType> effects;

  static IconData _iconFor(BWEffectType e) {
    return switch (e) {
      BWEffectType.grain     => Icons.grain,
      BWEffectType.vignette  => Icons.vignette,
      BWEffectType.lightLeak => Icons.flare,
      BWEffectType.bloom     => Icons.blur_on,
      BWEffectType.dust      => Icons.filter_drama_outlined,
      BWEffectType.beauty    => Icons.face_retouching_natural,
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(effects.first);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: AppColors.silver, size: 12),
    );
  }
}
