import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:guerrero_barber_app/services/services.dart';

class PendingAppointmentsScreen extends StatelessWidget {
  const PendingAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No hay citas pendientes por aprobar',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appointment = snapshot.data!.docs[index];
            final data = appointment.data() as Map<String, dynamic>;
            final dateTime = DateTime.parse(data['dateTime']);
            final userEmail = data['userEmail'];

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: userEmail)
                  .limit(1)
                  .get(),
              builder: (context, userSnapshot) {
                String displayName = userEmail;
                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.docs.isNotEmpty) {
                  final userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  displayName = userData['username'] ?? userEmail;
                }
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 1,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).cardTheme.color 
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Cliente: $displayName',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Servicio: ${data['service']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('EEEE d MMMM, y', 'es_ES').format(dateTime)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hora: ${DateFormat('HH:mm').format(dateTime)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _approveAppointment(context, appointment.id, data),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _markNoShow(context, appointment.id, data),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _approveAppointment(BuildContext context, String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      // Actualizar el estado de la cita
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'approved'});

      // Enviar notificación al cliente
      final dateTime = DateTime.parse(appointmentData['dateTime']);
      final userEmail = appointmentData['userEmail'];
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        print('No se encontró usuario con email $userEmail');
        return;
      }
      final userId = userQuery.docs.first.id;
      final userToken = await DeviceTokenService().getUserLastDeviceToken(userId);
      if (userToken != null) {
        final notificationsService = NotificationsService();
        final String formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
        final String formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
        const title = "¡Cita Confirmada!";
        final body = "Tu cita para el $formattedDate a las $formattedTime ha sido confirmada";
        await notificationsService.sendNotification(
          token: userToken,
          title: title,
          body: body,
        );
      } else {
        print('No se encontró token para el usuario $userEmail');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cita aprobada correctamente'),
            backgroundColor: Theme.of(context).extension<CustomThemeExtension>()!
              .appointmentStatusColors.confirmedBackground,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aprobar la cita: $e')),
        );
      }
    }
  }

  Future<void> _markNoShow(BuildContext context, String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      final userEmail = appointmentData['userEmail'];
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) return;
      final userDoc = userQuery.docs.first;
      final userRef = userDoc.reference;
      final userData = userDoc.data();
      int noShowCount = userData['noShowCount'] ?? 0;
      noShowCount++;
      DateTime? blockUntil;
      String notificationBody = '';
      if (noShowCount >= 4) {
        blockUntil = DateTime.now().add(const Duration(days: 120));
        notificationBody = 'Has faltado a 4 citas y no podrás reservar durante 4 meses.';
      } else {
        final restantes = 4 - noShowCount;
        notificationBody = 'Has faltado a una cita. Si faltas $restantes vez/veces más, no podrás reservar durante 4 meses.';
      }
      await userRef.update({
        'noShowCount': noShowCount,
        if (blockUntil != null) 'blockUntil': blockUntil.toIso8601String(),
      });
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'no_show'});
      // Notificar al usuario
      final userId = userDoc.id;
      final userToken = await DeviceTokenService().getUserLastDeviceToken(userId);
      if (userToken != null) {
        final notificationsService = NotificationsService();
        await notificationsService.sendNotification(
          token: userToken,
          title: 'Falta a la cita',
          body: notificationBody,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falta registrada y usuario notificado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar la falta: $e')),
        );
      }
    }
  }
} 