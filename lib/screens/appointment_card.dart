import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  final DateTime dateTime;
  final String formattedDate;
  final String formattedTime;
  final String service;
  final String status;
  final VoidCallback? onReminder;
  final VoidCallback? onDetails;

  const AppointmentCard({
    super.key,
    required this.dateTime,
    required this.formattedDate,
    required this.formattedTime,
    required this.service,
    required this.status,
    this.onReminder,
    this.onDetails,
  });

  bool get isConfirmed {
    final lowercaseStatus = status.toLowerCase();
    return lowercaseStatus == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = !isConfirmed;
    final bool isToday = dateTime.day == DateTime.now().day &&
        dateTime.month == DateTime.now().month &&
        dateTime.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPending
              ? [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ]
              : [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Ver detalles de la cita o realizar alguna acción
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de fecha
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateTime.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          dateTime.month.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isToday ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Detalles de la cita
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Servicio y hora
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.amber.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPending ? "Pendiente" : "Confirmada",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPending
                                      ? Colors.amber[900]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Día y hora
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Acciones para la cita
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: onDetails,
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Detalles'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            TextButton.icon(
                              onPressed: isConfirmed ? onReminder : null,
                              icon: Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: isConfirmed
                                    ? Colors.grey[700]
                                    : Colors.grey[400],
                              ),
                              label: Text(
                                'Recordar',
                                style: TextStyle(
                                  color: isConfirmed
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
