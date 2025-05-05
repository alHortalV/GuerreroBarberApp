import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/services/supabase_service.dart';
import 'package:guerrero_barber_app/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      if (userData.exists) {
        setState(() {
          _usernameController.text = userData.data()?['username'] ?? '';
          _phoneController.text = userData.data()?['phone'] ?? '';
          _currentPhotoUrl = userData.data()?['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleImageSelection(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleImageSelection(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    try {
      // Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 600,
      );
      
      if (image == null) return;

      setState(() => _isLoading = true);

      try {
        // Convertir XFile a File
        final File imageFile = File(image.path);

        // Subir imagen a Supabase
        final String? imageUrl = await SupabaseService.uploadProfileImage(
          user!.uid,
          imageFile,
        );

        if (imageUrl == null) {
          throw Exception('Error al obtener la URL de la imagen');
        }

        // Actualizar Firestore con la nueva URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'profileImageUrl': imageUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Actualizar UI
        setState(() {
          _currentPhotoUrl = imageUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error en la subida: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir la imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en la selección: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el perfil: $e')),
          );
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dropdown para cambiar el tema
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Tema:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      DropdownButton<ThemeMode>(
                        value: themeModeNotifier.value,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Sistema'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Claro'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Oscuro'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) themeModeNotifier.value = mode;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Foto de perfil
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          backgroundImage: _currentPhotoUrl != null
                              ? NetworkImage(_currentPhotoUrl!)
                              : null,
                          child: _currentPhotoUrl == null
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un nombre de usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un número de teléfono';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // FAB de cerrar sesión
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'logout_user',
                backgroundColor: Colors.red,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  }
                },
                child: const Icon(Icons.logout, color: Colors.white),
              ),
            ),
            // FAB de más información
            Positioned(
              bottom: 24,
              left: 24,
              child: FloatingActionButton(
                heroTag: 'info_user',
                backgroundColor: Colors.blue,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  );
                },
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 