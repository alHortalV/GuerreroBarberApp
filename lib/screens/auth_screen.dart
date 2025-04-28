import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:dynamic_background/dynamic_background.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';


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
  bool isForgotPassword = false;
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

    // Validar email (siempre necesario)
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido')),
      );
      return;
    }
    final atIndex = email.indexOf('@');
    final dotIndex = email.lastIndexOf('.');
    if (atIndex < 1 ||
        atIndex == email.length - 1 ||
        dotIndex <= atIndex + 1 ||
        dotIndex == email.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido')),
      );
      return;
    }

    // Si está en modo "Reestablecer contraseña" solo se necesita el correo
    if (isForgotPassword) {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(mounted ? context : context).showSnackBar(
          const SnackBar(
              content: Text('Se ha enviado el enlace de reinicio a tu correo')),
        );
        setState(() {
          isForgotPassword = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(mounted ? context : context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      return;
    }

    // Validar username para registro
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
        // Obtén el nombre del usuario desde la colección de users
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          username = data['username'] ?? '';
        }
        // Comprobar si las credenciales pertenecen a un administrador
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: email)
            .get();
        bool isAdmin = false;
        if (adminSnapshot.docs.isNotEmpty) {
          final adminData = adminSnapshot.docs.first.data();
          // Se asume que en el documento de admins se guarda la contraseña en claro (o con un método compatible)
          if (adminData['email'] == email) {
            isAdmin = true;
          }
          username = adminData['username'] ?? '';
        }
        if (isAdmin) {
          // Si es administrador, registrar el token del dispositivo
          await DeviceTokenService().registerDeviceToken();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bienvenido de nuevo, $username')),
            );
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AdminPanel()));
          }
        } else {
          // También registrar el token para usuarios normales
          await DeviceTokenService().registerDeviceToken();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bienvenido de nuevo, $username')),
            );
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
          }
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
          'phone': '', // Campo para el número de teléfono
          'profileImageUrl': '', // Campo para la foto de perfil
          'createdAt': FieldValue.serverTimestamp(), // Fecha de creación
          'role': 'cliente', // Rol por defecto
        });
        ScaffoldMessenger.of(mounted ? context : context).showSnackBar(
          SnackBar(content: Text('Registro exitoso')),
        );
        Navigator.of(mounted ? context : context)
            .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
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
    if (!isForgotPassword) {
      if (isLogin) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      setState(() {
        isLogin = !isLogin;
      });
    }
  }

  void _toggleForgotPassword() {
    // Si se activa, mostramos solo el campo de correo y cambiamos títulos y botón
    setState(() {
      isForgotPassword = !isForgotPassword;
    });
  }

  // Método de inicio de sesión con Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Cancelado por el usuario

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Verificar si el usuario ya existe en Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          // Crear el documento del usuario
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'username': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': '', // Campo para el número de teléfono
            'profileImageUrl': user.photoURL ?? '', // Usar la foto de perfil de Google si está disponible
            'createdAt': FieldValue.serverTimestamp(), // Fecha de creación
            'role': 'cliente',
          });
        }

        ScaffoldMessenger.of(mounted ? context : context).showSnackBar(
          SnackBar(
            content: Text("Bienvenido, ${user.displayName ?? ''}"),
          ),
        );
        Navigator.of(mounted ? context : context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(mounted ? context : context).showSnackBar(
        SnackBar(
          content: Text("Error al iniciar sesión con Google: ${e.toString()}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicBg(
        duration: const Duration(seconds: 45),
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
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Center(
                    key: ValueKey<String>(isForgotPassword
                        ? 'forgotTitle'
                        : (isLogin ? 'loginTitle' : 'registerTitle')),
                    child: Text(
                      isForgotPassword
                          ? 'Reestablecer Contraseña'
                          : (isLogin ? 'Iniciar Sesión' : 'Registro'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 37, 83, 105),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const Icon(
                    Icons.content_cut,
                    size: 80,
                    color: Color.fromARGB(255, 37, 83, 105),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // En modo Reestablecer contraseña solo se muestra el correo
                      if (isForgotPassword)
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
                        )
                      else ...[
                        // Muestra el campo de nombre si no es inicio de sesión (registro)
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
                                  key: const ValueKey('username'),
                                  cursorColor: Colors.grey,
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
                                      borderSide:
                                          BorderSide(color: Colors.grey),
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
                        // Campo correo
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
                        // Campo contraseña
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
                        // Solo en Registro se muestra el campo de confirmar contraseña
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                      ],
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
                          isForgotPassword
                              ? 'Enviar enlace'
                              : (isLogin ? 'Iniciar Sesión' : 'Registrarse'),
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          label: const Text("Iniciar Sesión con Google",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Botones para cambiar de modo:
                      if (isForgotPassword)
                        TextButton(
                          onPressed: _toggleForgotPassword,
                          child: const Text(
                            'Volver',
                            style: TextStyle(
                              color: Color.fromARGB(255, 37, 83, 105),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else ...[
                        TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(
                            isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : 'Ya tengo cuenta',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 37, 83, 105),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isLogin)
                          TextButton(
                            onPressed: _toggleForgotPassword,
                            child: const Text(
                              'Se me olvidó la contraseña',
                              style: TextStyle(
                                color: Color.fromARGB(255, 37, 83, 105),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ]
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
