import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guerrero_barber_app/screens/AuthScreen.dart';
import 'package:guerrero_barber_app/screens/admin/AdminPanel.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userRole = 'cliente';

  @override
  void initState() {
    super.initState();
    // Simulación: aquí podrías consultar Firestore para obtener datos del usuario
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guerrero Barber App'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sesión cerrada')),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AuthScreen()),
                );
              }
            },
          )
        ],
      ),
      body: userRole == 'administrador'
          ? AdminPanel()
          : Center(
              child: Text(
                  'Bienvenido, Cliente. Aquí iría tu calendario de citas.'),
            ),
    );
  }
}
