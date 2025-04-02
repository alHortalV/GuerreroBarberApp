import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/AuthScreen.dart';
import 'package:guerrero_barber_app/screens/calendar_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Simulación: en un escenario real se obtendría el rol del usuario u otros datos si es necesario.
  String userRole = 'cliente';
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar información extra del usuario
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guerrero Barber App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
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
          )
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Para evitar el desplazamiento manual
        children: const [
          AppointmentsList(),
          BookAppointmentWidget(),
          CalendarScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        items: const <Widget>[
          Icon(Icons.list, size: 30, color: Colors.white),
          Icon(Icons.add, size: 30, color: Colors.white),
          Icon(Icons.calendar_today, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          _onTabTapped(index);
        },
      ),
    );
  }
}

// Primera pestaña: Lista de citas registradas
class AppointmentsList extends StatelessWidget {
  const AppointmentsList({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection("appointments").get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No tienes citas registradas."));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final dateTime = DateTime.parse(data["dateTime"]);
            return ListTile(
              leading: const Icon(Icons.event),
              title: Text("${data["service"]}"),
              subtitle: Text(
                  "A las ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"),
            );
          },
        );
      },
    );
  }
}

// Segunda pestaña: Sección para reservar una cita
class BookAppointmentWidget extends StatefulWidget {
  const BookAppointmentWidget({super.key});

  @override
  _BookAppointmentWidgetState createState() => _BookAppointmentWidgetState();
}

class _BookAppointmentWidgetState extends State<BookAppointmentWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String haircut = '';
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? now;
    final newDate = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final initialTime = selectedTime ?? TimeOfDay.now();
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'ES'),
          child: child,
        );
      },
    );
    if (newTime != null) {
      setState(() {
        selectedTime = newTime;
      });
    }
  }

  void _submitAppointment() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (selectedDate == null || selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seleccione día y hora")),
        );
        return;
      }
      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
      });

      // Combinar fecha y hora
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      try {
        // Verificar si ya existe la cita en ese horario
        final snapshot = await FirebaseFirestore.instance
            .collection("appointments")
            .where('dateTime', isEqualTo: appointmentDateTime.toIso8601String())
            .get();
        if (snapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El horario ya está reservado.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Obtener el usuario actual
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No autorizado')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Crear la cita en Firestore
        final newAppointmentRef =
            FirebaseFirestore.instance.collection("appointments").doc();
        await newAppointmentRef.set({
          'id': newAppointmentRef.id,
          'userId': user.uid,
          'dateTime': appointmentDateTime.toIso8601String(),
          'service': haircut,
          'notes': "",
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita reservada exitosamente.')),
        );

        // Reiniciar el formulario
        setState(() {
          selectedDate = null;
          selectedTime = null;
          haircut = '';
          _isLoading = false;
        });
        _formKey.currentState?.reset();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo para seleccionar la fecha
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Día',
                    hintText: selectedDate == null
                        ? 'Selecciona un día'
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    suffixIcon: const Icon(Icons.calendar_today),
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
                // Campo para seleccionar la hora
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    hintText: selectedTime == null
                        ? 'Selecciona una hora'
                        : selectedTime!.format(context),
                    suffixIcon: const Icon(Icons.access_time),
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
                // Campo para escribir el corte deseado
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Corte deseado',
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
                  onPressed: _submitAppointment,
                  child: const Text('Reservar Cita'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
