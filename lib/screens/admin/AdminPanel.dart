import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/admin/client_history_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String? selectedEmail;
  String? selectedName;
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Slider horizontal con la lista de clientes
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar clientes.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final clients = snapshot.data!.docs;
                if (clients.isEmpty) {
                  return const Center(child: Text('No hay clientes registrados.'));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    print('Documento $index: ${clients[index].data()}'); // Debug
                    final data = clients[index].data() as Map<String, dynamic>;
                    final clientName = data['username'] ?? data['email'];
                    final clientEmail = data['email'];
                    final isSelected = selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          selectedEmail = clientEmail;
                          selectedName = clientName;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.redAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: Center(
                          child: Text(
                            clientName,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Botón para ver el Historial de Cortes, se habilita solo si se ha seleccionado un cliente
          ElevatedButton(
            onPressed: selectedEmail != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClientHistoryScreen(
                          clientEmail: selectedEmail!,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: const Text(
              'Historial de Cortes',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}