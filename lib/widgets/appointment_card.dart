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
        color: isPending
            ? Colors.orange.withValues(alpha: 0.3)
            : Colors.green.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                          ? Colors.grey[200]
                          : Theme.of(context).colorScheme.primary,
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
                            color: isToday ? Colors.black87 : Colors.white,
                          ),
                        ),
                        Text(
                          dateTime.month.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isToday ? Colors.black54 : Colors.white,
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
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[500],
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
                                foregroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            TextButton.icon(
                              onPressed: isConfirmed ? onReminder : null,
                              icon: Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? (isConfirmed
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5))
                                    : (isConfirmed
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5)),
                              ),
                              label: Text(
                                'Recordar',
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? (isConfirmed
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5))
                                      : (isConfirmed
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5)),
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
