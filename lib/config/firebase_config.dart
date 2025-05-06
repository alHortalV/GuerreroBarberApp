import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  final String oauth2TokenUrl;
  final String serviceAccountEmail;
  final String privateKey;
  final String fcmBaseUrl;
  final String fcmScope;

  const FirebaseConfig({
    required this.oauth2TokenUrl,
    required this.serviceAccountEmail,
    required this.privateKey,
    required this.fcmBaseUrl,
    required this.fcmScope,
  });

  static FirebaseConfig fromEnv() {
    return FirebaseConfig(
      oauth2TokenUrl:  dotenv.env['OAUTH2_TOKEN_URL'] ?? '',
      serviceAccountEmail: dotenv.env['SERVICE_ACCOUNT_EMAIL'] ?? '',
      privateKey: (dotenv.env['PRIVATE_KEY'] ?? ''),
      fcmBaseUrl: dotenv.env['FCM_BASE_URL'] ?? '',
      fcmScope: dotenv.env['FCM_SCOPE'] ?? '',
    );
  }
}
