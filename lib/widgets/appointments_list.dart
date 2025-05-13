import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/screens/home_screen.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/widgets/widgets.dart';
import 'package:intl/intl.dart';

class AppointmentsList extends StatelessWidget {
  final String? username;

  const AppointmentsList({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      return const Center(child: Text("No autorizado."));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hola, ${username ?? 'cliente'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Refresh action
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Text(
                'Tus próximas citas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("appointments")
                        .where('userEmail', isEqualTo: userEmail)
                        .where('dateTime',
                            isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
                        .orderBy('dateTime')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error al cargar las citas: ${snapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No tienes citas programadas",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Reserva una nueva cita ahora",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Navegar a la pestaña de reserva
                                  final homeState = context.findAncestorStateOfType<HomeScreenState>();
                                  if (homeState != null) {
                                    homeState.onTabTapped(1);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No se pudo navegar a la pantalla de reserva'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Reservar cita'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final dateTime = DateTime.parse(data["dateTime"]);
                          final formattedDate =
                              DateFormat('EEEE, d MMMM', 'es_ES').format(dateTime);
                          final formattedTime =
                              "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
                          final status = data['status'] ?? 'pending';

                          // Si la cita está rechazada, la eliminamos de Firebase y no la mostramos
                          if (status == 'rejected') {
                            FirebaseFirestore.instance
                                .collection("appointments")
                                .doc(data['id'])
                                .delete();
                            return const SizedBox.shrink();
                          }

                          return Dismissible(
                            key: Key(data['id']),
                            direction: status.toLowerCase() == 'pending' 
                                ? DismissDirection.endToStart 
                                : DismissDirection.none,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete, color: Colors.white, size: 28),
                                  SizedBox(height: 4),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (status.toLowerCase() != 'pending') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No puedes eliminar una cita confirmada'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return false;
                              }
                              
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text("Confirmar eliminación"),
                                    content: const Text(
                                        "¿Estás seguro de que deseas eliminar esta cita?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) async {
                              await FirebaseFirestore.instance
                                  .collection("appointments")
                                  .doc(data['id'])
                                  .delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cita eliminada correctamente'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: AppointmentCard(
                              dateTime: dateTime,
                              formattedDate: formattedDate,
                              formattedTime: formattedTime,
                              service: data["service"],
                              status: status == 'no_show' ? 'No Asistido' : status,
                              onDetails: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Detalles de la Cita'),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                            context,
                                            'Servicio:',
                                            data["service"],
                                            Icons.content_cut,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildDetailRow(
                                            context,
                                            'Fecha:',
                                            formattedDate,
                                            Icons.event,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildDetailRow(
                                            context,
                                            'Hora:',
                                            formattedTime,
                                            Icons.access_time,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildDetailRow(
                                            context,
                                            'Estado:',
                                            status == 'pending'
                                              ? 'Pendiente'
                                              : status == 'approved'
                                                ? 'Confirmada'
                                                : status == 'no_show'
                                                  ? 'No Asistido'
                                                  : status,
                                            status == 'pending' ? Icons.pending : status == 'approved' ? Icons.check_circle : status == 'no_show' ? Icons.block : Icons.info,
                                            color: status == 'pending' ? Colors.orange : status == 'approved' ? Colors.green : status == 'no_show' ? Colors.red : null,
                                          ),
                                          if (data["notes"] != null && data["notes"].toString().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            _buildDetailRow(
                                              context,
                                              'Notas:',
                                              data["notes"],
                                              Icons.note,
                                            ),
                                          ],
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onReminder: () async {
                                if (status.toLowerCase() != 'approved') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Solo puedes programar recordatorios para citas confirmadas'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                
                                try {
                                  final notificationsService = NotificationsService();
                                  await notificationsService.initNotification();
                                  
                                  // Calcular tiempo hasta la cita
                                  final now = DateTime.now();
                                  final timeUntilAppointment = dateTime.difference(now);
                                  
                                  // Determinar el tiempo de notificación
                                  DateTime notificationTime;
                                  String notificationMessage;
                                  
                                  if (timeUntilAppointment <= const Duration(hours: 1)) {
                                    // Si falta menos de 1 hora, notificar 30 minutos antes
                                    notificationTime = dateTime.subtract(const Duration(minutes: 30));
                                    notificationMessage = 'Tienes una cita en 30 minutos para ${data["service"]}';
                                  } else {
                                    // Si falta más de 1 hora, notificar 1 hora antes
                                    notificationTime = dateTime.subtract(const Duration(hours: 1));
                                    notificationMessage = 'Tienes una cita en 1 hora para ${data["service"]}';
                                  }
                                  
                                  if (notificationTime.isAfter(now)) {
                                    await notificationsService.scheduleNotification(
                                      id: dateTime.hashCode,
                                      title: 'Recordatorio de Cita',
                                      body: notificationMessage,
                                      scheduledTime: notificationTime,
                                    );
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          timeUntilAppointment <= const Duration(hours: 1)
                                              ? 'Recordatorio programado para 30 minutos antes'
                                              : 'Recordatorio programado para 1 hora antes'
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('La cita está demasiado próxima para programar un recordatorio'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al programar el recordatorio: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode 
              ? Colors.white 
              : (color ?? Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode 
                      ? Colors.white 
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 