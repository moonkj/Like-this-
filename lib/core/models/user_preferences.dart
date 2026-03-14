/// 사용자 설정 — 메모리 기반 (Hive 의존성 제거, 단순화)
class UserPreferences {
  UserPreferences({
    this.lastUsedFilterId = 'bw_pure',
    this.favoriteFilterIds = const [],
    this.defaultGrain = 20.0,
    this.defaultVignette = 15.0,
    this.hapticEnabled = true,
    this.saveToGallery = true,
    this.shutterSound = false,
    this.totalPhotosCaptured = 0,
  });

  String lastUsedFilterId;
  List<String> favoriteFilterIds;
  double defaultGrain;
  double defaultVignette;
  bool hapticEnabled;
  bool saveToGallery;
  bool shutterSound;
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
    bool? shutterSound,
    int? totalPhotosCaptured,
  }) => UserPreferences(
    lastUsedFilterId: lastUsedFilterId ?? this.lastUsedFilterId,
    favoriteFilterIds: favoriteFilterIds ?? this.favoriteFilterIds,
    defaultGrain: defaultGrain ?? this.defaultGrain,
    defaultVignette: defaultVignette ?? this.defaultVignette,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    shutterSound: shutterSound ?? this.shutterSound,
    totalPhotosCaptured: totalPhotosCaptured ?? this.totalPhotosCaptured,
  );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
    lastUsedFilterId: json['lastUsedFilterId'] as String? ?? 'bw_pure',
    favoriteFilterIds: (json['favoriteFilterIds'] as List<dynamic>?)
        ?.map((e) => e as String).toList() ?? const [],
    defaultGrain: (json['defaultGrain'] as num?)?.toDouble() ?? 20.0,
    defaultVignette: (json['defaultVignette'] as num?)?.toDouble() ?? 15.0,
    hapticEnabled: json['hapticEnabled'] as bool? ?? true,
    saveToGallery: json['saveToGallery'] as bool? ?? true,
    shutterSound: json['shutterSound'] as bool? ?? false,
    totalPhotosCaptured: json['totalPhotosCaptured'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'lastUsedFilterId': lastUsedFilterId,
    'favoriteFilterIds': favoriteFilterIds,
    'defaultGrain': defaultGrain,
    'defaultVignette': defaultVignette,
    'hapticEnabled': hapticEnabled,
    'saveToGallery': saveToGallery,
    'shutterSound': shutterSound,
    'totalPhotosCaptured': totalPhotosCaptured,
  };
}
