import 'package:flutter/material.dart';

/// B&W 필터 카테고리 — Like This는 blackwhite 단일 카테고리
enum FilterCategory {
  blackwhite,
}

/// B&W 필터 이펙트 타입
enum BWEffectType {
  grain,      // 아날로그 입자감
  lightLeak,  // 빛 번짐 (흰색 오버레이)
  vignette,   // 주변부 어둠
  dust,       // 먼지 텍스처 (Film Dust 전용)
  bloom,      // Highlights 번짐 (Silver Glow 전용)
  beauty,     // 피부 보정 (Porcelain/Silky 전용)
}

/// 흑백 필터 모델
class FilterModel {
  const FilterModel({
    required this.id,
    required this.name,
    required this.lutFileName,
    required this.description,
    this.defaultIntensity = 1.0,
    this.defaultGrain = 20.0,
    this.defaultVignette = 15.0,
    this.defaultLightLeak = 0.0,
    this.defaultDust = 0.0,
    this.defaultBloom = 0.0,
    this.enabledEffects = const [],
    this.fallbackColor = const Color(0xFF1A1A1A),
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String lutFileName;
  final String description;
  final double defaultIntensity;    // 0.0 ~ 1.0
  final double defaultGrain;        // 0 ~ 100
  final double defaultVignette;     // 0 ~ 100
  final double defaultLightLeak;    // 0 ~ 100
  final double defaultDust;         // 0 ~ 100 — Film Dust 전용
  final double defaultBloom;        // 0 ~ 100 — Silver Glow 전용
  final List<BWEffectType> enabledEffects;
  final Color fallbackColor;        // 썸네일 없을 때 배경색
  final bool isFavorite;

  FilterModel copyWith({
    bool? isFavorite,
    double? defaultIntensity,
  }) => FilterModel(
    id: id,
    name: name,
    lutFileName: lutFileName,
    description: description,
    defaultIntensity: defaultIntensity ?? this.defaultIntensity,
    defaultGrain: defaultGrain,
    defaultVignette: defaultVignette,
    defaultLightLeak: defaultLightLeak,
    defaultDust: defaultDust,
    defaultBloom: defaultBloom,
    enabledEffects: enabledEffects,
    fallbackColor: fallbackColor,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  @override
  bool operator ==(Object other) =>
    other is FilterModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 7종 B&W 필터 데이터 레지스트리
abstract final class BWFilters {
  static const FilterModel pureThis = FilterModel(
    id: 'bw_pure',
    name: 'Pure This',
    lutFileName: 'bw_pure.cube',
    description: '가장 화사하고 깨끗한 흑백',
    defaultIntensity: 1.0,
    defaultGrain: 0.0,       // 노이즈 없이 순수하게
    defaultVignette: 0.0,    // 주변부 어둠 없음
    enabledEffects: [],
    fallbackColor: Color(0xFF2A2A2A),
  );

  static const FilterModel deepNoir = FilterModel(
    id: 'bw_noir',
    name: 'Deep Noir',
    lutFileName: 'bw_noir.cube',
    description: '강렬한 대비의 느와르 감성',
    defaultIntensity: 1.0,   // 풀 강도로 블랙 극대화
    defaultGrain: 38.0,      // 필름 분위기 살리는 입자감
    defaultVignette: 48.0,   // 강한 주변부 어둠 — 느와르 핵심
    enabledEffects: [BWEffectType.vignette],
    fallbackColor: Color(0xFF0D0D0D),
  );

  static const FilterModel softGrey = FilterModel(
    id: 'bw_soft',
    name: 'Soft Grey',
    lutFileName: 'bw_soft.cube',
    description: '연필 소묘 같은 부드러움',
    defaultIntensity: 0.88,  // 살짝 눌러서 부드러운 계조
    defaultGrain: 6.0,       // 거의 없는 수준 — 에어리한 느낌
    defaultVignette: 6.0,    // 아주 은은한 테두리
    enabledEffects: [],
    fallbackColor: Color(0xFF3A3A3A),
  );

  static const FilterModel bw2k = FilterModel(
    id: 'bw_2k',
    name: 'BY2K',
    lutFileName: 'bw_2k.cube',
    description: '2000년대 디카 흑백 모드',
    defaultIntensity: 0.85,
    defaultGrain: 45.0,      // 디지털 노이즈 느낌의 굵은 입자
    defaultVignette: 22.0,   // 저가형 렌즈 주변부 열화
    enabledEffects: [BWEffectType.grain],
    fallbackColor: Color(0xFF252525),
  );

  static const FilterModel filmDust = FilterModel(
    id: 'bw_dust',
    name: 'Film Dust',
    lutFileName: 'bw_dust.cube',
    description: '먼지와 입자가 섞인 빈티지',
    defaultIntensity: 0.82,
    defaultGrain: 60.0,      // 빈티지 필름의 heavy grain
    defaultVignette: 30.0,   // 오래된 렌즈 느낌
    defaultDust: 55.0,       // 먼지 텍스처 — 이 필터의 핵심
    enabledEffects: [BWEffectType.grain, BWEffectType.dust],
    fallbackColor: Color(0xFF1E1E1E),
  );

  static const FilterModel silverGlow = FilterModel(
    id: 'bw_glow',
    name: 'Silver Glow',
    lutFileName: 'bw_glow.cube',
    description: '금속성 광택이 도는 물광',
    defaultIntensity: 0.88,
    defaultGrain: 3.0,       // 글로우 효과가 돋보이도록 최소
    defaultVignette: 8.0,    // 중심으로 시선 집중
    defaultBloom: 28.0,      // 하이라이트 번짐 — 자연스러운 물광
    enabledEffects: [BWEffectType.bloom],
    fallbackColor: Color(0xFF303030),
  );

  static const FilterModel paperLog = FilterModel(
    id: 'bw_paper',
    name: 'Paper Log',
    lutFileName: 'bw_paper.cube',
    description: '종이에 인쇄한 듯한 질감',
    defaultIntensity: 0.88,
    defaultGrain: 18.0,      // 인쇄 질감의 미세 입자
    defaultVignette: 40.0,   // 오래된 사진 인화지 느낌
    enabledEffects: [BWEffectType.vignette],
    fallbackColor: Color(0xFF1A1715),
  );

  static const FilterModel porcelainBW = FilterModel(
    id: 'bw_porcelain',
    name: 'Porcelain',
    lutFileName: 'bw_porcelain.cube',
    description: '미드톤 밝게, 블랙 리프트 — 매끈한 피부 표현',
    defaultIntensity: 0.95,  // 거의 풀 강도 — 밝기 극대화
    defaultGrain: 2.0,       // 피부 표현 위해 최소
    defaultVignette: 5.0,    // 아주 은은하게
    enabledEffects: [BWEffectType.beauty],
    fallbackColor: Color(0xFF3D3D3D),
  );

  static const FilterModel silkyBW = FilterModel(
    id: 'bw_silky',
    name: 'Silky',
    lutFileName: 'bw_silky.cube',
    description: '대비 낮추고 부드럽게 — 셀카 전용',
    defaultIntensity: 0.92,
    defaultGrain: 0.0,       // 완전 무결점 — 셀카 최적
    defaultVignette: 3.0,    // 거의 없는 수준
    enabledEffects: [BWEffectType.beauty],
    fallbackColor: Color(0xFF383838),
  );

  /// 순서 있는 전체 목록 (더블탭 사이클 순서)
  static const List<FilterModel> all = [
    pureThis,
    deepNoir,
    softGrey,
    bw2k,
    filmDust,
    silverGlow,
    paperLog,
    porcelainBW,
    silkyBW,
  ];

  static FilterModel byId(String id) =>
    all.firstWhere((f) => f.id == id, orElse: () => pureThis);

  static FilterModel next(String currentId) {
    final idx = all.indexWhere((f) => f.id == currentId);
    return all[(idx + 1) % all.length];
  }
}
