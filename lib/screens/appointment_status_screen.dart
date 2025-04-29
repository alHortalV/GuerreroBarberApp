import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:intl/intl.dart';

class AppointmentStatusScreen extends StatelessWidget {
  const AppointmentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userEmail', isEqualTo: user?.email)
          .where('dateTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Theme.of(context).primaryColor.withAlpha(5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tienes citas pendientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.content_cut,
                            color: Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cita para ${data['service']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE d MMMM, y', 'es_ES')
                                .format(dateTime),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(dateTime),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildHorizontalTimeline(context, status),
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

  Widget _buildHorizontalTimeline(BuildContext context, String status) {
    final customTheme = Theme.of(context).extension<CustomThemeExtension>()!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimelineStep(
          context,
          Icons.post_add_rounded,
          'Creada',
          true,
          customTheme.appointmentStatusColors.confirmedIcon,
        ),
        _buildArrow(
          status == 'approved' 
            ? customTheme.appointmentStatusColors.confirmedIcon 
            : customTheme.appointmentStatusColors.pendingIcon
        ),
        _buildTimelineStep(
          context,
          Icons.pending_actions,
          'Pendiente',
          status == 'pending',
          status == 'approved' 
            ? customTheme.appointmentStatusColors.confirmedIcon 
            : customTheme.appointmentStatusColors.pendingIcon,
        ),
        _buildArrow(
          status == 'approved' 
            ? customTheme.appointmentStatusColors.confirmedIcon 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
        ),
        _buildTimelineStep(
          context,
          Icons.check_circle_outline,
          'Confirmada',
          status == 'approved',
          status == 'approved' 
            ? customTheme.appointmentStatusColors.confirmedIcon 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    IconData icon,
    String text,
    bool isActive,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow(Color color) {
    return Icon(
      Icons.arrow_forward,
      color: color,
      size: 20,
    );
  }
}
