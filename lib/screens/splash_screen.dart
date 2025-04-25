import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/services/connectivity_service.dart';

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
  bool _isLoading = true;
  String? _error;
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupConnectivity();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.blue.shade900,
      end: Colors.blue.shade300,
    ).animate(_animationController);

    _colorAnimation2 = ColorTween(
      begin: Colors.black,
      end: Colors.blue,
    ).animate(_animationController);
  }

  void _setupConnectivity() {
    _connectivitySubscription = _connectivityService
        .onConnectivityChanged.listen((bool hasConnection) {
      if (mounted) {
        setState(() {
          if (hasConnection) {
            if (_error != null) {
              _error = null;
              _isLoading = true;
              _initializeApp();
            }
          } else {
            _error = 'No hay conexión a Internet';
            _isLoading = false;
          }
        });
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    try {
      final hasConnection = await _connectivityService.checkConnection();
      
      if (!mounted) return;

      if (!hasConnection) {
        setState(() {
          _error = 'No hay conexión a Internet';
          _isLoading = false;
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      await _checkAuthState();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      if (user == null) {
        _navigateToAuth();
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!mounted) return;

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        if (role == 'admin') {
          _navigateToAdmin();
        } else {
          _navigateToHome();
        }
      } else {
        _navigateToAuth();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToAdmin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminPanel()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
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
                  const Icon(
                    Icons.content_cut,
                    size: 100,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Guerrero Barber App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (_error != null)
                    Column(
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _isLoading = true;
                            });
                            _initializeApp();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
