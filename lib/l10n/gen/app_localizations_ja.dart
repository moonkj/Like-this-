// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get photoMode => '写真';

  @override
  String get videoMode => '動画';

  @override
  String get cameraInitError => 'カメラを初期化できません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get apply => '適用';

  @override
  String get select => '選択';

  @override
  String get settings => '設定';

  @override
  String get album => 'アルバム';

  @override
  String get camera => 'カメラ';

  @override
  String get filterTab => 'フィルター';

  @override
  String get effectsTab => 'エフェクト';

  @override
  String get cropTab => '切り抜き';

  @override
  String get none => 'なし';

  @override
  String get free => 'フリー';

  @override
  String get reset => 'リセット';

  @override
  String get resetCrop => '切り抜きリセット';

  @override
  String deleteConfirmTitle(int count) {
    return '$count枚を削除しますか？';
  }

  @override
  String get deleteWarning => '削除した写真は復元できません。';

  @override
  String get deletePhotoConfirm => 'この写真を削除しますか？';

  @override
  String deletedCount(int count) {
    return '$count枚を削除しました';
  }

  @override
  String get deleteFailedICloud => '削除に失敗しました。iCloudの写真は写真アプリで削除してください。';

  @override
  String filterApplied(int count) {
    return '$count件のフィルターを適用（元の写真は保持）';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total 処理中...';
  }

  @override
  String selectedCount(int count) {
    return '$count枚を選択中';
  }

  @override
  String get photoPermissionRequired => '写真へのアクセス許可が必要です';

  @override
  String get allowInSettings => '設定で許可する';

  @override
  String get noPhotos => '写真がありません';

  @override
  String get filterIntensity => 'フィルター強度';

  @override
  String get videoProcessError => '動画処理に失敗しました';

  @override
  String get nativeProcessError => '処理に失敗しました';

  @override
  String saveError(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get exposure => '露出';

  @override
  String get contrast => 'コントラスト';

  @override
  String get grain => 'グレイン';

  @override
  String get vignette => 'ビネット';

  @override
  String get lightLeak => '光漏れ';

  @override
  String get bloom => 'グロー';

  @override
  String get silentShutter => '無音シャッター';

  @override
  String get silentShutterDesc => 'シャッター音なしで撮影';

  @override
  String get cameraSection => 'カメラ';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get version => 'バージョン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get contact => 'お問い合わせ';

  @override
  String get appTagline => 'モノクロフィルムカメラ';
}
