/// 사용자 설정 — 메모리 기반 (Hive 의존성 제거, 단순화)
class UserPreferences {
  UserPreferences({
    this.lastUsedFilterId = 'bw_pure',
    this.favoriteFilterIds = const [],
    this.defaultGrain = 20.0,
    this.defaultVignette = 15.0,
    this.hapticEnabled = true,
    this.saveToGallery = true,
    this.totalPhotosCaptured = 0,
  });

  String lastUsedFilterId;
  List<String> favoriteFilterIds;
  double defaultGrain;
  double defaultVignette;
  bool hapticEnabled;
  bool saveToGallery;
  int totalPhotosCaptured;

  bool isFavorite(String filterId) => favoriteFilterIds.contains(filterId);

  void toggleFavorite(String filterId) {
    if (favoriteFilterIds.contains(filterId)) {
      favoriteFilterIds = favoriteFilterIds.where((id) => id != filterId).toList();
    } else {
      favoriteFilterIds = [...favoriteFilterIds, filterId];
    }
  }

  UserPreferences copyWith({
    String? lastUsedFilterId,
    List<String>? favoriteFilterIds,
    double? defaultGrain,
    double? defaultVignette,
    bool? hapticEnabled,
    bool? saveToGallery,
    int? totalPhotosCaptured,
  }) => UserPreferences(
    lastUsedFilterId: lastUsedFilterId ?? this.lastUsedFilterId,
    favoriteFilterIds: favoriteFilterIds ?? this.favoriteFilterIds,
    defaultGrain: defaultGrain ?? this.defaultGrain,
    defaultVignette: defaultVignette ?? this.defaultVignette,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    totalPhotosCaptured: totalPhotosCaptured ?? this.totalPhotosCaptured,
  );
}
