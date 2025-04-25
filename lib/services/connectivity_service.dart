import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _hasConnection = false;

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get hasConnection => _hasConnection;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar la conectividad: $e');
      }
      _controller.add(false);
      _hasConnection = false;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (kDebugMode) {
      print('Estado de conectividad: $result');
    }
    
    _hasConnection = result != ConnectivityResult.none;
    
    if (kDebugMode) {
      print('¿Tiene conexión? $_hasConnection');
    }
    
    _controller.add(_hasConnection);
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar la conectividad: $e');
      }
      _controller.add(false);
      _hasConnection = false;
      return false;
    }
  }

  void dispose() {
    _controller.close();
  }
} 