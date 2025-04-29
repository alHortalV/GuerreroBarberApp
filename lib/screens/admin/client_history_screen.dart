import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientHistoryScreen extends StatelessWidget {
  final String clientEmail;
  const ClientHistoryScreen({super.key, required this.clientEmail});

  @override
  Widget build(BuildContext context) {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Citas")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("appointments")
            .where("userEmail", isEqualTo: clientEmail)
            .where('dateTime', isGreaterThanOrEqualTo: oneYearAgo.toIso8601String())
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No hay citas registradas en el último año."));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final dateTime = DateTime.parse(data["dateTime"]);
              final formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(dateTime);
              return ListTile(
                title: Text(data["service"]),
                subtitle: Text(formattedDate),
              );
            },
          );
        },
      ),
    );
  }
}