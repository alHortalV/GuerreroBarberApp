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
  List<TimeOfDay> availableTimes = [];

  List<DropdownMenuItem<TimeOfDay>> get timeDropdownItems {
    return availableTimes
        .map((time) => DropdownMenuItem(
              value: time,
              child: Text(time.format(context)),
            ))
        .toList();
  }

  void _updateAvailableTimes() async {
    availableTimes.clear();
    if (selectedDate == null) return;
    // Definir los horarios según el día
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
    // Filtrar horas ocupadas
    if (selectedDate != null && availableTimes.isNotEmpty) {
      final date = selectedDate!;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('dateTime', isLessThan: endOfDay.toIso8601String())
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      final takenTimes = appointments.docs.map((doc) {
        final dt = DateTime.parse(doc['dateTime']);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }).toSet();
      availableTimes.removeWhere((t) => takenTimes.contains(t));
    }
    setState(() {});
    if (availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay citas disponibles para este día.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _updateAvailableTimes();
  }

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
        selectedTime = null;
        _timeController.clear();
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _updateAvailableTimes();
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

      // Comprobar si el usuario está vetado
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        if (data != null && data['blockUntil'] != null) {
          final blockUntil = DateTime.tryParse(data['blockUntil']);
          if (blockUntil != null && blockUntil.isAfter(DateTime.now())) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No puedes reservar citas hasta el ${DateFormat('dd/MM/yyyy').format(blockUntil)} por acumulación de faltas.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

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

      if (appointmentDateTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No puedes reservar una cita en el pasado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validar si el usuario ya tiene una cita en el mismo día
      final startOfDay = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingAppointmentsForDay = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userEmail', isEqualTo: FirebaseAuth.instance.currentUser!.email)
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('dateTime', isLessThan: endOfDay.toIso8601String())
          .where('status', whereIn: ['pending', 'approved']) // Solo citas pendientes o aprobadas
          .get();

      if (existingAppointmentsForDay.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya tienes una cita reservada para este día. Solo se permite una cita por día.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validar si ya existe una cita en la misma fecha y hora
      final existing = await FirebaseFirestore.instance
          .collection('appointments')
          .where('dateTime', isEqualTo: appointmentDateTime.toIso8601String())
          .get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe una cita reservada para esa hora.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                  Center(
                    child: SizedBox(
                      child: DropdownButtonFormField<TimeOfDay>(
                        value: selectedTime,
                        items: availableTimes.isEmpty ? [] : timeDropdownItems,
                        onChanged: (availableTimes.isEmpty || selectedDate == null)
                            ? null
                            : (value) {
                                setState(() {
                                  selectedTime = value;
                                  _timeController.text = value != null ? value.format(context) : '';
                                });
                              },
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Hora',
                          prefixIcon: Icon(
                            Icons.access_time,
                            color: (availableTimes.isEmpty || selectedDate == null)
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400])
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: (availableTimes.isEmpty || selectedDate == null)
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[400]!)
                                  : Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: (availableTimes.isEmpty || selectedDate == null)
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[400]!)
                                  : Theme.of(context).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: (availableTimes.isEmpty || selectedDate == null)
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[400]!)
                                  : Theme.of(context).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: (availableTimes.isEmpty || selectedDate == null)
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[400]!)
                                  : Theme.of(context).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: (availableTimes.isEmpty || selectedDate == null)
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100])
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white10
                                  : Colors.grey[50]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        dropdownColor: (availableTimes.isEmpty || selectedDate == null)
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100])
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: (availableTimes.isEmpty || selectedDate == null)
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400])
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        style: TextStyle(
                          color: (availableTimes.isEmpty || selectedDate == null)
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400])
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        validator: (value) {
                          if (availableTimes.isEmpty) {
                            return 'No hay horas disponibles para este día';
                          }
                          if (value == null) {
                            return 'Por favor, selecciona una hora';
                          }
                          return null;
                        },
                        selectedItemBuilder: (context) {
                          return availableTimes.map((time) {
                            return Text(
                              time.format(context),
                              style: TextStyle(
                                color: (availableTimes.isEmpty || selectedDate == null)
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400])
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          }).toList();
                        },
                        menuMaxHeight: 320,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Corte Deseado',
                      hintText: 'Indica el tipo de corte',
                      prefixIcon: const Icon(Icons.content_cut, color: null),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
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
                  const SizedBox(height: 40),
                  const Text(
                    'IMPORTANTE:\nSi llegas entre 15 y 30 minutos tarde, tendrás que abonar el doble del importe de la siguiente cita por las molestias ocasionadas.\n\nSi no te presentas a 4 citas, serás vetado y no podrás reservar durante 4 meses.',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
