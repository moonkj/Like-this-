import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/camera_state.dart';
import '../../providers/camera_provider.dart';

/// Beauty Mode 효과 패널
enum BeautyMode {
  soft(     'Soft',       '피부 결 부드럽게'),
  glow(     'Glow',       '은은한 피부 광채'),
  silky(    'Silky',      '매끈한 셀카 톤'),
  softDepth('Soft Depth', '배경 블러, 인물 선명');

  const BeautyMode(this.label, this.description);
  final String label;
  final String description;
}

/// 효과 탭 정의 (노출~글로우)
enum _EffectTab {
  exposure( '노출',   -100.0, 100.0),
  contrast( '대비',   -100.0, 100.0),
  grain(    '그레인',    0.0, 100.0),
  vignette( '비네팅',   0.0, 100.0),
  lightLeak('빛번짐',   0.0, 100.0),
  bloom(    '글로우',   0.0, 100.0);

  const _EffectTab(this.label, this.min, this.max);
  final String label;
  final double min;
  final double max;
}

/// 효과 + 뷰티 통합 패널 (탭 선택 → 단일 슬라이더)
class BeautyPanel extends ConsumerStatefulWidget {
  const BeautyPanel({super.key});

  @override
  ConsumerState<BeautyPanel> createState() => _BeautyPanelState();
}

class _BeautyPanelState extends ConsumerState<BeautyPanel> {
  // 탭 인덱스: 0~5 = 효과, 6~9 = 뷰티 모드
  int _selectedIndex = 0;
  double _beautyIntensity = 0.5;

  static const _effectCount = 6;   // _EffectTab.values.length
  static const _beautyCount = 4;   // BeautyMode.values.length

  BeautyMode get _selectedBeautyMode =>
      BeautyMode.values[_selectedIndex - _effectCount];

  bool get _isEffectTab => _selectedIndex < _effectCount;

  @override
  void initState() {
    super.initState();
    final s = ref.read(cameraProvider);
    final beautyIdx = BeautyMode.values.indexWhere((m) => m.name == s.beautyMode);
    if (beautyIdx >= 0) _selectedIndex = _effectCount + beautyIdx;
    _beautyIntensity = s.beautyIntensity > 0 ? s.beautyIntensity : 0.5;
  }

  // 현재 탭의 슬라이더 값
  double _currentValue(CameraState s) {
    if (_isEffectTab) {
      return switch (_EffectTab.values[_selectedIndex]) {
        _EffectTab.exposure  => s.exposure,
        _EffectTab.contrast  => s.contrast,
        _EffectTab.grain     => s.grain,
        _EffectTab.vignette  => s.vignette,
        _EffectTab.lightLeak => s.lightLeak,
        _EffectTab.bloom     => s.bloom,
      };
    }
    return _beautyIntensity;
  }

  double get _currentMin => _isEffectTab
      ? _EffectTab.values[_selectedIndex].min
      : 0.0;

  double get _currentMax => _isEffectTab
      ? _EffectTab.values[_selectedIndex].max
      : 1.0;

  void _onSliderChanged(double v, CameraNotifier notifier) {
    if (_isEffectTab) {
      switch (_EffectTab.values[_selectedIndex]) {
        case _EffectTab.exposure:  notifier.setExposure(v);
        case _EffectTab.contrast:  notifier.setContrast(v);
        case _EffectTab.grain:     notifier.setGrain(v);
        case _EffectTab.vignette:  notifier.setVignette(v);
        case _EffectTab.lightLeak: notifier.setLightLeak(v);
        case _EffectTab.bloom:     notifier.setBloom(v);
      }
    } else {
      setState(() => _beautyIntensity = v);
      notifier.setBeauty(_selectedBeautyMode.name, v);
    }
  }

  String _displayValue(double v) {
    if (_isEffectTab) return v.round().toString();
    return '${(v * 100).round()}';
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(cameraProvider);
    final notifier = ref.read(cameraProvider.notifier);
    final value    = _currentValue(state);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 탭 목록 ────────────────────────────────────────────────
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _effectCount + _beautyCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _selectedIndex;
                final label = i < _effectCount
                    ? _EffectTab.values[i].label
                    : BeautyMode.values[i - _effectCount].label;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = i);
                    // 뷰티 탭 선택 시 즉시 적용
                    if (i >= _effectCount) {
                      notifier.setBeauty(
                        BeautyMode.values[i - _effectCount].name,
                        _beautyIntensity,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.silver.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: selected ? AppColors.silver : AppColors.border,
                        width: selected ? 1.0 : 0.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: selected
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

          // ── 단일 슬라이더 ───────────────────────────────────────────
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
                    value: value.clamp(_currentMin, _currentMax),
                    min: _currentMin,
                    max: _currentMax,
                    onChanged: (v) => _onSliderChanged(v, notifier),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  _displayValue(value),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
