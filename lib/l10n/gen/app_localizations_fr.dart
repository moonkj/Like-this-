// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get photoMode => 'Photo';

  @override
  String get videoMode => 'Vidéo';

  @override
  String get cameraInitError => 'Impossible d\'initialiser la caméra.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get apply => 'Appliquer';

  @override
  String get select => 'Sélectionner';

  @override
  String get settings => 'Paramètres';

  @override
  String get album => 'Album';

  @override
  String get camera => 'Caméra';

  @override
  String get filterTab => 'Filtre';

  @override
  String get effectsTab => 'Effets';

  @override
  String get cropTab => 'Recadrer';

  @override
  String get none => 'Aucun';

  @override
  String get free => 'Libre';

  @override
  String get reset => 'reset';

  @override
  String get resetCrop => 'Réinitialiser le recadrage';

  @override
  String deleteConfirmTitle(int count) {
    return 'Supprimer $count photo(s) ?';
  }

  @override
  String get deleteWarning =>
      'Les photos supprimées ne peuvent pas être récupérées.';

  @override
  String get deletePhotoConfirm => 'Supprimer cette photo ?';

  @override
  String deletedCount(int count) {
    return '$count supprimé(s)';
  }

  @override
  String get deleteFailedICloud =>
      'Échec de la suppression. Les photos iCloud doivent être supprimées dans l\'app Photos.';

  @override
  String filterApplied(int count) {
    return '$count filtre(s) appliqué(s) (originaux conservés)';
  }

  @override
  String processingProgress(int current, int total) {
    return '$current / $total en cours...';
  }

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get photoPermissionRequired => 'Accès à la photothèque requis';

  @override
  String get allowInSettings => 'Autoriser dans Réglages';

  @override
  String get noPhotos => 'Aucune photo';

  @override
  String get filterIntensity => 'Intensité du filtre';

  @override
  String get videoProcessError => 'Échec du traitement vidéo';

  @override
  String get nativeProcessError => 'Échec du traitement';

  @override
  String saveError(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get exposure => 'Exposition';

  @override
  String get contrast => 'Contraste';

  @override
  String get grain => 'Grain';

  @override
  String get vignette => 'Vignette';

  @override
  String get lightLeak => 'Fuite lumineuse';

  @override
  String get bloom => 'Lueur';

  @override
  String get silentShutter => 'Obturateur silencieux';

  @override
  String get silentShutterDesc => 'Prendre des photos sans son';

  @override
  String get cameraSection => 'Caméra';

  @override
  String get appInfo => 'Infos sur l\'app';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get contact => 'Contact';

  @override
  String get appTagline => 'Appareil photo noir et blanc';
}
