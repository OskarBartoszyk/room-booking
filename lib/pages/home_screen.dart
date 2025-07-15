// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:zpo/auth/auth_service.dart';
import 'package:zpo/pages/my_booking_screen.dart';
import 'package:zpo/pages/room_search_widget.dart';
import 'package:zpo/pages/rooms_screen.dart';
import 'package:zpo/pages/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String? _firstName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        setState(() {
          _firstName = userData['firstName'] ?? 'Użytkowniku';
          _isLoading = false;
        });
      } else {
        setState(() {
          _firstName = 'Użytkowniku';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _firstName = 'Użytkowniku';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Rezerwacji Sal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Witaj, $_firstName!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jak się dziś masz? ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Szybkie akcje
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Szybkie akcje',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.add, color: Colors.blue),
                            title: const Text('Nowa rezerwacja'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RoomsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.list, color: Colors.blue),
                            title: const Text('Moje rezerwacje'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const MyBookingsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.calendar_today, color: Colors.blue),
                            title: const Text('Kalendarz rezerwacji'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CalendarScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Widget wyszukiwania sal
                  const SizedBox(
                    width: double.infinity,
                    child: RoomSearchWidget(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sekcja kalendarza - podgląd
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kalendarz',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CalendarScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Zobacz wszystkie'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_view_week,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Podgląd kalendarza',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kliknij "Zobacz wszystkie" aby otworzyć\npełny kalendarz rezerwacji',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const CalendarScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text('Otwórz kalendarz'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dodatkowe sekcje (opcjonalne)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Informacje',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Użyj wyszukiwarki sal powyżej, aby znaleźć dostępne sale w preferowanym terminie. Możesz również przeglądać aktualnie dostępne sale i sprawdzać kalendarz rezerwacji.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}