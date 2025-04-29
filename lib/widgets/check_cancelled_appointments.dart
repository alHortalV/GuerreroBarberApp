import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CheckCancelledAppointments extends StatefulWidget {
  final Widget child;

  const CheckCancelledAppointments({
    super.key,
    required this.child,
  });

  @override
  State<CheckCancelledAppointments> createState() => _CheckCancelledAppointmentsState();
}

class _CheckCancelledAppointmentsState extends State<CheckCancelledAppointments> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForCancelledAppointments();
  }

  Future<void> _checkForCancelledAppointments() async {
    if (_hasChecked) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notifications = await FirebaseFirestore.instance
        .collection('appointment_notifications')
        .where('userEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'unread')
        .get();

    if (notifications.docs.isNotEmpty && mounted) {
      // Marcar como verificado antes de mostrar el diálogo
      setState(() => _hasChecked = true);
      
      // Mostrar el diálogo
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Citas Canceladas'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.docs.length,
                itemBuilder: (context, index) {
                  final notification = notifications.docs[index];
                  final data = notification.data();
                  final appointmentDateTime = DateTime.parse(data['appointmentDateTime']);
                  final formattedDate = DateFormat('EEEE, d MMMM', 'es_ES').format(appointmentDateTime);
                  final formattedTime = DateFormat('HH:mm').format(appointmentDateTime);

                  return Card(
                    child: ListTile(
                      title: Text(
                        data['service'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$formattedDate - $formattedTime'),
                          if (data['reason'] != null && data['reason'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Motivo: ${data['reason']}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        child: Icon(
                          Icons.event_busy,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Marcar todas las notificaciones como leídas
                  for (var doc in notifications.docs) {
                    await FirebaseFirestore.instance
                        .collection('appointment_notifications')
                        .doc(doc.id)
                        .update({'status': 'read'});
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() => _hasChecked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 