import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class AppointmentStatusScreen extends StatelessWidget {
  const AppointmentStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userEmail', isEqualTo: user?.email)
          .where('dateTime',
              isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No tienes citas pendientes',
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
            final status = data['status'] ?? 'pending';

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cita para ${data['service']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha: ${DateFormat('EEEE d MMMM, y', 'es_ES').format(dateTime)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Hora: ${DateFormat('HH:mm').format(dateTime)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(status),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeline(String status) {
    return Column(
      children: [
        TimelineTile(
          isFirst: true,
          endChild: _buildTimelineContent(
            'Cita Registrada',
            true,
            Colors.green,
          ),
          beforeLineStyle: const LineStyle(color: Colors.green),
        ),
        TimelineTile(
          endChild: _buildTimelineContent(
            'Pendiente de Aprobación',
            status == 'pending',
            status == 'approved' ? Colors.green : Colors.orange,
          ),
          beforeLineStyle: LineStyle(
            color: status == 'approved' ? Colors.green : Colors.orange,
          ),
        ),
        TimelineTile(
          isLast: true,
          endChild: _buildTimelineContent(
            'Cita Confirmada',
            status == 'approved',
            status == 'approved' ? Colors.green : Colors.grey,
          ),
          beforeLineStyle: LineStyle(
            color: status == 'approved' ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineContent(String text, bool isActive, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 