import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/services/services.dart';
import 'package:guerrero_barber_app/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String userRole = 'cliente';
  String? _profileImageUrl;
  String? _username;
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final GlobalKey<BookAppointmentWidgetState> _bookAppointmentKey =
      GlobalKey<BookAppointmentWidgetState>();
  late Stream<DocumentSnapshot> _userStream;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _setupUserStream();
    _registerDeviceToken();

    // Configurar el tema de la barra de estado
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      
    ));
  }

  void _setupUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();

      _userSubscription = _userStream.listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final imageUrl = data['profileImageUrl'];
          final username = data['username'] ?? user.email;

          if (imageUrl != null && imageUrl.contains('guerrerobarberapp')) {
            final fileName = imageUrl.split('guerrerobarberapp/').last;
            final signedUrl = await SupabaseService.getPublicUrl(fileName);
            if (mounted) {
              setState(() {
                _profileImageUrl = signedUrl;
                _username = username;
              });
            }
          } else if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
              _username = username;
            });
          }
        }
      });
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          userRole = userDoc.data()?['role'] ?? 'cliente';
        });
      }
    }
  }

  Future<void> _registerDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final deviceToken = await DeviceTokenService().getDeviceToken();
      if (deviceToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'deviceToken': deviceToken});
      }
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          scrolledUnderElevation: 0,
          centerTitle: false,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 36,
                // Si no tienes el logo, usa un ícono:
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.content_cut,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Guerrero Barber',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profile-image',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person, color: Colors.blue)
                            : null,
                      ),
                    ),
                    if (userRole == 'admin')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              if (index >= 0 && index < (userRole == 'admin' ? 4 : 4)) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            children: [
              AppointmentsList(username: _username),
              BookAppointmentWidget(key: _bookAppointmentKey),
              const CalendarScreen(),
              if (userRole == 'admin')
                const PendingAppointmentsScreen()
              else
                const AppointmentStatusScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.onPrimary,
                unselectedItemColor:
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                iconSize: 24,
                elevation: 0,
                onTap: onTabTapped,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month),
                    label: 'Mis Citas',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 24),
                    ),
                    label: 'Nueva',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'Calendario',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      userRole == 'admin'
                          ? Icons.admin_panel_settings_outlined
                          : Icons.pending_actions_outlined,
                    ),
                    activeIcon: Icon(
                      userRole == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.pending_actions,
                    ),
                    label: userRole == 'admin' ? 'Admin' : 'Estado',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
