import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    // Configuramos el animation controller para animar el fondo
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Animar entre dos colores para un gradiente dinámico
    _colorAnimation1 = ColorTween(
      begin: Colors.blue.shade900, // azul marino
      end: Colors.blue.shade300, // azul claro
    ).animate(_animationController);

    _colorAnimation2 = ColorTween(
      begin: Colors.black,
      end: Colors.blue, // azul para contraste
    ).animate(_animationController);

    // Verificar si hay una sesión activa después de unos segundos
    Timer(const Duration(seconds: 3), () {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // El usuario está autenticado, verificar si es admin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        if (mounted) {
          if (role == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminPanel()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    } else {
      // No hay sesión activa, ir a la pantalla de autenticación
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_colorAnimation1.value!, _colorAnimation2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono alusivo a la barbería
                  const Icon(
                    Icons.content_cut,
                    size: 100,
                    color: Colors.red, // acento típico de peluquería
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Guerrero Barber App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
