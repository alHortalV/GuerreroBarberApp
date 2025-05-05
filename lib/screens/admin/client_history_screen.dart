import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:guerrero_barber_app/models/user_model.dart';

class ClientHistoryScreen extends StatelessWidget {
  final String clientEmail;
  const ClientHistoryScreen({super.key, required this.clientEmail});

  Future<UserModel?> _fetchUser() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: clientEmail)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return UserModel.fromMap(doc.id, doc.data());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final appointmentsQuery = FirebaseFirestore.instance
        .collection("appointments")
        .where("userEmail", isEqualTo: clientEmail)
        .where('dateTime', isGreaterThanOrEqualTo: oneYearAgo.toIso8601String())
        .get();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Citas"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: FutureBuilder<UserModel?>(
        future: _fetchUser(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnapshot.data;
          return Column(
            children: [
              if (user != null)
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (user.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.phone,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: appointmentsQuery,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay citas registradas en el último año.",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final dateTime = DateTime.parse(data["dateTime"]);
                        final formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(dateTime);
                        final service = data["service"] ?? "Servicio";
                        final status = data["status"] ?? "";
                        Color? cardColor;
                        IconData? icon;
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        if (status == 'pending') {
                          cardColor = Theme.of(context).extension<CustomThemeExtension>()?.appointmentStatusColors.pendingBackground;
                          icon = Icons.hourglass_empty;
                        } else if (status == 'approved') {
                          cardColor = Theme.of(context).extension<CustomThemeExtension>()?.appointmentStatusColors.confirmedBackground;
                          icon = Icons.check_circle;
                        }
                        return Card(
                          color: cardColor ?? Theme.of(context).cardTheme.color,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              icon,
                              color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              service,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: status.isNotEmpty
                                ? Text(
                                    status == 'pending'
                                        ? 'Pendiente'
                                        : status == 'approved'
                                            ? 'Confirmada'
                                            : 'Cancelada',
                                    style: TextStyle(
                                      color: status == 'pending'
                                          ? Theme.of(context).extension<CustomThemeExtension>()?.appointmentStatusColors.pendingText
                                          : status == 'approved'
                                              ? Theme.of(context).extension<CustomThemeExtension>()?.appointmentStatusColors.confirmedText
                                              : Theme.of(context).extension<CustomThemeExtension>()?.appointmentStatusColors.canceledText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}