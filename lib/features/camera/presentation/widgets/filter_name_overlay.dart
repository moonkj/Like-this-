import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';

/// 더블탭으로 필터 전환 시 필터명을 잠깐 표시
class FilterNameOverlay extends StatefulWidget {
  const FilterNameOverlay({
    super.key,
    required this.filterName,
    required this.visible,
  });

  final String filterName;
  final bool visible;

  @override
  State<FilterNameOverlay> createState() => _FilterNameOverlayState();
}

class _FilterNameOverlayState extends State<FilterNameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(FilterNameOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward(from: 0.0);
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: child,
        ),
      ),
      child: Text(
        widget.filterName.toUpperCase(),
        style: AppTypography.filterOverlay,
        textAlign: TextAlign.center,
      ),
    );
  }
}
