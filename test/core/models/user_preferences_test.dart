// 🔴 RED → 🟢 GREEN → 🔵 REFACTOR
import 'package:flutter_test/flutter_test.dart';
import 'package:likethis/core/models/user_preferences.dart';

void main() {
  group('UserPreferences', () {
    test('기본 lastUsedFilterId는 bw_pure다', () {
      final prefs = UserPreferences();
      expect(prefs.lastUsedFilterId, equals('bw_pure'));
    });

    test('기본 즐겨찾기 목록은 비어있다', () {
      final prefs = UserPreferences();
      expect(prefs.favoriteFilterIds, isEmpty);
    });

    group('toggleFavorite', () {
      test('즐겨찾기 추가', () {
        final prefs = UserPreferences();
        prefs.toggleFavorite('bw_noir');
        expect(prefs.isFavorite('bw_noir'), isTrue);
      });

      test('즐겨찾기 제거', () {
        final prefs = UserPreferences(favoriteFilterIds: ['bw_noir']);
        prefs.toggleFavorite('bw_noir');
        expect(prefs.isFavorite('bw_noir'), isFalse);
      });

      test('토글 2번 = 원래 상태', () {
        final prefs = UserPreferences();
        prefs.toggleFavorite('bw_soft');
        prefs.toggleFavorite('bw_soft');
        expect(prefs.isFavorite('bw_soft'), isFalse);
      });

      test('여러 필터 즐겨찾기 독립적 동작', () {
        final prefs = UserPreferences();
        prefs.toggleFavorite('bw_pure');
        prefs.toggleFavorite('bw_noir');
        expect(prefs.isFavorite('bw_pure'), isTrue);
        expect(prefs.isFavorite('bw_noir'), isTrue);
        prefs.toggleFavorite('bw_pure');
        expect(prefs.isFavorite('bw_pure'), isFalse);
        expect(prefs.isFavorite('bw_noir'), isTrue);
      });
    });

    group('copyWith', () {
      test('hapticEnabled 변경', () {
        final prefs = UserPreferences();
        final updated = prefs.copyWith(hapticEnabled: false);
        expect(updated.hapticEnabled, isFalse);
        expect(prefs.hapticEnabled, isTrue); // 원본 불변
      });

      test('totalPhotosCaptured 증가', () {
        final prefs = UserPreferences(totalPhotosCaptured: 5);
        final updated = prefs.copyWith(totalPhotosCaptured: 6);
        expect(updated.totalPhotosCaptured, equals(6));
      });
    });

    test('isFavorite: 없는 필터는 false', () {
      final prefs = UserPreferences();
      expect(prefs.isFavorite('bw_not_exist'), isFalse);
    });
  });
}
