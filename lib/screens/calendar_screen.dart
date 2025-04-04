import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define a class to represent an appointment
class Appointment {
  final String id;
  final String userId;
  final DateTime dateTime;
  final String service;
  final String notes;

  Appointment({
    required this.id,
    required this.userId,
    required this.dateTime,
    required this.service,
    required this.notes,
  });

  // Factory constructor to create an Appointment from a map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      service: map['service'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

// Create a FirestoreService class to handle Firestore interactions
class FirestoreService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _loadAppointments();
  }

  void _loadAppointments() async {
    // Consulta las citas del día seleccionado usando Firestore
    final startOfDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadAppointments();
                  if (selectedDay.weekday == DateTime.monday ||
                      selectedDay.weekday == DateTime.sunday) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El peluquero está cerrado este día.'),
                      ),
                    );
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.monday ||
                        day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return null;
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.monday ||
                        day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: const CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  titleTextFormatter: (date, locale) =>
                      DateFormat.yMMMM(locale).format(date).toUpperCase(),
                  titleTextStyle:
                      const TextStyle(color: Colors.blue, fontSize: 18),
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: Colors.blue),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_appointments.isEmpty) {
      return const Center(
        child: Text(
          'No hay citas para este día.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.event, color: Colors.blue),
            title: Text(appointment.service,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Hora: ${DateFormat('HH:mm').format(appointment.dateTime)}'),
          ),
        );
      },
    );
  }
}
