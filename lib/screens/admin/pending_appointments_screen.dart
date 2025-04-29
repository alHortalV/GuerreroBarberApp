import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';

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
                  'Cliente: ${data['username'] ?? data['userEmail']}',
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _approveAppointment(context, appointment.id, data),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _rejectAppointment(context, appointment.id, data),
                    ),
                  ],
                ),
              ),
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
      final userToken = appointmentData['userToken'];
      
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
        print('No se encontró token para el usuario ${appointmentData['userEmail']}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cita aprobada correctamente'),
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

  Future<void> _rejectAppointment(BuildContext context, String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      final dateTime = DateTime.parse(appointmentData['dateTime']);
      final userToken = appointmentData['userToken'];

      // Eliminar la cita
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      // Enviar notificación al cliente
      if (userToken != null) {
        final notificationsService = NotificationsService();
        final title = 'Cita no disponible';
        final body = 'Lo sentimos, tu cita para el ${DateFormat('EEEE d MMMM', 'es_ES').format(dateTime)} a las ${DateFormat('HH:mm').format(dateTime)} no está disponible.';

        await notificationsService.sendNotification(
          token: userToken,
          title: title,
          body: body,
        );
      } else {
        print('No se encontró token para el usuario ${appointmentData['userEmail']}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita rechazada correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al rechazar la cita: $e')),
        );
      }
    }
  }
} 