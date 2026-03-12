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

    group('fromJson / toJson', () {
      test('toJson은 모든 필드를 포함한다', () {
        final prefs = UserPreferences(
          lastUsedFilterId: 'bw_noir',
          favoriteFilterIds: ['bw_soft'],
          defaultGrain: 30.0,
          defaultVignette: 25.0,
          hapticEnabled: false,
          saveToGallery: false,
          totalPhotosCaptured: 42,
        );
        final json = prefs.toJson();
        expect(json['lastUsedFilterId'], equals('bw_noir'));
        expect(json['favoriteFilterIds'], equals(['bw_soft']));
        expect(json['defaultGrain'], equals(30.0));
        expect(json['defaultVignette'], equals(25.0));
        expect(json['hapticEnabled'], isFalse);
        expect(json['saveToGallery'], isFalse);
        expect(json['totalPhotosCaptured'], equals(42));
      });

      test('fromJson은 모든 필드를 복원한다', () {
        final json = {
          'lastUsedFilterId': 'bw_soft',
          'favoriteFilterIds': ['bw_pure', 'bw_noir'],
          'defaultGrain': 15.0,
          'defaultVignette': 10.0,
          'hapticEnabled': true,
          'saveToGallery': true,
          'totalPhotosCaptured': 7,
        };
        final prefs = UserPreferences.fromJson(json);
        expect(prefs.lastUsedFilterId, equals('bw_soft'));
        expect(prefs.favoriteFilterIds, equals(['bw_pure', 'bw_noir']));
        expect(prefs.defaultGrain, equals(15.0));
        expect(prefs.defaultVignette, equals(10.0));
        expect(prefs.hapticEnabled, isTrue);
        expect(prefs.saveToGallery, isTrue);
        expect(prefs.totalPhotosCaptured, equals(7));
      });

      test('fromJson 누락된 필드는 기본값을 사용한다', () {
        final prefs = UserPreferences.fromJson({});
        expect(prefs.lastUsedFilterId, equals('bw_pure'));
        expect(prefs.favoriteFilterIds, isEmpty);
        expect(prefs.hapticEnabled, isTrue);
        expect(prefs.saveToGallery, isTrue);
        expect(prefs.totalPhotosCaptured, equals(0));
      });

      test('toJson → fromJson 왕복 변환은 동일한 상태를 유지한다', () {
        final original = UserPreferences(
          lastUsedFilterId: 'bw_film',
          favoriteFilterIds: ['bw_pure'],
          defaultGrain: 50.0,
          hapticEnabled: false,
          totalPhotosCaptured: 100,
        );
        final restored = UserPreferences.fromJson(original.toJson());
        expect(restored.lastUsedFilterId, equals(original.lastUsedFilterId));
        expect(restored.favoriteFilterIds, equals(original.favoriteFilterIds));
        expect(restored.defaultGrain, equals(original.defaultGrain));
        expect(restored.hapticEnabled, equals(original.hapticEnabled));
        expect(restored.totalPhotosCaptured, equals(original.totalPhotosCaptured));
      });
    });
  });
}
