import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:guerrero_barber_app/screens/auth_screen.dart';
import 'package:guerrero_barber_app/services/supabase_service.dart';
import 'package:guerrero_barber_app/main.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:guerrero_barber_app/screens/theme_transition_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Determinar el tema actual
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
                  color: Colors.black.withAlpha(70),
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
                    color: Theme.of(context).colorScheme.primary,
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
          _showSnackBar('Foto actualizada correctamente');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackBar('Error al subir la imagen: $e', isError: true);
        }
      }
    } catch (e) {
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
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa un nombre de usuario', isError: true);
      return;
    }
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
        _showSnackBar('Perfil actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar el perfil: $e', isError: true);
      }
    }
    setState(() => _isLoading = false);
  }

  void _confirmSignOut() {
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
                color: Colors.black.withAlpha(70),
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

  void _onThemeChanged(ThemeMode mode) async {
    final isDark = mode == ThemeMode.dark;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThemeTransitionScreen(
          toDark: isDark,
          onFinish: () {
            Navigator.of(context).pop();
            setState(() {
            });
            themeModeNotifier.value = mode;
            forceThemeRebuild();
          },
        ),
      ),
    );
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
              color: Colors.black.withAlpha(140),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                color: Colors.white.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            'Panel de Administrador',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
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
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              _buildProfileSection(isDark),
              const SizedBox(height: 32),
              
              // Theme section
              _buildThemeSection(),
              const SizedBox(height: 32),
              
              // Username section
              Text(
                'Información de Administrador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de administrador',
                icon: Icons.admin_panel_settings,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un nombre de administrador';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Save button
              _buildSaveButton(),
              const SizedBox(height: 24),
              
              // Logout button
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProfileSection(bool isDark) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha(127),
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
                          color: isDark ? Theme.of(context).colorScheme.onPrimary.withAlpha(178) : Theme.of(context).colorScheme.primary.withAlpha(178),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withAlpha(127),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: isDark ? Theme.of(context).colorScheme.onPrimary : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            _usernameController.text.isNotEmpty
                ? _usernameController.text
                : 'Administrador',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
            ),
          ).animate().fadeIn(delay: 900.ms),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema de la Aplicación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? colorScheme.onPrimary : colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Opción Claro
              _ThemePill(
                icon: Icons.light_mode,
                label: 'Claro',
                selected: themeModeNotifier.value == ThemeMode.light,
                onTap: () => _onThemeChanged(ThemeMode.light),
                isDark: isDark,
              ).animate().fadeIn(delay: 1100.ms).slide(begin: const Offset(-20, 0)),
              const SizedBox(width: 12),
              // Opción Oscuro
              _ThemePill(
                icon: Icons.dark_mode,
                label: 'Oscuro',
                selected: themeModeNotifier.value == ThemeMode.dark,
                onTap: () => _onThemeChanged(ThemeMode.dark),
                isDark: isDark,
              ).animate().fadeIn(delay: 1200.ms).slide(begin: const Offset(-20, 0)),
            ],
          ),
        ),
      ],
    );
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
            color: Colors.black.withAlpha(13),
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
          labelStyle: TextStyle(color: isDark ? colorScheme.onPrimary.withAlpha(204) : colorScheme.primary.withAlpha(204)),
          prefixIcon: Icon(icon, color: isDark ? colorScheme.onPrimary : colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: isDark ? colorScheme.onPrimary.withAlpha(51) : colorScheme.primary.withAlpha(51)),
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
          fillColor: colorScheme.onPrimary.withAlpha(13),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    ).animate().fadeIn(delay: 1300.ms);
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _updateProfile,
      icon: const Icon(Icons.save, color: Colors.white),
      label: const Text(
        'GUARDAR CAMBIOS',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary.withAlpha(127),
        minimumSize: const Size(double.infinity, 55),
      ),
    ).animate().shimmer(delay: 1500.ms, duration: 1500.ms);
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _confirmSignOut,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text(
        'CERRAR SESIÓN',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.red,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: const Size(double.infinity, 55),
      ),
    ).animate().fadeIn(delay: 1600.ms);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class _ThemePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? (selected ? colorScheme.onPrimary : Colors.transparent)
                : (selected ? colorScheme.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark
                  ? (selected ? colorScheme.onPrimary : colorScheme.onPrimary.withOpacity(0.5))
                  : (selected ? colorScheme.primary : colorScheme.outline),
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: isDark
                          ? colorScheme.onPrimary.withOpacity(0.15)
                          : colorScheme.primary.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark
                    ? (selected ? colorScheme.primary : colorScheme.onPrimary.withOpacity(0.7))
                    : (selected ? Colors.white : colorScheme.primary),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? (selected ? colorScheme.primary : colorScheme.onPrimary.withOpacity(0.7))
                      : (selected ? Colors.white : colorScheme.onSurface),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
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