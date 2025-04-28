import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/admin/admin.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/screens/admin/calendar_admin_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  String? selectedEmail;
  String? selectedName;
  int? selectedIndex;
  late TabController _tabController;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileImage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Panel de Administración'),
          backgroundColor: Colors.red,
          actions: [
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AdminSettingsScreen()),
                );
                // Recargar la imagen de perfil al volver
                _loadProfileImage();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.red)
                      : null,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.people),
                text: 'Clientes',
              ),
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Citas Pendientes',
              ),
              Tab(
                icon: Icon(Icons.calendar_today),
                text: 'Calendario',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Primera pestaña: Vista de clientes
            Column(
              children: [
                // Slider horizontal con la lista de clientes
                SizedBox(
                  height: 100,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error al cargar los clientes.'));
                      }
                      final clients = snapshot.data!.docs;
                      if (clients.isEmpty) {
                        return const Center(
                            child: Text('No hay clientes registrados.'));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final data =
                              clients[index].data() as Map<String, dynamic>;
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
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.redAccent
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  clientName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
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
                // Botón para ver el Historial de Cortes
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  child: const Text(
                    'Historial de Cortes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            // Segunda pestaña: Citas pendientes
            const PendingAppointmentsScreen(),
            // Tercera pestaña: Calendario admin
            const CalendarAdminScreen(),
          ],
        ),
      ),
    );
  }
}
