import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/screens/admin/admin.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:guerrero_barber_app/screens/admin/user_details_screen.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';

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

  // Controlador para el ScrollView principal
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileImage();
    DeviceTokenService().registerDeviceToken();
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
        backgroundColor:
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
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

  void _showTodayAppointmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          width: 400,
          height: 500,
          child: _TodayAppointmentsList(),
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
                      MaterialPageRoute(
                          builder: (_) => const AdminSettingsScreen()),
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
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 28)
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 150,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data =
                              clients[index].data() as Map<String, dynamic>;
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
                                    : Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : [],
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 3)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'client_${clients[index].id}',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 42,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.3),
                                        backgroundImage: profileImage != null
                                            ? NetworkImage(profileImage)
                                            : null,
                                        child: profileImage == null
                                            ? const Icon(Icons.person,
                                                size: 42, color: Colors.white70)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 130,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Text(
                                      clientName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .tertiary,
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

  Widget _buildSelectedClientPanel(
      BuildContext context, DocumentSnapshot clientDoc) {
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

  Widget _buildClientInfoSection(
      BuildContext context, Map<String, dynamic> data) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      // Diseño compacto para pantallas pequeñas (vertical)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
              context, 'Nombre', data['username'] ?? 'No especificado'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Email', data['email']),
          const SizedBox(height: 8),
          _buildInfoRow(
              context, 'Teléfono', data['phone'] ?? 'No especificado'),
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
                _buildInfoRow(
                    context, 'Nombre', data['username'] ?? 'No especificado'),
                const SizedBox(width: 16),
                _buildInfoRow(context, 'Email', data['email']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              context, 'Teléfono', data['phone'] ?? 'No especificado'),
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
                _buildHistoryButton(context),
                _buildEditButton(context),
                _buildAppointmentsButton(context),
                const SizedBox(height: 8),
                _buildTodayAppointmentsButton(context),
                const SizedBox(height: 8),
                _buildSendGlobalMessageButton(context),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHistoryButton(context, isExpanded: true),
                    _buildEditButton(context, isExpanded: true),
                    _buildAppointmentsButton(context, isExpanded: true),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTodayAppointmentsButton(context),
                const SizedBox(height: 8),
                _buildSendGlobalMessageButton(context),
              ],
            ),
    );
  }

  Widget _buildSendGlobalMessageButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.campaign),
        label: const Text('Enviar Mensaje Global'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent, // A distinct color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        onPressed: () => _showSendGlobalMessageDialog(context),
      ),
    );
  }

  void _showSendGlobalMessageDialog(BuildContext context) {
    showDialog(
        context: context, builder: (context) => const _SendGlobalMessageDialog());
  }

  Widget _buildHistoryButton(BuildContext context, {bool isExpanded = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final widget = ElevatedButton(
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
      ),
      child: isSmallScreen
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Historial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, color: Colors.white),
                const SizedBox(height: 6),
                const Text(
                  'Historial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );

    return isExpanded
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: widget,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: widget,
            ),
          );
  }

  Widget _buildEditButton(BuildContext context, {bool isExpanded = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final widget = ElevatedButton(
      onPressed: selectedIndex != null
          ? () {
              // Uso de función anónima async para obtener correctamente el ID
              () async {
                final snapshot =
                    await FirebaseFirestore.instance.collection('users').get();
                final userId = snapshot.docs[selectedIndex!].id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserDetailsScreen(userId: userId),
                  ),
                );
              }();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.secondary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
      ),
      child: isSmallScreen
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, color: Colors.white),
                const SizedBox(height: 6),
                const Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );

    return isExpanded
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: widget,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: widget,
            ),
          );
  }

  Widget _buildAppointmentsButton(BuildContext context,
      {bool isExpanded = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final widget = ElevatedButton(
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.tertiary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
      ),
      child: isSmallScreen
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_available, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Citas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_available, color: Colors.white),
                const SizedBox(height: 6),
                const Text(
                  'Citas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );

    return isExpanded
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: widget,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: widget,
            ),
          );
  }

  Widget _buildTodayAppointmentsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.today),
        label: const Text('Citas para hoy'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showTodayAppointmentsDialog(context),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth < 360 ? double.infinity : 150.0;

    return SizedBox(
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
}

class _TodayAppointmentsList extends StatefulWidget {
  @override
  State<_TodayAppointmentsList> createState() => _TodayAppointmentsListState();
}

class _TodayAppointmentsListState extends State<_TodayAppointmentsList> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 2));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Citas para hoy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('status', isEqualTo: 'approved')
                  .where('dateTime',
                      isGreaterThanOrEqualTo: startOfDay.toIso8601String())
                  .where('dateTime', isLessThan: endOfDay.toIso8601String())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay citas para hoy.'));
                }
                final appointments = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final data =
                        appointments[index].data() as Map<String, dynamic>;
                    final appointmentId = appointments[index].id;
                    final dateTime = DateTime.parse(data['dateTime']);
                    final userEmail = data['userEmail'];
                    final status = data['status'] ?? '';
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: userEmail)
                          .limit(1)
                          .get(),
                      builder: (context, userSnapshot) {
                        String displayName = "";
                        if (userSnapshot.hasData &&
                            userSnapshot.data != null &&
                            userSnapshot.data!.docs.isNotEmpty) {
                          final userData = userSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          displayName = userData['username'] ?? userEmail;
                        }
                        if (!mounted) {
                          return const CircularProgressIndicator();
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('Cliente: $displayName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Servicio: ${data['service']}'),
                                Text(
                                    'Hora: ${TimeOfDay.fromDateTime(dateTime).format(context)}'),
                                Text('Estado: ${status == 'approved' ? 'Aprobada' : status}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: status == 'no_show'
                                      ? null
                                      : () => _markNoShow(
                                          context, appointmentId, data),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markNoShow(BuildContext context, String appointmentId,
      Map<String, dynamic> appointmentData) async {
    try {
      final userEmail = appointmentData['userEmail'];
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) return;
      final userDoc = userQuery.docs.first;
      final userRef = userDoc.reference;
      final userData = userDoc.data();
      int noShowCount = userData['noShowCount'] ?? 0;
      noShowCount++;
      DateTime? blockUntil;
      String notificationBody = '';
      if (noShowCount >= 4) {
        blockUntil = DateTime.now().add(const Duration(days: 120));
        notificationBody =
            'Has faltado a 4 citas y no podrás reservar durante 4 meses.';
      } else {
        final restantes = 4 - noShowCount;
        notificationBody =
            'Has faltado a una cita. Si faltas $restantes vez/veces más, no podrás reservar durante 4 meses.';
      }
      await userRef.update({
        'noShowCount': noShowCount,
        if (blockUntil != null) 'blockUntil': blockUntil.toIso8601String(),
      });
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'no_show'});
      final userId = userDoc.id;
      final userToken = await DeviceTokenService().getUserLastDeviceToken(userId);
      if (userToken != null && userToken != '') {
        final notificationsService = NotificationsService();
        await notificationsService.sendNotification(
          token: userToken,
          title: 'Falta a la cita',
          body: notificationBody,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falta registrada y usuario notificado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar la falta: $e')),
        );
      }
    }
  }
}

class _SendGlobalMessageDialog extends StatefulWidget {
  const _SendGlobalMessageDialog();

  @override
  State<_SendGlobalMessageDialog> createState() =>
      _SendGlobalMessageDialogState();
}

class _SendGlobalMessageDialogState extends State<_SendGlobalMessageDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final message = _messageController.text.trim();

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final notificationsService = NotificationsService();
      final deviceTokenService = DeviceTokenService();
      int successCount = 0;
      int failureCount = 0;
      List<String> tokensToSend = [];

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        // Assuming DeviceTokenService has a method to get the user's last device token
        final userToken =
            await deviceTokenService.getUserLastDeviceToken(userId);
        if (userToken != null && userToken.isNotEmpty) {
          tokensToSend.add(userToken);
        } else {
          // Optional: Log users for whom no token was found
          // ignore: avoid_print
          print('No device token found for user $userId');
        }
      }

      if (tokensToSend.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No hay clientes con tokens para notificar.')),
          );
        }
        return;
      }

      for (final token in tokensToSend) {
        try {
          await notificationsService.sendNotification(
            token: token,
            title: 'Mensaje de Barbería Guerrero', // Customize title as needed
            body: message,
          );
          successCount++;
        } catch (e) {
          // ignore: avoid_print
          print('Failed to send notification to token $token: $e');
          failureCount++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Mensaje enviado a $successCount clientes. Fallos: $failureCount.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar envío de mensajes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enviar Mensaje Global a Clientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Escribe tu mensaje aquí...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El mensaje no puede estar vacío.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _isSending
                        ? Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text('Enviar'),
                    onPressed: _isSending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
