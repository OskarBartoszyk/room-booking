
import 'package:flutter/material.dart';
import 'package:zpo/admin/admin_service.dart';
import 'package:zpo/admin/manage_bookings_screen.dart';
import 'package:zpo/admin/manage_users_screen.dart';
import 'package:zpo/admin/manage_rooms_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  Map<String, int> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _adminService.getStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administratora'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Panel Administratora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Zarządzaj systemem rezerwacji sal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statystyki
                    const Text(
                      'Statystyki systemu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Użytkownicy',
                          _statistics['totalUsers']?.toString() ?? '0',
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Sale',
                          _statistics['totalRooms']?.toString() ?? '0',
                          Icons.meeting_room,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Rezerwacje',
                          _statistics['totalBookings']?.toString() ?? '0',
                          Icons.event,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Aktywne',
                          _statistics['activeBookings']?.toString() ?? '0',
                          Icons.access_time,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Zarządzanie
                    const Text(
                      'Zarządzanie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildManagementCard(
                      'Użytkownicy',
                      'Zarządzaj kontami użytkowników',
                      Icons.people,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageUsersScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildManagementCard(
                      'Sale',
                      'Dodawaj, edytuj i usuwaj sale',
                      Icons.meeting_room,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageRoomsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildManagementCard(
                      'Rezerwacje',
                      'Przeglądaj i zarządzaj rezerwacjami',
                      Icons.event,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageBookingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}