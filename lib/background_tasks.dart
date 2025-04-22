import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> checkAppointmentsCallback() async {
  // Consulta las citas pendientes
  final now = DateTime.now();
  final querySnapshot = await FirebaseFirestore.instance
      .collection("appointments")
      .where("dateTime", isGreaterThanOrEqualTo: now.toIso8601String())
      .orderBy("dateTime")
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    // Obtén la cita próxima
    final nextAppointmentData = querySnapshot.docs.first.data();
    final appointmentTime = DateTime.parse(nextAppointmentData["dateTime"]);
    
    // Calcula el momento de notificación: 3 horas antes
    final notificationMoment = appointmentTime.subtract(const Duration(hours: 3));
    
    // Asegúrate de que sea un momento futuro
    final tz.TZDateTime tzNotificationTime = notificationMoment.isBefore(DateTime.now())
        ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1))
        : tz.TZDateTime.from(notificationMoment, tz.local);
    
    // Programa la notificación usando tu servicio
    await NotificationsService().showNotification(
      appointmentTime: appointmentTime,
      title: 'Recordatorio de cita',
      body: 'Tienes una cita a las ${DateFormat("HH:mm").format(appointmentTime)}',
    );
  }
}