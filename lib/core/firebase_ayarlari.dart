import 'package:firebase_core/firebase_core.dart';

/// Derleme sırasında `--dart-define` ile verilen Firebase Web ayarlarını okur.
/// Gizli değişkenler GitHub Actions Secrets içinde tutulur, depoya açık yazılmaz.
class FirebaseAyarlari {
  const FirebaseAyarlari._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');

  /// Tüm zorunlu Firebase parametreleri tanımlanmış mı?
  static bool get yapilandirildiMi =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      appId.isNotEmpty;

  static FirebaseOptions get webSecenekleri => const FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        messagingSenderId: messagingSenderId,
        appId: appId,
      );
}
