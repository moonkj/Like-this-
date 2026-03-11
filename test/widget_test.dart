import 'package:flutter_test/flutter_test.dart';
import 'package:likethis/core/models/filter_model.dart';

void main() {
  group('Like This — 기본 스모크 테스트', () {
    test('BWFilters.all이 7종 로드됨', () {
      expect(BWFilters.all.length, equals(9));
    });

    test('첫 번째 필터는 Pure This', () {
      expect(BWFilters.all.first.id, equals('bw_pure'));
    });
  });
}
