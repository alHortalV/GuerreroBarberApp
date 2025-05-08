import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/screens/screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _requesting = false;
  String? _error;

  Future<void> _requestPermissions() async {
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (notificationStatus.isGranted && alarmStatus.isGranted) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          }
          return;
        } else {
          setState(() {
            _error = 'Debes aceptar ambos permisos para continuar.';
          });
        }
      } else {
        // En iOS o web, simplemente avanza
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error al solicitar permisos: $e';
      });
    } finally {
      setState(() {
        _requesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active, size: 80, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(height: 24),
              const Text(
                'Permisos requeridos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Necesitamos tu permiso para enviarte notificaciones de citas y recordatorios importantes. También requerimos permiso para alarmas para poder avisarte incluso si la app está cerrada.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: _requesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Aceptar y continuar'),
                onPressed: _requesting ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 