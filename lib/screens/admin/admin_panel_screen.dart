import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/admin/admin.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/screens/admin/user_details_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  String? selectedEmail;
  String? selectedName;
  int? selectedIndex;
  late TabController _tabController;
  String? _profileImageUrl;
  
  // Controlador para el ScrollView principal
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileImage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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
    final screenSize = MediaQuery.of(context).size;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        body: SafeArea(
          child: Column(
            children: [
              // Header con AppBar personalizado
              _buildCustomAppBar(context),
              
              // Contenido principal
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Clientes
                    _buildClientsTab(context, screenSize),
                    
                    // Tab 2: Pendientes
                    const PendingAppointmentsScreen(),
                    
                    // Tab 3: Calendario
                    const CalendarAdminScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Panel de Administración',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                    );
                    _loadProfileImage();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Tabs personalizados y adaptables
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            isScrollable: false, // Forzar distribución uniforme
            tabs: _buildAdaptiveTabs(context),
          ),
        ],
      ),
    );
  }

  // Método para construir pestañas adaptables según el ancho de la pantalla
  List<Widget> _buildAdaptiveTabs(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (isSmallScreen) {
      // Para pantallas muy pequeñas, solo mostrar iconos
      return const [
        Tab(icon: Icon(Icons.people)),
        Tab(icon: Icon(Icons.pending_actions)),
        Tab(icon: Icon(Icons.calendar_today)),
      ];
    } else {
      // Para pantallas medianas, mostrar iconos con texto compacto
      return [
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 4),
              Text(
                'Clientes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth < 400 ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pending_actions, size: 20),
              const SizedBox(width: 4),
              Text(
                'Pendientes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth < 400 ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 4),
              Text(
                'Calendario',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth < 400 ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ];
    }
  }

  Widget _buildClientsTab(BuildContext context, Size screenSize) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar los clientes.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay clientes registrados.'));
        }
        
        final clients = snapshot.data!.docs;
        
        return Column(
          children: [
            // Sección del carrusel de clientes
            Container(
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              height: screenSize.height * 0.25,
              width: screenSize.width,
              child: CustomScrollView(
                scrollDirection: Axis.horizontal,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 150,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data = clients[index].data() as Map<String, dynamic>;
                          final clientName = data['username'] ?? data['email'];
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
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? Theme.of(context).colorScheme.secondary 
                                  : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : [],
                                border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                                  : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'client_$index',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 42,
                                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                                        child: profileImage == null
                                            ? const Icon(Icons.person, size: 42, color: Colors.white70)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 130,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      clientName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white :  Theme.of(context).colorScheme.tertiary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: clients.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Panel de información del cliente seleccionado
            if (selectedIndex != null)
              _buildSelectedClientPanel(context, clients[selectedIndex!]),
            
            // Botones de acción adaptables
            _buildActionButtons(context, screenSize),
          ],
        );
      },
    );
  }

  Widget _buildSelectedClientPanel(BuildContext context, DocumentSnapshot clientDoc) {
    final data = clientDoc.data() as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Detalles del Cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildClientInfoSection(context, data),
        ],
      ),
    );
  }

  Widget _buildClientInfoSection(BuildContext context, Map<String, dynamic> data) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      // Diseño compacto para pantallas pequeñas (vertical)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, 'Nombre', data['username'] ?? 'No especificado'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Email', data['email']),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Teléfono', data['phone'] ?? 'No especificado'),
        ],
      );
    } else {
      // Diseño con scroll horizontal para pantallas más grandes
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoRow(context, 'Nombre', data['username'] ?? 'No especificado'),
                const SizedBox(width: 16),
                _buildInfoRow(context, 'Email', data['email']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Teléfono', data['phone'] ?? 'No especificado'),
        ],
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, Size screenSize) {
    final isSmallScreen = screenSize.width < 360;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      width: screenSize.width - 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isSmallScreen
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'Historial',
                color: Theme.of(context).colorScheme.primary,
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
              ),
              _buildActionButton(
                context,
                icon: Icons.edit,
                label: 'Editar',
                color: Theme.of(context).colorScheme.secondary,
                onPressed: selectedIndex != null
                    ? () {
                        final clients = FirebaseFirestore.instance.collection('users').snapshots().first;
                        final userId = clients.then((value) => value.docs[selectedIndex!].id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserDetailsScreen(userId: userId.toString()),
                          ),
                        );
                      }
                    : null,
              ),
              _buildActionButton(
                context,
                icon: Icons.event_available,
                label: 'Citas',
                color: Theme.of(context).colorScheme.tertiary,
                onPressed: selectedEmail != null && selectedName != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientConfirmedAppointmentsScreen(
                              clientEmail: selectedEmail!,
                              clientName: selectedName!,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'Historial',
                color: Theme.of(context).colorScheme.primary,
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
              ),
              _buildActionButton(
                context,
                icon: Icons.edit,
                label: 'Editar',
                color: Theme.of(context).colorScheme.secondary,
                onPressed: selectedIndex != null
                    ? () {
                        // Uso de async-await para obtener correctamente el ID
                        () async {
                          final snapshot = await FirebaseFirestore.instance.collection('users').get();
                          final userId = snapshot.docs[selectedIndex!].id;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserDetailsScreen(userId: userId),
                            ),
                          );
                        }();
                      }
                    : null,
              ),
              _buildActionButton(
                context,
                icon: Icons.event_available,
                label: 'Citas',
                color: Theme.of(context).colorScheme.tertiary,
                onPressed: selectedEmail != null && selectedName != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientConfirmedAppointmentsScreen(
                              clientEmail: selectedEmail!,
                              clientName: selectedName!,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth < 360 ? double.infinity : 150.0;
    
    return Container(
      width: containerWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return isSmallScreen
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: color.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: color.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}