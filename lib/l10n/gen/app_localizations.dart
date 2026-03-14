import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @photoMode.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photoMode;

  /// No description provided for @videoMode.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get videoMode;

  /// No description provided for @cameraInitError.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 초기화할 수 없습니다.'**
  String get cameraInitError;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @apply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get apply;

  /// No description provided for @select.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get select;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @album.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get album;

  /// No description provided for @camera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get camera;

  /// No description provided for @filterTab.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get filterTab;

  /// No description provided for @effectsTab.
  ///
  /// In ko, this message translates to:
  /// **'효과'**
  String get effectsTab;

  /// No description provided for @cropTab.
  ///
  /// In ko, this message translates to:
  /// **'자르기'**
  String get cropTab;

  /// No description provided for @none.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get none;

  /// No description provided for @free.
  ///
  /// In ko, this message translates to:
  /// **'자유'**
  String get free;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'reset'**
  String get reset;

  /// No description provided for @resetCrop.
  ///
  /// In ko, this message translates to:
  /// **'크롭 초기화'**
  String get resetCrop;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{count}장을 삭제하시겠습니까?'**
  String deleteConfirmTitle(int count);

  /// No description provided for @deleteWarning.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 사진은 복구할 수 없습니다.'**
  String get deleteWarning;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In ko, this message translates to:
  /// **'사진을 삭제하시겠습니까?'**
  String get deletePhotoConfirm;

  /// No description provided for @deletedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장 삭제됨'**
  String deletedCount(int count);

  /// No description provided for @deleteFailedICloud.
  ///
  /// In ko, this message translates to:
  /// **'삭제에 실패했습니다. iCloud 사진은 사진 앱에서 삭제해주세요.'**
  String get deleteFailedICloud;

  /// No description provided for @filterApplied.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 필터 적용 완료 (원본 유지)'**
  String filterApplied(int count);

  /// No description provided for @processingProgress.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total} 처리 중...'**
  String processingProgress(int current, int total);

  /// No description provided for @selectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장 선택됨'**
  String selectedCount(int count);

  /// No description provided for @photoPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'사진 접근 권한이 필요합니다'**
  String get photoPermissionRequired;

  /// No description provided for @allowInSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 허용'**
  String get allowInSettings;

  /// No description provided for @noPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진이 없습니다'**
  String get noPhotos;

  /// No description provided for @filterIntensity.
  ///
  /// In ko, this message translates to:
  /// **'필터 강도'**
  String get filterIntensity;

  /// No description provided for @videoProcessError.
  ///
  /// In ko, this message translates to:
  /// **'영상 처리 실패'**
  String get videoProcessError;

  /// No description provided for @nativeProcessError.
  ///
  /// In ko, this message translates to:
  /// **'네이티브 처리 실패'**
  String get nativeProcessError;

  /// No description provided for @saveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String saveError(String error);

  /// No description provided for @exposure.
  ///
  /// In ko, this message translates to:
  /// **'노출'**
  String get exposure;

  /// No description provided for @contrast.
  ///
  /// In ko, this message translates to:
  /// **'대비'**
  String get contrast;

  /// No description provided for @grain.
  ///
  /// In ko, this message translates to:
  /// **'그레인'**
  String get grain;

  /// No description provided for @vignette.
  ///
  /// In ko, this message translates to:
  /// **'비네팅'**
  String get vignette;

  /// No description provided for @lightLeak.
  ///
  /// In ko, this message translates to:
  /// **'빛번짐'**
  String get lightLeak;

  /// No description provided for @bloom.
  ///
  /// In ko, this message translates to:
  /// **'글로우'**
  String get bloom;

  /// No description provided for @silentShutter.
  ///
  /// In ko, this message translates to:
  /// **'무음 셔터'**
  String get silentShutter;

  /// No description provided for @silentShutterDesc.
  ///
  /// In ko, this message translates to:
  /// **'촬영음 없이 사진 찍기'**
  String get silentShutterDesc;

  /// No description provided for @cameraSection.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get cameraSection;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// No description provided for @contact.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get contact;

  /// No description provided for @appTagline.
  ///
  /// In ko, this message translates to:
  /// **'Black & White Camera'**
  String get appTagline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'fr',
    'hi',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
