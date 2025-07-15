// lib/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zpo/pages/booking_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Booking> _bookings = [];
  Map<String, String> _roomNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('Loading bookings for user: ${currentUser.uid}');

      // Pobierz rezerwacje użytkownika
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('startTime', descending: false)
          .get();

      print('Found ${bookingsSnapshot.docs.length} bookings');

      // Pobierz nazwy sal
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final roomNames = <String, String>{};
      for (final doc in roomsSnapshot.docs) {
        roomNames[doc.id] = doc.data()['name'] ?? 'Nieznana sala';
      }

      final bookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing booking: ${doc.id} - ${data}');
        
        return Booking.fromFirestore(doc.id, data);
      }).toList();

      setState(() {
        _bookings = bookings;
        _roomNames = roomNames;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Pokaż error użytkownikowi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania rezerwacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezerwacja została anulowana'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings(); // Odśwież listę
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas anulowania: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Anuluj rezerwację'),
          content: Text('Czy na pewno chcesz anulować rezerwację "${booking.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nie'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(booking.id);
              },
              child: const Text('Tak', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezerwacje'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nie masz jeszcze żadnych rezerwacji',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      final roomName = _roomNames[booking.roomId] ?? 'Nieznana sala';
                      final now = DateTime.now();
                      final isUpcoming = booking.startTime.isAfter(now);
                      final isActive = booking.startTime.isBefore(now) && booking.endTime.isAfter(now);

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive 
                                  ? Colors.green 
                                  : isUpcoming 
                                      ? Colors.blue 
                                      : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        booking.title,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive 
                                            ? Colors.green 
                                            : isUpcoming 
                                                ? Colors.blue 
                                                : Colors.grey,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        isActive 
                                            ? 'AKTYWNE' 
                                            : isUpcoming 
                                                ? 'NADCHODZĄCE' 
                                                : 'ZAKOŃCZONE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.room, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      roomName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatDateTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (booking.participantNames.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.people, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Uczestnicy: ${booking.participantNames.join(', ')}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (isUpcoming) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showCancelDialog(booking),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Anuluj'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}