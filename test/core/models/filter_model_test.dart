// 🔴 RED → 🟢 GREEN → 🔵 REFACTOR
import 'package:flutter_test/flutter_test.dart';
import 'package:likethis/core/models/filter_model.dart';

void main() {
  group('FilterModel', () {
    test('모든 필터는 고유한 ID를 가진다', () {
      final ids = BWFilters.all.map((f) => f.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length));
    });

    test('BWFilters.all은 정확히 9종을 포함한다', () {
      expect(BWFilters.all.length, equals(9));
    });

    test('모든 필터의 LUT 파일명은 bw_로 시작한다', () {
      for (final filter in BWFilters.all) {
        expect(filter.lutFileName, startsWith('bw_'));
        expect(filter.lutFileName, endsWith('.cube'));
      }
    });

    test('defaultIntensity는 0.0~1.0 범위다', () {
      for (final filter in BWFilters.all) {
        expect(filter.defaultIntensity, greaterThanOrEqualTo(0.0));
        expect(filter.defaultIntensity, lessThanOrEqualTo(1.0));
      }
    });

    test('defaultGrain은 0~100 범위다', () {
      for (final filter in BWFilters.all) {
        expect(filter.defaultGrain, greaterThanOrEqualTo(0.0));
        expect(filter.defaultGrain, lessThanOrEqualTo(100.0));
      }
    });

    test('copyWith는 불변성을 유지한다', () {
      const original = BWFilters.pureThis;
      final copied = original.copyWith(isFavorite: true);
      expect(copied.id, equals(original.id));
      expect(copied.isFavorite, isTrue);
      expect(original.isFavorite, isFalse);
    });

    group('BWFilters.byId', () {
      test('유효한 ID로 필터를 찾는다', () {
        final filter = BWFilters.byId('bw_noir');
        expect(filter.id, equals('bw_noir'));
        expect(filter.name, equals('Deep Noir'));
      });

      test('존재하지 않는 ID는 pureThis를 반환한다', () {
        final filter = BWFilters.byId('bw_unknown');
        expect(filter.id, equals(BWFilters.pureThis.id));
      });
    });

    group('BWFilters.next', () {
      test('마지막 필터의 다음은 첫 번째 필터다 (순환)', () {
        final last = BWFilters.all.last;
        final next = BWFilters.next(last.id);
        expect(next.id, equals(BWFilters.all.first.id));
      });

      test('첫 번째 필터의 다음은 두 번째 필터다', () {
        final first = BWFilters.all.first;
        final next = BWFilters.next(first.id);
        expect(next.id, equals(BWFilters.all[1].id));
      });

      test('전체 필터 수만큼 순환하면 원래 필터로 돌아온다', () {
        var current = BWFilters.all.first;
        for (int i = 0; i < BWFilters.all.length; i++) {
          current = BWFilters.next(current.id);
        }
        expect(current.id, equals(BWFilters.all.first.id));
      });
    });

    group('FilterModel equality', () {
      test('같은 id를 가진 FilterModel은 동일하다', () {
        final a = BWFilters.pureThis;
        final b = BWFilters.pureThis.copyWith(isFavorite: true);
        expect(a, equals(b)); // id 기반 비교
      });

      test('다른 id를 가진 FilterModel은 다르다', () {
        expect(BWFilters.pureThis, isNot(equals(BWFilters.deepNoir)));
      });

      test('hashCode는 id 기반이다', () {
        final a = BWFilters.pureThis;
        final b = BWFilters.pureThis.copyWith(isFavorite: true);
        expect(a.hashCode, equals(b.hashCode));
        expect(a.hashCode, isNot(equals(BWFilters.deepNoir.hashCode)));
      });

      test('Set에 넣을 때 중복 제거된다', () {
        final set = {BWFilters.pureThis, BWFilters.pureThis.copyWith(isFavorite: true)};
        expect(set.length, equals(1));
      });
    });

    test('copyWith isFavorite 미전달 시 기존 값 유지', () {
      final favorited = BWFilters.pureThis.copyWith(isFavorite: true);
      final again = favorited.copyWith(defaultIntensity: 0.5);
      expect(again.isFavorite, isTrue); // isFavorite ?? this.isFavorite 경로
    });
  });

  group('BWEffectType', () {
    test('Film Dust 필터는 grain과 dust 이펙트를 포함한다', () {
      expect(BWFilters.filmDust.enabledEffects, contains(BWEffectType.grain));
      expect(BWFilters.filmDust.enabledEffects, contains(BWEffectType.dust));
    });

    test('Silver Glow 필터는 bloom 이펙트를 포함한다', () {
      expect(BWFilters.silverGlow.enabledEffects, contains(BWEffectType.bloom));
    });

    test('Pure This 필터는 특수 이펙트 없음', () {
      expect(BWFilters.pureThis.enabledEffects, isEmpty);
    });

    test('Pure This는 grain/vignette 기본값이 0이다', () {
      expect(BWFilters.pureThis.defaultGrain, equals(0.0));
      expect(BWFilters.pureThis.defaultVignette, equals(0.0));
    });
  });
}
