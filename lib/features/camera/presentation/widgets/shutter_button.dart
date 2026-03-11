import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// 셔터 버튼 — Silver 아웃라인 링 스타일 (Like It 참조)
class ShutterButton extends StatefulWidget {
  const ShutterButton({
    super.key,
    required this.onTap,
    this.isCapturing = false,
  });

  final VoidCallback onTap;
  final bool isCapturing;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    HapticFeedback.heavyImpact();          // 셔터 누름 — 묵직한 피드백
    await _controller.forward();
    widget.onTap();
    await _controller.reverse();
    HapticFeedback.lightImpact();          // 셔터 해제 — 가벼운 클릭감
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isCapturing ? null : _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: SizedBox(
          width: AppDimensions.shutterOuter + 8,
          height: AppDimensions.shutterOuter + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 외부 링 (Silver outline)
              Container(
                width: AppDimensions.shutterOuter + 8,
                height: AppDimensions.shutterOuter + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.silver,
                    width: 2.5,
                  ),
                ),
              ),
              // 내부 채워진 원
              Container(
                width: AppDimensions.shutterInner,
                height: AppDimensions.shutterInner,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isCapturing
                      ? AppColors.silverDark
                      : AppColors.white,
                ),
                child: widget.isCapturing
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.background),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
