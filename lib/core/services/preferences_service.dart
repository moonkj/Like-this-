import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_preferences.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>(
  (ref) => PreferencesNotifier(),
);

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier() : super(UserPreferences()) {
    _load();
  }

  File? _file;

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/likethis_prefs.json');
      if (_file!.existsSync()) {
        final content = await _file!.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = UserPreferences.fromJson(json);
      }
    } catch (_) {
      // 파일 없거나 파싱 실패 → 기본값 유지
    }
  }

  Future<void> _save() async {
    await _file?.writeAsString(jsonEncode(state.toJson()));
  }

  Future<void> setHapticEnabled(bool value) async {
    state = state.copyWith(hapticEnabled: value);
    await _save();
  }

  Future<void> setSaveToGallery(bool value) async {
    state = state.copyWith(saveToGallery: value);
    await _save();
  }

  Future<void> setShutterSound(bool value) async {
    state = state.copyWith(shutterSound: value);
    await _save();
  }

  Future<void> setLastUsedFilter(String filterId) async {
    state = state.copyWith(lastUsedFilterId: filterId);
    await _save();
  }

  Future<void> toggleFavorite(String filterId) async {
    state.toggleFavorite(filterId);
    state = state.copyWith(favoriteFilterIds: List.from(state.favoriteFilterIds));
    await _save();
  }

  Future<void> incrementPhotoCount() async {
    state = state.copyWith(totalPhotosCaptured: state.totalPhotosCaptured + 1);
    await _save();
  }
}
