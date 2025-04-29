import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CancelledAppointmentsScreen extends StatelessWidget {
  const CancelledAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas Canceladas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointment_notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay citas canceladas',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;
              final appointmentDateTime = DateTime.parse(data['appointmentDateTime']);
              final formattedDate = DateFormat('EEEE, d MMMM', 'es_ES').format(appointmentDateTime);
              final formattedTime = DateFormat('HH:mm').format(appointmentDateTime);
              final createdAt = DateTime.parse(data['createdAt']);
              final formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    data['service'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Cliente: ${data['userEmail']}'),
                      Text('Fecha de cita: $formattedDate - $formattedTime'),
                      Text('Cancelada el: $formattedCreatedAt'),
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
                      Text(
                        'Cancelada por: ${data['isAdminCancellation'] ? 'Administrador' : 'Cliente'}',
                        style: TextStyle(
                          color: data['isAdminCancellation'] 
                              ? Theme.of(context).colorScheme.error 
                              : Theme.of(context).colorScheme.secondary,
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
          );
        },
      ),
    );
  }
} 