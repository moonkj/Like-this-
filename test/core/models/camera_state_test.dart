// 🔴 RED → 🟢 GREEN → 🔵 REFACTOR
import 'package:flutter_test/flutter_test.dart';
import 'package:likethis/core/models/camera_state.dart';

void main() {
  group('CameraState', () {
    test('초기 상태는 uninitialized다', () {
      const state = CameraState();
      expect(state.status, equals(CameraStatus.uninitialized));
    });

    test('초기 노출값은 0이다', () {
      const state = CameraState();
      expect(state.exposure, equals(0.0));
    });

    test('초기 대비값은 0이다', () {
      const state = CameraState();
      expect(state.contrast, equals(0.0));
    });

    test('초기 렌즈는 back이다', () {
      const state = CameraState();
      expect(state.lens, equals(CameraLens.back));
    });

    test('초기 필터는 Pure This다', () {
      const state = CameraState();
      expect(state.activeFilter.id, equals('bw_pure'));
    });

    test('초기 isNoneFilter는 false다', () {
      const state = CameraState();
      expect(state.isNoneFilter, isFalse);
    });

    test('isNoneFilter를 true로 설정하면 유지된다', () {
      const state = CameraState(isNoneFilter: true);
      expect(state.isNoneFilter, isTrue);
      // copyWith 시 다른 필드 변경해도 isNoneFilter 유지
      final updated = state.copyWith(exposure: 10.0);
      expect(updated.isNoneFilter, isTrue);
    });

    test('isNoneFilter copyWith으로 false로 변경 가능', () {
      const state = CameraState(isNoneFilter: true);
      final updated = state.copyWith(isNoneFilter: false);
      expect(updated.isNoneFilter, isFalse);
    });

    group('copyWith', () {
      test('status만 변경된다', () {
        const state = CameraState();
        final updated = state.copyWith(status: CameraStatus.ready);
        expect(updated.status, equals(CameraStatus.ready));
        expect(updated.exposure, equals(state.exposure));
        expect(updated.lens, equals(state.lens));
      });

      test('exposure 범위 확인 (Provider에서 clamp됨)', () {
        const state = CameraState();
        final updated = state.copyWith(exposure: 50.0);
        expect(updated.exposure, equals(50.0));
      });
    });

    group('computed properties', () {
      test('isReady는 ready 상태에서만 true', () {
        expect(const CameraState(status: CameraStatus.ready).isReady, isTrue);
        expect(const CameraState(status: CameraStatus.error).isReady, isFalse);
        expect(const CameraState().isReady, isFalse);
      });

      test('isRecording은 recording 상태에서만 true', () {
        expect(
          const CameraState(status: CameraStatus.recording).isRecording,
          isTrue,
        );
        expect(const CameraState().isRecording, isFalse);
      });

      test('isFront은 front 렌즈에서만 true', () {
        expect(
          const CameraState(lens: CameraLens.front).isFront,
          isTrue,
        );
        expect(
          const CameraState(lens: CameraLens.back).isFront,
          isFalse,
        );
      });
    });
  });
}
