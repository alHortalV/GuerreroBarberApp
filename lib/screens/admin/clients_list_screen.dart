import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guerrero_barber_app/screens/admin/admin.dart';


class ClientsListScreen extends StatelessWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un cliente")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final clients = snapshot.data!.docs;
          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final data = clients[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['profileImageUrl'] != null
                        ? NetworkImage(data['profileImageUrl'])
                        : null,
                    child: data['profileImageUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(data['name'] ?? data['email']),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ClientHistoryScreen(
                        clientEmail: data['email'],
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}