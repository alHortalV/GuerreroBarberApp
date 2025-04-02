import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/HomeScreen.dart';
import 'package:dynamic_background/dynamic_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialIsLogin = true});

  final bool initialIsLogin;

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  late bool isLogin;
  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    Tween<Offset>(
      // Initialize _titleSlideAnimation
      begin: Offset.zero,
      end: const Offset(1.0, 0.0), // Initial end, will be adjusted in build
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _validateRegisterPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');
    if (!regex.hasMatch(value)) {
      return 'La contraseña debe tener al menos 8 caracteres, una mayúscula, un número y un signo especial';
    }
    return null;
  }

  String? _validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  void _submit() async {
    // Primero se guardan los valores de los campos
    _formKey.currentState?.save();

    // Validar email
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido')),
      );
      return;
    }

    final atIndex = email.indexOf('@');
    final dotIndex = email.lastIndexOf('.');

    if (atIndex < 1 || // No hay contenido antes de "@"
            atIndex == email.length - 1 || // No hay contenido después de "@"
            dotIndex <= atIndex + 1 || // No hay contenido entre "@" y "."
            dotIndex == email.length - 1 // No hay contenido después de "."
        ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido')),
      );
      return;
    }

    // Validar username para el registro
    if (!isLogin && username.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre de usuario')),
      );
      return;
    }
    // Validar contraseña para registro
    if (!isLogin) {
      final passError = _validateRegisterPassword(password);
      if (passError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passError)),
        );
        return;
      }
      // Validar confirmar contraseña para el registro
      final confirmPassError = _validateConfirmPassword(confirmPassword);
      if (confirmPassError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(confirmPassError)),
        );
        return;
      }
    } else {
      // Validar contraseña para inicio de sesión
      final passError = _validateLoginPassword(password);
      if (passError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passError)),
        );
        return;
      }
    }

    try {
      UserCredential userCredential;
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          username = data['username'] ?? '';
        }
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': username,
          'email': email,
        });
      }
      if (userCredential.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogin
                  ? 'Bienvenido de nuevo $username'
                  : 'Registro exitoso'),
            ),
          );
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este correo ya está registrado')),
          );
        } else if (e.code == 'wrong-password' || e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La contraseña es incorrecta')),
          );
        } else if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('El correo o la contraseña son incorrectos')),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _toggleAuthMode() {
    if (isLogin) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicBg(
        duration: const Duration(
            seconds:
                45), // Puedes ajustar la duración para cambiar la velocidad
        painterData: ScrollerPainterData(
          direction: ScrollDirection.bottom2Top,
          shape: ScrollerShape.stripesDiagonalBackward,
          backgroundColor: Colors.white,
          color: Colors.redAccent,
          shapeWidth: 100.0,
          spaceBetweenShapes: 100.0,
          shapeOffset: ScrollerShapeOffset.shiftAndMesh,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    isLogin ? 'Iniciar Sesión' : 'Registro',
                    key: ValueKey<bool>(
                        isLogin), // Important for AnimatedSwitcher
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const Icon(
                    Icons.content_cut,
                    size: 80,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          );
                        },
                        child: !isLogin
                            ? TextFormField(
                                cursorColor: Colors.grey,
                                key: const ValueKey('username'),
                                style: TextStyle(color: Colors.grey[800]),
                                decoration: InputDecoration(
                                  labelText: 'Nombre de usuario',
                                  labelStyle:
                                      TextStyle(color: Colors.grey[800]),
                                  filled: true,
                                  fillColor: Colors.white70,
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.grey[800],
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa un nombre de usuario';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  username = value!.trim();
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        cursorColor: Colors.grey,
                        style: TextStyle(color: Colors.grey[800]),
                        key: const ValueKey('email'),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: TextStyle(color: Colors.grey[800]),
                          filled: true,
                          fillColor: Colors.white70,
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.grey[800],
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              !value.contains('@') ||
                              !value.contains('.')) {
                            return 'Ingresa un correo válido';
                          }
                          final atIndex = value.indexOf('@');
                          final dotIndex = value.lastIndexOf('.');
                          if (atIndex < 1 ||
                              atIndex == value.length - 1 ||
                              dotIndex <= atIndex + 1 ||
                              dotIndex == value.length - 1) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          email = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        cursorColor: Colors.grey,
                        style: TextStyle(color: Colors.grey[800]),
                        key: const ValueKey('password'),
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: Colors.grey[800]),
                          filled: true,
                          fillColor: Colors.white70,
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Colors.grey[800],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[800],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSaved: (value) {
                          password = value!;
                        },
                        validator: isLogin
                            ? _validateLoginPassword
                            : _validateRegisterPassword,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          );
                        },
                        child: !isLogin
                            ? Column(
                                children: [
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    cursorColor: Colors.grey,
                                    style: TextStyle(color: Colors.grey[800]),
                                    key: const ValueKey('confirmPassword'),
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Confirmar Contraseña',
                                      labelStyle:
                                          TextStyle(color: Colors.grey[800]),
                                      filled: true,
                                      fillColor: Colors.white70,
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: Colors.grey[800],
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[800],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    validator: _validateConfirmPassword,
                                    onSaved: (value) {
                                      confirmPassword = value!;
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(
                          isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          isLogin
                              ? '¿No tienes cuenta? Regístrate'
                              : 'Ya tengo cuenta',
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
