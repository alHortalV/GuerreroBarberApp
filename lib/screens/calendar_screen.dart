import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/firebase_firestore.dart';
import 'package:guerrero_barber_app/models/appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userEmail = user.email!;
    // Calcula el inicio del día seleccionado (00:00 horas)
    final selectedDateStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    // Definimos el fin del día seleccionado
    final endOfDay = selectedDateStart.add(const Duration(days: 1));

    final snapshot = await FirestoreService.firestore
        .collection('appointments')
        .where('userEmail', isEqualTo: userEmail)
        // Se buscan todas las citas del día seleccionado.
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 1,
              color: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                      SnackBar(
                        content: Text(
                          'El peluquero está cerrado este día.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.white,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.red[900] : Colors.red,
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
                          style: TextStyle(
                            color: isDarkMode ? Colors.red[300] : Colors.red,
                          ),
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
                          style: TextStyle(
                            color: isDarkMode ? Colors.red[300] : Colors.red,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue[700] : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.red[700] : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  weekendTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  outsideTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  formatButtonDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue[700] : Colors.blue,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  titleTextFormatter: (date, locale) =>
                      DateFormat.yMMMM(locale).format(date).toUpperCase(),
                  titleTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.blue,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: isDarkMode ? Colors.white : Colors.blue,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? Colors.white : Colors.blue,
                  ),
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
      return Center(
        child: Text(
          'No hay citas para este día.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        // Colores para modo claro
        Color lightBackgroundColor = appointment.status == 'pending' 
            ? Colors.orange.shade200 
            : Colors.green.shade200;
        Color lightTextColor = appointment.status == 'pending' 
            ? Colors.orange[900]! 
            : Colors.green[900]!;
        
        // Colores para modo oscuro
        Color darkBackgroundColor = appointment.status == 'pending' 
            ? Colors.orange.shade900 
            : Colors.green.shade900;
        Color darkTextColor = Colors.white;
        
        // Seleccionar colores según el modo
        Color backgroundColor = isDarkMode ? darkBackgroundColor : lightBackgroundColor;
        Color textColor = isDarkMode ? darkTextColor : lightTextColor;
        
        String statusText = appointment.status == 'pending' 
            ? 'Pendiente' 
            : 'Confirmada';
        
        return Card(
          elevation: isDarkMode ? 8 : 2,
          color: backgroundColor,
          child: ListTile(
            leading: Icon(Icons.event, color: textColor),
            title: Text(
              appointment.service,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              )
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hora: ${DateFormat('HH:mm').format(appointment.dateTime)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  )
                ),
                Text(
                  'Estado: $statusText',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
