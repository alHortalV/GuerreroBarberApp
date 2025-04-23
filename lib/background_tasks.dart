import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:intl/intl.dart';

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
    
    // Calcula el momento de notificación: 2 horas antes
    final notificationMoment = appointmentTime.subtract(const Duration(hours: 2));
    
    
    // Programa la notificación usando tu servicio
    await NotificationsService().showNotification(
      appointmentTime: appointmentTime,
      scheduledTime: notificationMoment,
      title: 'Recordatorio de cita',
      body: 'Tienes una cita a las ${DateFormat("HH:mm").format(appointmentTime)}',
    );
  }
}