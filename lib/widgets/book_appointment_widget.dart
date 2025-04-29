import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/models/appointment.dart';
import 'package:guerrero_barber_app/services/services.dart';
import 'package:intl/intl.dart';

class BookAppointmentWidget extends StatefulWidget {
  const BookAppointmentWidget({super.key});

  @override
  BookAppointmentWidgetState createState() => BookAppointmentWidgetState();
}

class BookAppointmentWidgetState extends State<BookAppointmentWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String haircut = '';
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  void clearForm() {
    setState(() {
      haircut = '';
      _dateController.clear();
      _timeController.clear();
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
      if (now.weekday == DateTime.monday) {
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
        return !(day.weekday == DateTime.monday ||
            day.weekday == DateTime.sunday);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.secondary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
        _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
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
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                  primary: Theme.of(context).colorScheme.secondary),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary),
              ),
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

    if (newTime != null && availableTimes.contains(newTime)) {
      setState(() {
        selectedTime = newTime;
        _timeController.text = selectedTime!.format(context);
      });
    } else if (newTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hora no disponible para este día.')),
      );
    }
  }

  Future<void> _submitAppointment() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (selectedDate == null || selectedTime == null || haircut.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String? deviceToken = await DeviceTokenService().getDeviceToken();
      if (deviceToken == null) {
        print('No se pudo obtener el token del dispositivo');
      }

      final DateTime appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final String appointmentId =
          FirebaseFirestore.instance.collection('appointments').doc().id;

      final appointment = Appointment(
        id: appointmentId,
        userId: FirebaseAuth.instance.currentUser!.uid,
        dateTime: appointmentDateTime,
        service: haircut,
        notes: '',
        userEmail: FirebaseAuth.instance.currentUser!.email!,
        username: FirebaseAuth.instance.currentUser!.displayName,
      );

      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .set({
          ...appointment.toMap(),
          'userEmail': FirebaseAuth.instance.currentUser!.email,
          'username': FirebaseAuth.instance.currentUser!.displayName,
          'status': 'pending',
          'userToken': deviceToken ?? '',
          'notificationScheduled': true,
        });

        await NotificationsService().notifyPendingAppointment();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita solicitada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
        clearForm();
      } catch (e) {
        print('Error al crear la cita: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Error al crear la cita. Por favor intenta de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Espacio superior
                const SizedBox(height: 20),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Día',
                    hintText: 'DD/MM/AAAA',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecciona un día';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Hora',
                    hintText: 'HH:MM',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onTap: () => _selectTime(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecciona una hora';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Corte Deseado',
                    hintText: 'Indica el tipo de corte',
                    prefixIcon: const Icon(Icons.content_cut),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      haircut = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, describe el corte deseado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitAppointment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Solicitar Cita',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Horario de atención: Martes a Viernes de 9:30–14:00 y 17:00–21:00. Sábados de 9:30–14:00.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40), // Espacio inferior
              ],
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
} 