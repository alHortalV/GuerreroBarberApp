import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import '../firebase_firestore.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() async {
    // Consulta las citas del día seleccionado usando Firestore
    final startOfDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot = await FirestoreService.firestore
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('dateTime', isLessThan: endOfDay.toIso8601String())
        .get();

    setState(() {
      _appointments =
          snapshot.docs.map((doc) => Appointment.fromMap(doc.data())).toList();
    });
  }

  // Valida si el horario ya está reservado (comparando fecha y hora)
  bool _isSlotAvailable(DateTime dateTime) {
    for (final appt in _appointments) {
      if (appt.dateTime == dateTime) return false;
    }
    return true;
  }

  void _bookAppointment(DateTime dateTime) async {
    if (!_isSlotAvailable(dateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El horario ya está reservado.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newAppointmentRef =
        FirestoreService.firestore.collection('appointments').doc();
    final newAppointment = Appointment(
      id: newAppointmentRef.id,
      userId: user.uid,
      dateTime: dateTime,
      service: "Corte",
      notes: '',
    );

    await newAppointmentRef.set(newAppointment.toMap());

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Cita reservada exitosamente.')));

    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario de Citas'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadAppointments();
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                return ListTile(
                  title: Text(
                      '${appt.service} a las ${appt.dateTime.hour}:${appt.dateTime.minute.toString().padLeft(2, '0')}'),
                );
              },
            ),
          ),
          // Ejemplo: reserva una cita fija a las 10:00 AM del día seleccionado.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              child: Text('Reservar cita a las 10:00'),
              onPressed: () {
                final appointmentTime = DateTime(_selectedDay.year,
                    _selectedDay.month, _selectedDay.day, 10, 0);
                _bookAppointment(appointmentTime);
              },
            ),
          )
        ],
      ),
    );
  }
}
