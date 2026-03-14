// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get photoMode => '照片';

  @override
  String get videoMode => '视频';

  @override
  String get cameraInitError => '无法初始化相机。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get apply => '应用';

  @override
  String get select => '选择';

  @override
  String get settings => '设置';

  @override
  String get album => '相册';

  @override
  String get camera => '相机';

  @override
  String get filterTab => '滤镜';

  @override
  String get effectsTab => '效果';

  @override
  String get cropTab => '裁剪';

  @override
  String get none => '无';

  @override
  String get free => '自由';

  @override
  String get reset => '重置';

  @override
  String get resetCrop => '重置裁剪';

  @override
  String deleteConfirmTitle(int count) {
    return '删除$count张照片？';
  }

  @override
  String get deleteWarning => '已删除的照片无法恢复。';

  @override
  String get deletePhotoConfirm => '删除此照片？';

  @override
  String deletedCount(int count) {
    return '已删除$count张';
  }

  @override
  String get deleteFailedICloud => '删除失败。iCloud照片请在照片应用中删除。';

  @override
  String filterApplied(int count) {
    return '$count个滤镜已应用（保留原件）';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total 处理中...';
  }

  @override
  String selectedCount(int count) {
    return '已选$count张';
  }

  @override
  String get photoPermissionRequired => '需要照片库访问权限';

  @override
  String get allowInSettings => '在设置中允许';

  @override
  String get noPhotos => '没有照片';

  @override
  String get filterIntensity => '滤镜强度';

  @override
  String get videoProcessError => '视频处理失败';

  @override
  String get nativeProcessError => '处理失败';

  @override
  String saveError(String error) {
    return '保存失败：$error';
  }

  @override
  String get exposure => '曝光';

  @override
  String get contrast => '对比度';

  @override
  String get grain => '颗粒';

  @override
  String get vignette => '暗角';

  @override
  String get lightLeak => '漏光';

  @override
  String get bloom => '发光';

  @override
  String get silentShutter => '静音快门';

  @override
  String get silentShutterDesc => '拍照时不发出快门声';

  @override
  String get cameraSection => '相机';

  @override
  String get appInfo => '应用信息';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get contact => '联系我们';

  @override
  String get appTagline => '黑白胶片相机';
}
