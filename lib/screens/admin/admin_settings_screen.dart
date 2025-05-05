import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:guerrero_barber_app/screens/auth_screen.dart';
import 'package:guerrero_barber_app/services/supabase_service.dart';
import 'package:guerrero_barber_app/main.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (user != null) {
      final adminData = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user!.uid)
          .get();

      if (adminData.exists) {
        setState(() {
          _usernameController.text = adminData.data()?['username'] ?? '';
          _currentPhotoUrl = adminData.data()?['profileImageUrl'];
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 600,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      try {
        final File imageFile = File(image.path);

        final String? imageUrl = await SupabaseService.uploadProfileImage(
          user!.uid,
          imageFile,
        );

        if (imageUrl == null) {
          throw Exception('Error al obtener la URL de la imagen');
        }

        final adminDocRef = FirebaseFirestore.instance.collection('admins').doc(user!.uid);
        final adminDoc = await adminDocRef.get();

        final dataToUpdate = {
          'profileImageUrl': imageUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (adminDoc.exists) {
          await adminDocRef.update(dataToUpdate);
        } else {
          await adminDocRef.set(dataToUpdate, SetOptions(merge: true));
        }

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

  Future<void> _updateProfile(GlobalKey<FormState> formKey) async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final adminDocRef = FirebaseFirestore.instance.collection('admins').doc(user!.uid);
        final adminDoc = await adminDocRef.get();

        final dataToUpdate = {
          'username': _usernameController.text.trim(),
        };

        if (adminDoc.exists) {
          await adminDocRef.update(dataToUpdate);
        } else {
          await adminDocRef.set(dataToUpdate, SetOptions(merge: true));
        }

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
    final _formKey = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
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
                          backgroundColor: Colors.grey[300],
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
                              color: Colors.red,
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _updateProfile(_formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                heroTag: 'logout_admin',
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}