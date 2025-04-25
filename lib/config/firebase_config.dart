class FirebaseConfig {
  // La URL base para obtener el token de acceso OAuth2
  static const String oauth2TokenUrl = 'https://oauth2.googleapis.com/token';
  
  // El email de la cuenta de servicio
  static const String serviceAccountEmail = 'guerrerobarberapp@appspot.gserviceaccount.com';
  
  // La clave privada de la cuenta de servicio
  static const String privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDcBm5NPeWpoxOg
hY1vmwWjyzEsbQmaMvwqiPsALhr7X/5hq70U/aaWuTLkjMh0CVQAJ8b4kTPro1Wp
745qtoYijTS1hstWdJwnA83L+PTUPsGWfHKpXDRZ2vpGYwqYvy88LPSHuJY8mcRW
4Vj7XOoil9pkC9RRVoEy2B6ZYN5ISXR0GjEEXVizGXT9/Es053JRB/OPML/WMjhi
dnk0R8w8ZMtDrzouCPftjmpMWbTJAoVmL7mdSW2+iU73N+eAYsdt/fLekmVKU1wC
YuN8Sqm/C6RAP185drryYiaUsUM7pq1noRGVtT6BchaUI7Q3E+W7orm+OQ5zzBUq
zBrXmX8tAgMBAAECggEAAcVdeuquIAzregXJKyZMx9I5XZmtE5wocnEy0AAPAIn3
wrJ+rZ4TCrCH69YEQQbYMb4gOFz21YU1ic4fT9WTQ9DuJS3mEhaTMS8zJ1qkIdc1
eLAcvic7VqPQEuP2MF+NkkbsWvFN6EP2lBpxPGi1i7y8KcT8mwD+vjmGGYbxkxRc
cvB5J+hteyw9bj4D8ciibEsMwBDrTeWErgTFqxLAP3akE7kgEWbKiDgcUWtfcEcv
gbIClKSEdj/loz/3XekfXx1x4hJBNgz5ttCgUsm0OwRPcpaDQdHvzRba5pkzRb8u
NTRTETjlUwhzoMgkUb2xtWAud2w7MlUrE1jxwKTpUwKBgQDeUFpA5khiovIdKO88
crMZpjXFIk6sc0sT48+LSQ1JfbBMqORitofKwn23oudKSh7AkdyGhSI4MqTPEeHt
iGbTaGiT46jc2DyPLWuCgNNYthBHAAonl1RAhmZkycsQLYkBJ6uXBvzIXymL552T
7rnlIZbuwSUM0UYySHuFLNFlcwKBgQD9XUvnMmyc9db5cs1kRTMIYkfY9HHKMbrx
Rt1vkja3Dd09o6wgQAFUeSFsRxRVy/5SmN3dHuZeqwVQBY7xiRixLTmmEeXBkFSM
Yz0yMRROBBvlq/csT0urqv9m0eMbixsGkrAwxJuQIeghP68V58TLbTVdBATnZa6y
WHpFyn1g3wKBgE3S1yVs993/qL3ofIcup9/MvXn7Hotj+N5Hm3no4svdQgA0B28+
8p5aI2RLlKf+9nD3HrnAlVAS+nq6idp7K3PKUwGiapSU5e5BOid/LX0ajuwr6WIe
qZHE+sdBlOJe7l0HJBxEh+0k0wh01kbZBR5e+dUuq+emwuoLUaI3JD5dAoGBAIX/
otY69/CnoLO7QN+oLY5glEktN0VNueZDqXeJqAB2h61C9BT2ZP2tNr0SdrHNussq
aCS7Y/Frl9qzpd8et/10wsmPK6mM0PqSvdne1TNRvwNgSNCZe5bmUD+r/+YgUwHN
8PtJ8FBxblivWsVGF/HS52czafiL8bIHU1u39UmXAoGBAMCxt1SI6p1eP4EewFHu
vo5sObLhhaSrpkXsWjoNNMDZZMzcqV2qlM+WXcBhSpFl6rYBrOjD7keCjTOq8LnD
OXiCunQCySxZ1M7jrUGWQckFPlLEvTkIcpRSSyvgaJQhhyZx6UwxQ4/fLYNJ1Zj/
0o+yVw8pzpXqLIq3YOKc+sRP
-----END PRIVATE KEY-----''';
  
  // URL base para la API HTTP v1 de FCM
  static const String fcmBaseUrl = 'https://fcm.googleapis.com/v1/projects/guerrerobarberapp/messages:send';

  // El scope necesario para FCM
  static const String fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';
} 