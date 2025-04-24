import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/services/supabase_service.dart';
import 'package:intl/intl.dart';
import '../global_keys.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userRole = 'cliente';
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final GlobalKey<_BookAppointmentWidgetState> _bookAppointmentKey =
      GlobalKey<_BookAppointmentWidgetState>();
  String? _profileImageUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final imageUrl = userDoc.data()?['profileImageUrl'];
        if (imageUrl != null && imageUrl.contains('guerrerobarberapp')) {
          // Si la URL es de Supabase, intentamos obtener una URL firmada
          final fileName = imageUrl.split('guerrerobarberapp/').last;
          final signedUrl = await SupabaseService.getPublicUrl(fileName);
          setState(() {
            _profileImageUrl = signedUrl;
            _username = userDoc.data()?['username'] ?? user.email;
          });
        } else {
          setState(() {
            _profileImageUrl = imageUrl;
            _username = userDoc.data()?['username'] ?? user.email;
          });
        }
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userRole = userDoc.data()?['role'] ?? 'cliente';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index >= 0 && index < (userRole == 'admin' ? 4 : 4)) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);
      if (index != 1) {
        _bookAppointmentKey.currentState?.clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> navigationItems = [
      const Icon(Icons.list, size: 30, color: Colors.white),
      const Icon(Icons.add, size: 30, color: Colors.white),
      const Icon(Icons.calendar_today, size: 30, color: Colors.white),
      Icon(
        userRole == 'admin' ? Icons.admin_panel_settings : Icons.pending_actions,
        size: 30,
        color: Colors.white,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Guerrero Barber',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (userRole != 'admin')
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.blue)
                      : null,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada')),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (index >= 0 && index < (userRole == 'admin' ? 4 : 4)) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: [
          const AppointmentsList(),
          const BookAppointmentWidget(),
          const CalendarScreen(),
          if (userRole == 'admin')
            const PendingAppointmentsScreen()
          else
            const AppointmentStatusScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: const Key('bottomNav'),
        index: _currentIndex,
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        buttonBackgroundColor: Colors.redAccent,
        items: navigationItems,
        onTap: _onTabTapped,
      ),
    );
  }
}

class AppointmentsList extends StatelessWidget {
  const AppointmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    if (userEmail == null) {
      return const Center(child: Text("No autorizado."));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("appointments")
            .where('userEmail', isEqualTo: userEmail)
            .where('dateTime',
                isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
            .orderBy('dateTime')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No tienes citas actuales registradas.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final dateTime = DateTime.parse(data["dateTime"]);
              final formattedDate =
                  DateFormat('EEEE, d MMMM', 'es_ES').format(dateTime);
              return Dismissible(
                key: Key(data['id']),
                direction: DismissDirection.endToStart,
                background: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(width: 8),
                        Icon(Icons.delete, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection("appointments")
                      .doc(data['id'])
                      .delete();
                  // Usa navigatorKey.currentContext! para obtener un context activo
                  if (navigatorKey.currentContext != null) {
                    ScaffoldMessenger.of(navigatorKey.currentContext!)
                        .showSnackBar(
                      const SnackBar(content: Text('Cita eliminada')),
                    );
                  }
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.blue),
                      trailing: const Icon(Icons.arrow_back_ios,
                          color: Colors.redAccent),
                      title: Text(
                        "${data["service"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "A las ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookAppointmentWidget extends StatefulWidget {
  const BookAppointmentWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookAppointmentWidgetState createState() => _BookAppointmentWidgetState();
}

class _BookAppointmentWidgetState extends State<BookAppointmentWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String haircut = '';
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Método para limpiar el formulario
  void clearForm() {
    setState(() {
      haircut = '';
      _dateController.clear(); // Limpia el controlador
      _timeController.clear(); // Asigna cadena vacía
      _formKey.currentState?.reset();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime adjustedInitialDate;
    if (selectedDate != null) {
      adjustedInitialDate = selectedDate!;
    } else {
      // Si hoy es lunes o domingo, ajusta al siguiente día habilitado
      if (now.weekday == DateTime.monday) {
        // Si es lunes, suma 1 día; si es domingo, suma 1 o 2 días según convenga (en este caso 1 día, ya que lunes también se descarta, quizá 2 días)
        adjustedInitialDate = now.add(const Duration(days: 1));
      } else if (now.weekday == DateTime.sunday) {
        adjustedInitialDate = now.add(const Duration(days: 2));
      } else {
        adjustedInitialDate = now;
      }
    }

    final newDate = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: adjustedInitialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        // Deshabilitar lunes y domingos
        if (day.weekday == DateTime.monday || day.weekday == DateTime.sunday) {
          return false;
        }
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogTheme: const DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
        _dateController.text =
            "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (selectedDate == null) return;

    List<TimeOfDay> availableTimes = [];
    if (selectedDate!.weekday >= DateTime.tuesday &&
        selectedDate!.weekday <= DateTime.friday) {
      availableTimes.addAll([
        const TimeOfDay(hour: 9, minute: 30),
        const TimeOfDay(hour: 10, minute: 00),
        const TimeOfDay(hour: 10, minute: 30),
        const TimeOfDay(hour: 11, minute: 00),
        const TimeOfDay(hour: 11, minute: 30),
        const TimeOfDay(hour: 12, minute: 00),
        const TimeOfDay(hour: 12, minute: 30),
        const TimeOfDay(hour: 13, minute: 00),
        const TimeOfDay(hour: 13, minute: 30),
        const TimeOfDay(hour: 14, minute: 00),
        const TimeOfDay(hour: 17, minute: 00),
        const TimeOfDay(hour: 17, minute: 30),
        const TimeOfDay(hour: 18, minute: 00),
        const TimeOfDay(hour: 18, minute: 30),
        const TimeOfDay(hour: 19, minute: 00),
        const TimeOfDay(hour: 19, minute: 30),
        const TimeOfDay(hour: 20, minute: 00),
        const TimeOfDay(hour: 20, minute: 30)
      ]);
    } else if (selectedDate!.weekday == DateTime.saturday) {
      availableTimes.addAll([
        const TimeOfDay(hour: 9, minute: 30),
        const TimeOfDay(hour: 10, minute: 00),
        const TimeOfDay(hour: 10, minute: 30),
        const TimeOfDay(hour: 11, minute: 00),
        const TimeOfDay(hour: 11, minute: 30),
        const TimeOfDay(hour: 12, minute: 00),
        const TimeOfDay(hour: 12, minute: 30),
        const TimeOfDay(hour: 13, minute: 00),
        const TimeOfDay(hour: 13, minute: 30),
      ]);
    }

    if (availableTimes.isEmpty) return;

    final initialTime = availableTimes.first;

    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'ES'),
          child: Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color.fromARGB(255, 59, 125, 179),
              colorScheme: const ColorScheme.light(primary: Colors.blue),
              buttonTheme:
                  const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          ),
        );
      },
    );

    if (newTime != null) {
      if (availableTimes.contains(newTime)) {
        setState(() {
          selectedTime = newTime;
          _timeController.text = selectedTime!.format(context);
        });
      } else {
        ScaffoldMessenger.of(mounted ? context : context).showSnackBar(
          const SnackBar(
            content: Text('Hora no disponible para este día.'),
          ),
        );
      }
    }
  }

  void _submitAppointment() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (selectedDate == null || selectedTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Seleccione día y hora")),
          );
        }
        return;
      }

      // Validar día
      if (selectedDate!.weekday == DateTime.monday ||
          selectedDate!.weekday == DateTime.sunday) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Los lunes y domingos el peluquero está cerrado.')),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection("appointments")
            .where('dateTime', isEqualTo: appointmentDateTime.toIso8601String())
            .get();

        if (snapshot.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El horario ya está reservado.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No autorizado')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Obtener el username del usuario
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final username = userDoc.data()?['username'] ?? user.email;

        final newAppointmentRef =
            FirebaseFirestore.instance.collection("appointments").doc();
        await newAppointmentRef.set({
          'id': newAppointmentRef.id,
          'userEmail': user.email,
          'username': username,
          'dateTime': appointmentDateTime.toIso8601String(),
          'service': haircut,
          'notes': "",
          'status': "pending",
          'notificationScheduled': true,
        });

        // Notificar al administrador sobre la nueva cita pendiente
        final adminSnapshot =
            await FirebaseFirestore.instance.collection('admins').get();

        // ignore: unused_local_variable
        for (var adminDoc in adminSnapshot.docs) {
          // Enviar notificación a cada administrador
          await NotificationsService().showNotification(
            title: 'Nueva cita pendiente',
            body: 'Tienes una nueva cita pendiente de aprobación',
            appointmentTime: appointmentDateTime,
            scheduledTime: DateTime.now(),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Cita registrada. Pendiente de aprobación por el administrador.')),
          );

          // Limpia el formulario
          clearForm();
        }

        setState(() => _isLoading = false);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    hintText: 'Selecciona un día',
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectDate(context),
                  validator: (_) {
                    if (selectedDate == null) {
                      return 'Por favor, selecciona un día';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Hora',
                    hintText: 'Selecciona una hora',
                    suffixIcon: Icon(Icons.access_time, color: Colors.blue),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(context),
                  validator: (_) {
                    if (selectedTime == null) {
                      return 'Por favor, selecciona una hora';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Corte deseado',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.content_cut, color: Colors.blue),
                  ),
                  onChanged: (value) {
                    setState(() {
                      haircut = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa un corte deseado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitAppointment,
                  child: const Text('Reservar Cita',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 100),
                const Text(
                  'El horario es de Martes a Viernes de 9:30–14:00, 17:00–21:00 y los Sábados de 9:30–14:00',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
