// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get photoMode => 'फ़ोटो';

  @override
  String get videoMode => 'वीडियो';

  @override
  String get cameraInitError => 'कैमरा प्रारंभ नहीं हो सका।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get apply => 'लागू करें';

  @override
  String get select => 'चुनें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get album => 'एल्बम';

  @override
  String get camera => 'कैमरा';

  @override
  String get filterTab => 'फ़िल्टर';

  @override
  String get effectsTab => 'प्रभाव';

  @override
  String get cropTab => 'क्रॉप';

  @override
  String get none => 'कोई नहीं';

  @override
  String get free => 'मुक्त';

  @override
  String get reset => 'रीसेट';

  @override
  String get resetCrop => 'क्रॉप रीसेट';

  @override
  String deleteConfirmTitle(int count) {
    return '$count फ़ोटो हटाएं?';
  }

  @override
  String get deleteWarning => 'हटाई गई फ़ोटो पुनर्प्राप्त नहीं की जा सकती।';

  @override
  String get deletePhotoConfirm => 'यह फ़ोटो हटाएं?';

  @override
  String deletedCount(int count) {
    return '$count हटाई गई';
  }

  @override
  String get deleteFailedICloud =>
      'हटाने में विफल। iCloud फ़ोटो Photos ऐप में हटाएं।';

  @override
  String filterApplied(int count) {
    return '$count फ़िल्टर लागू (मूल सुरक्षित)';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total प्रोसेस हो रहा है...';
  }

  @override
  String selectedCount(int count) {
    return '$count चुनी गईं';
  }

  @override
  String get photoPermissionRequired => 'फ़ोटो लाइब्रेरी की अनुमति आवश्यक है';

  @override
  String get allowInSettings => 'सेटिंग्स में अनुमति दें';

  @override
  String get noPhotos => 'कोई फ़ोटो नहीं';

  @override
  String get filterIntensity => 'फ़िल्टर तीव्रता';

  @override
  String get videoProcessError => 'वीडियो प्रोसेसिंग विफल';

  @override
  String get nativeProcessError => 'प्रोसेसिंग विफल';

  @override
  String saveError(String error) {
    return 'सहेजना विफल: $error';
  }

  @override
  String get exposure => 'एक्सपोज़र';

  @override
  String get contrast => 'कंट्रास्ट';

  @override
  String get grain => 'ग्रेन';

  @override
  String get vignette => 'विगनेट';

  @override
  String get lightLeak => 'लाइट लीक';

  @override
  String get bloom => 'ग्लो';

  @override
  String get silentShutter => 'साइलेंट शटर';

  @override
  String get silentShutterDesc => 'बिना शटर ध्वनि के फ़ोटो लें';

  @override
  String get cameraSection => 'कैमरा';

  @override
  String get appInfo => 'ऐप जानकारी';

  @override
  String get version => 'संस्करण';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get contact => 'संपर्क करें';

  @override
  String get appTagline => 'ब्लैक एंड व्हाइट कैमरा';
}
