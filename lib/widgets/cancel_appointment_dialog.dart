import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/services/appointment_notification_service.dart';

class CancelAppointmentDialog extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final bool isAdminCancellation;

  const CancelAppointmentDialog({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
    this.isAdminCancellation = true,
  });

  @override
  State<CancelAppointmentDialog> createState() => _CancelAppointmentDialogState();
}

class _CancelAppointmentDialogState extends State<CancelAppointmentDialog> {
  String? reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar Cita'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Estás seguro de que deseas cancelar esta cita?'),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Ingresa el motivo de la cancelación',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => reason = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            try {
              // Crear la notificación
              final notificationService = AppointmentNotificationService();
              await notificationService.createCancelledAppointmentNotification(
                appointmentId: widget.appointmentId,
                userEmail: widget.appointmentData['userEmail'],
                service: widget.appointmentData['service'],
                appointmentDateTime: DateTime.parse(widget.appointmentData['dateTime']),
                reason: reason,
                isAdminCancellation: widget.isAdminCancellation,
              );

              // Eliminar la cita
              await FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(widget.appointmentId)
                  .delete();

              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cancelar la cita: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop(false);
              }
            }
          },
          child: const Text('Confirmar Cancelación'),
        ),
      ],
    );
  }
} 