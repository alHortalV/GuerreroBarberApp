import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';

class AppointmentNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationsService _notificationsService = NotificationsService();

  Future<void> createCancelledAppointmentNotification({
    required String appointmentId,
    required String userEmail,
    required String service,
    required DateTime appointmentDateTime,
    String? reason,
    required bool isAdminCancellation,
  }) async {
    await _firestore.collection('appointment_notifications').add({
      'appointmentId': appointmentId,
      'userEmail': userEmail,
      'service': service,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'reason': reason,
      'isAdminCancellation': isAdminCancellation,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'unread',
    });

    final userDoc = await _firestore
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userId = userDoc.docs.first.id;
      final userToken = await DeviceTokenService().getUserLastDeviceToken(userId);

      if (userToken != null) {
        final title = 'Cita Cancelada';
        final body = reason != null && reason.isNotEmpty
            ? 'Tu cita ha sido cancelada. Abre la aplicación para ver el motivo.'
            : 'Tu cita ha sido cancelada.';

        await _notificationsService.sendNotification(
          token: userToken,
          title: title,
          body: body,
        );
      }
    }
  }

  Stream<QuerySnapshot> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    return _firestore
        .collection('appointment_notifications')
        .where('userEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'unread')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('appointment_notifications')
        .doc(notificationId)
        .update({'status': 'read'});
  }
} 