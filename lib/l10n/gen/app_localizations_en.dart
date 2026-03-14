// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get photoMode => 'Photo';

  @override
  String get videoMode => 'Video';

  @override
  String get cameraInitError => 'Unable to initialize camera.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get apply => 'Apply';

  @override
  String get select => 'Select';

  @override
  String get settings => 'Settings';

  @override
  String get album => 'Album';

  @override
  String get camera => 'Camera';

  @override
  String get filterTab => 'Filter';

  @override
  String get effectsTab => 'Effects';

  @override
  String get cropTab => 'Crop';

  @override
  String get none => 'None';

  @override
  String get free => 'Free';

  @override
  String get reset => 'reset';

  @override
  String get resetCrop => 'Reset Crop';

  @override
  String deleteConfirmTitle(int count) {
    return 'Delete $count photo(s)?';
  }

  @override
  String get deleteWarning => 'Deleted photos cannot be recovered.';

  @override
  String get deletePhotoConfirm => 'Delete this photo?';

  @override
  String deletedCount(int count) {
    return '$count deleted';
  }

  @override
  String get deleteFailedICloud =>
      'Delete failed. iCloud photos can be deleted in the Photos app.';

  @override
  String filterApplied(int count) {
    return '$count filter(s) applied (originals preserved)';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total processing...';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get photoPermissionRequired => 'Photo library access required';

  @override
  String get allowInSettings => 'Allow in Settings';

  @override
  String get noPhotos => 'No photos';

  @override
  String get filterIntensity => 'Filter Intensity';

  @override
  String get videoProcessError => 'Video processing failed';

  @override
  String get nativeProcessError => 'Processing failed';

  @override
  String saveError(String error) {
    return 'Save failed: $error';
  }

  @override
  String get exposure => 'Exposure';

  @override
  String get contrast => 'Contrast';

  @override
  String get grain => 'Grain';

  @override
  String get vignette => 'Vignette';

  @override
  String get lightLeak => 'Light Leak';

  @override
  String get bloom => 'Glow';

  @override
  String get silentShutter => 'Silent Shutter';

  @override
  String get silentShutterDesc => 'Take photos without shutter sound';

  @override
  String get cameraSection => 'Camera';

  @override
  String get appInfo => 'App Info';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get contact => 'Contact';

  @override
  String get appTagline => 'Black & White Camera';
}
