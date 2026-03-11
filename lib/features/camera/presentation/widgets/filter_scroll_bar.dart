import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/filter_model.dart';

/// 하단 필터 캐러셀 — 7종 B&W 필터
class FilterScrollBar extends StatefulWidget {
  const FilterScrollBar({
    super.key,
    required this.filters,
    required this.selectedId,
    required this.onFilterSelected,
  });

  final List<FilterModel> filters;
  final String selectedId;
  final ValueChanged<FilterModel> onFilterSelected;

  @override
  State<FilterScrollBar> createState() => _FilterScrollBarState();
}

class _FilterScrollBarState extends State<FilterScrollBar> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected(int index) {
    final targetOffset = index *
        (AppDimensions.filterThumbW + AppDimensions.spaceS) -
        100;
    _scroll.animateTo(
      targetOffset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.filterBarHeight,
      color: AppColors.filterBarBg,
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spaceS),
          // 필터 목록
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
              ),
              itemCount: widget.filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimensions.spaceS),
              itemBuilder: (context, index) {
                final filter = widget.filters[index];
                final isSelected = filter.id == widget.selectedId;
                return _FilterThumb(
                  filter: filter,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onFilterSelected(filter);
                    _scrollToSelected(index);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
        ],
      ),
    );
  }
}

class _FilterThumb extends StatelessWidget {
  const _FilterThumb({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final FilterModel filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = isSelected
        ? AppDimensions.filterThumbSelectedW
        : AppDimensions.filterThumbW;
    final h = isSelected
        ? AppDimensions.filterThumbSelectedH
        : AppDimensions.filterThumbH;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: w,
        child: Column(
          children: [
            // 썸네일
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: filter.fallbackColor,
                borderRadius:
                    BorderRadius.circular(AppDimensions.filterThumbRadius),
                border: isSelected
                    ? Border.all(
                        color: AppColors.filterSelected,
                        width: AppDimensions.filterBorderWidth,
                      )
                    : Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimensions.filterThumbRadius - 1),
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(height: 4),
            // 필터명
            Text(
              filter.name,
              style: isSelected
                  ? AppTypography.filterNameSelected
                  : AppTypography.filterName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbPath = 'assets/thumbnails/${filter.id}.jpg';
    return Image.asset(
      thumbPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: filter.fallbackColor,
        child: Center(
          child: Text(
            filter.name[0],
            style: const TextStyle(
              color: AppColors.silverLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
