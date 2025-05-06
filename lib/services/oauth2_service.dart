import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guerrero_barber_app/config/firebase_config.dart';
import 'package:jose/jose.dart';

class OAuth2Service {
  static String? _cachedAccessToken;
  static DateTime? _tokenExpiryTime;

  static Future<String> getAccessToken() async {
    // Verificar si tenemos un token válido en caché
    if (_cachedAccessToken != null && _tokenExpiryTime != null) {
      if (_tokenExpiryTime!.isAfter(DateTime.now())) {
        return _cachedAccessToken!;
      }
    }

    // Si no hay token válido, generamos uno nuevo
    final jwt = await _createJWT();
    
    final response = await http.post(
      Uri.parse(FirebaseConfig.fromEnv().oauth2TokenUrl),
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _cachedAccessToken = data['access_token'];
      _tokenExpiryTime = DateTime.now().add(Duration(seconds: data['expires_in']));
      return _cachedAccessToken!;
    } else {
      throw Exception('Error al obtener el token de acceso: ${response.body}');
    }
  }

  static Future<String> _createJWT() async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(hours: 1));

    final claims = {
      'iss': FirebaseConfig.fromEnv().serviceAccountEmail,
      'scope': FirebaseConfig.fromEnv().fcmScope,
      'aud': FirebaseConfig.fromEnv().oauth2TokenUrl,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
    };

    final key = JsonWebKey.fromPem(FirebaseConfig.fromEnv().privateKey);
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims
      ..addRecipient(key, algorithm: 'RS256');

    return builder.build().toCompactSerialization();
  }
} 