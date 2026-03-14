// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get photoMode => '사진';

  @override
  String get videoMode => '동영상';

  @override
  String get cameraInitError => '카메라를 초기화할 수 없습니다.';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get apply => '적용';

  @override
  String get select => '선택';

  @override
  String get settings => '설정';

  @override
  String get album => '앨범';

  @override
  String get camera => '카메라';

  @override
  String get filterTab => '필터';

  @override
  String get effectsTab => '효과';

  @override
  String get cropTab => '자르기';

  @override
  String get none => '없음';

  @override
  String get free => '자유';

  @override
  String get reset => 'reset';

  @override
  String get resetCrop => '크롭 초기화';

  @override
  String deleteConfirmTitle(int count) {
    return '$count장을 삭제하시겠습니까?';
  }

  @override
  String get deleteWarning => '삭제된 사진은 복구할 수 없습니다.';

  @override
  String get deletePhotoConfirm => '사진을 삭제하시겠습니까?';

  @override
  String deletedCount(int count) {
    return '$count장 삭제됨';
  }

  @override
  String get deleteFailedICloud => '삭제에 실패했습니다. iCloud 사진은 사진 앱에서 삭제해주세요.';

  @override
  String filterApplied(int count) {
    return '$count개 필터 적용 완료 (원본 유지)';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total 처리 중...';
  }

  @override
  String selectedCount(int count) {
    return '$count장 선택됨';
  }

  @override
  String get photoPermissionRequired => '사진 접근 권한이 필요합니다';

  @override
  String get allowInSettings => '설정에서 허용';

  @override
  String get noPhotos => '사진이 없습니다';

  @override
  String get filterIntensity => '필터 강도';

  @override
  String get videoProcessError => '영상 처리 실패';

  @override
  String get nativeProcessError => '네이티브 처리 실패';

  @override
  String saveError(String error) {
    return '저장 실패: $error';
  }

  @override
  String get exposure => '노출';

  @override
  String get contrast => '대비';

  @override
  String get grain => '그레인';

  @override
  String get vignette => '비네팅';

  @override
  String get lightLeak => '빛번짐';

  @override
  String get bloom => '글로우';

  @override
  String get silentShutter => '무음 셔터';

  @override
  String get silentShutterDesc => '촬영음 없이 사진 찍기';

  @override
  String get cameraSection => '카메라';

  @override
  String get appInfo => '앱 정보';

  @override
  String get version => '버전';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get termsOfService => '이용약관';

  @override
  String get contact => '문의하기';

  @override
  String get appTagline => 'Black & White Camera';
}
