import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/firebase_firestore.dart';
import 'package:guerrero_barber_app/models/appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarAdminScreen extends StatefulWidget {
  const CalendarAdminScreen({super.key});

  @override
  State<CalendarAdminScreen> createState() => _CalendarAdminScreenState();
}

class _CalendarAdminScreenState extends State<CalendarAdminScreen> {
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
    final selectedDateStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = selectedDateStart.add(const Duration(days: 1));

    final snapshot = await FirestoreService.firestore
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: selectedDateStart.toIso8601String())
        .where('dateTime', isLessThan: endOfDay.toIso8601String())
        .orderBy('dateTime')
        .get();

    setState(() {
      _appointments = snapshot.docs
          .map((doc) => Appointment.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  weekendTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  outsideTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  titleTextFormatter: (date, locale) =>
                      DateFormat.yMMMM(locale).format(date).toUpperCase(),
                  titleTextStyle: const TextStyle(color: Colors.blue, fontSize: 18),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.blue),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.blue),
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
            leading: Icon(
              Icons.event, 
              color: Theme.of(context).colorScheme.primary
            ),
            title: Text(
              appointment.service,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Hora: ${DateFormat('HH:mm').format(appointment.dateTime)}\nCliente: ${appointment.username}',
            ),
          ),
        );
      },
    );
  }
}