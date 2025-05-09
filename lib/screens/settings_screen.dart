import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/services/supabase_service.dart';
import 'package:guerrero_barber_app/main.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:guerrero_barber_app/screens/theme_transition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadThemePreference();
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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'light';
    setState(() {
      _isDarkMode = theme == 'dark';
    });
    themeModeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleccionar imagen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                _ImageSourceOption(
                  icon: Icons.photo_library,
                  title: 'Galería',
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleImageSelection(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 15),
                _ImageSourceOption(
                  icon: Icons.camera_alt,
                  title: 'Cámara',
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleImageSelection(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (user == null) {
      _showSnackBar('Usuario no autenticado', isError: true);
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
          _showSnackBar('Foto actualizada correctamente');
        }
      } catch (e) {
        print('Error en la subida: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackBar('Error al subir la imagen: $e', isError: true);
        }
      }
    } catch (e) {
      print('Error en la selección: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error al seleccionar la imagen: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
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
          _showSnackBar('Perfil actualizado correctamente');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error al actualizar el perfil: $e', isError: true);
        }
      }

      setState(() => _isLoading = false);
    }
  }

  void _onThemeChanged(bool isDark) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThemeTransitionScreen(
          toDark: isDark,
          onFinish: () {
            Navigator.of(context).pop();
            setState(() {
              _isDarkMode = isDark;
            });
            themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
            forceThemeRebuild();
          },
        ),
      ),
    );
    await _saveThemePreference(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary,
                  colorScheme.surface,
                ],
                stops: const [0.3, 0.3],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(context),
                
                // Content
                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Actualizando...',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Actions FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'info',
            backgroundColor: colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InfoScreen()),
              );
            },
            child: const Icon(Icons.info_outline, color: Colors.white),
          ).animate().fadeIn(delay: 300.ms).slide(begin: const Offset(0, 20)),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'logout',
            backgroundColor: Colors.red,
            onPressed: () async {
              _showLogoutConfirmation();
            },
            child: const Icon(Icons.logout, color: Colors.white),
          ).animate().fadeIn(delay: 600.ms).slide(begin: const Offset(0, 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            'Perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: _isDarkMode,
            onChanged: _onThemeChanged,
            activeColor: Colors.amber,
            activeTrackColor: Colors.amber.withAlpha(50),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slide(begin: const Offset(0, -20));
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Profile picture
              _buildProfilePicture(isDark),
              const SizedBox(height: 30),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? colorScheme.onPrimary : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nombre de usuario',
                      icon: Icons.person,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Número de teléfono',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un número de teléfono';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    
                    // Save button
                    _buildSaveButton(),
                    const SizedBox(height: 80), // Space for FABs
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProfilePicture(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: colorScheme.primary.withAlpha(50),
                width: 4,
              ),
              image: _currentPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_currentPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _currentPhotoUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: isDark ? colorScheme.onPrimary.withAlpha(70) : colorScheme.primary.withAlpha(70),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: isDark ? colorScheme.onPrimary : colorScheme.onPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isDark = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? colorScheme.onPrimary.withAlpha(80) : colorScheme.primary.withAlpha(80)),
          prefixIcon: Icon(icon, color: isDark ? colorScheme.onPrimary : colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: isDark ? colorScheme.onPrimary.withAlpha(20) : colorScheme.primary.withAlpha(20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: colorScheme.onPrimary.withAlpha(5),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary.withAlpha(50),
        minimumSize: const Size(double.infinity, 55),
      ),
      child: const Text(
        'GUARDAR CAMBIOS',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ).animate().shimmer(delay: 1000.ms, duration: 1500.ms);
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                '¿Cerrar sesión?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Estás seguro que deseas cerrar tu sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primary.withAlpha(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}