import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  static final LatLng _location = LatLng(37.1416537, -3.6218495); // C/Valladolid 68, Armilla

  Future<void> _launchInstagram() async {
    final url = Uri.parse('https://www.instagram.com/guerrero_barbershop__/?hl=es');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  Future<void> _callPhone() async {
    final phone = Uri.parse('tel:695261211');
    if (!await launchUrl(phone)) {
      throw Exception('No se pudo abrir $phone');
    }
  }

  Future<void> _openMap() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=37.1416537,-3.6218495');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más información', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Image.asset(
                'assets/instagram_logo.png',
                width: 32,
                height: 32,
              ),
              title: const Text('Instagram'),
              subtitle: const Text('@guerrero_barbershop__'),
              onTap: _launchInstagram,
              trailing: const Icon(Icons.open_in_new),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Teléfono'),
              subtitle: const Text('695261211'),
              onTap: _callPhone,
              trailing: const Icon(Icons.open_in_new),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Ubicación'),
              subtitle: const Text('C/Valladolid 68, 18100 Armilla, Granada'),
              onTap: _openMap,
              trailing: const Icon(Icons.map),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _location,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.guerrero_barber_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _location,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 