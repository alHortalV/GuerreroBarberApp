import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/admin/admin.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/screens/admin/user_details_screen.dart';
import 'package:guerrero_barber_app/models/user_model.dart';

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
          backgroundColor: Theme.of(context).colorScheme.secondary,
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
                text: 'Pendientes',
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
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error al cargar los clientes.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No hay clientes registrados.'));
                      }
                      final clients = snapshot.data!.docs;
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: clients.length,
                              itemBuilder: (context, index) {
                                final data = clients[index].data()
                                    as Map<String, dynamic>;
                                final clientName =
                                    data['username'] ?? data['email'];
                                final clientEmail = data['email'];
                                final profileImage = data['profileImageUrl'];
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
                                        horizontal: 12, vertical: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.black, width: 2)
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 35,
                                          backgroundImage: profileImage != null
                                              ? NetworkImage(profileImage)
                                              : null,
                                          child: profileImage == null
                                              ? const Icon(Icons.person,
                                                  size: 35)
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        Flexible(
                                          child: Text(
                                            clientName,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white),
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: selectedEmail != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClientHistoryScreen(
                                                  clientEmail: selectedEmail!,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    icon: const Icon(Icons.history,
                                        color: Colors.white),
                                    label: const Text(
                                      'Historial',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: selectedIndex != null
                                        ? () {
                                            final userId =
                                                clients[selectedIndex!].id;
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserDetailsScreen(
                                                        userId: userId),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    label: const Text(
                                      'Editar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: selectedEmail != null &&
                                            selectedName != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClientConfirmedAppointmentsScreen(
                                                  clientEmail: selectedEmail!,
                                                  clientName: selectedName!,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    icon: const Icon(Icons.event_available,
                                        color: Colors.white),
                                    label: const Text(
                                      'Citas',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
