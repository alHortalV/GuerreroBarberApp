import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              child: ListTile(
                title: Text(
                  'Cliente: ${data['username'] ?? data['userEmail']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servicio: ${data['service']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Fecha: ${DateFormat('EEEE d MMMM, y', 'es_ES').format(dateTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Hora: ${DateFormat('HH:mm').format(dateTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveAppointment(context, appointment.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
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
      await NotificationsService().showNotification(
        title: '¡Tu cita ha sido aprobada!',
        body: 'Tu cita para el ${DateFormat('EEEE d MMMM', 'es_ES').format(dateTime)} a las ${DateFormat('HH:mm').format(dateTime)} ha sido confirmada.',
        appointmentTime: dateTime,
        scheduledTime: DateTime.now(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita aprobada correctamente')),
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
      // Eliminar la cita
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      // Enviar notificación al cliente
      final dateTime = DateTime.parse(appointmentData['dateTime']);
      await NotificationsService().showNotification(
        title: 'Cita no disponible',
        body: 'Lo sentimos, tu cita para el ${DateFormat('EEEE d MMMM', 'es_ES').format(dateTime)} a las ${DateFormat('HH:mm').format(dateTime)} no está disponible.',
        appointmentTime: dateTime,
        scheduledTime: DateTime.now(),
      );

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