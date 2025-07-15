// lib/screens/rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zpo/pages/booking_model.dart';
import 'package:zpo/pages/room_booking_screen.dart';
import 'package:zpo/pages/room_model.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Room> _rooms = [];
  Map<String, Booking?> _currentBookings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      // Pobierz pokoje
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final rooms = roomsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Room(
          id: doc.id,
          name: data['name'] ?? '',
          capacity: data['capacity'] ?? 0,
          description: data['description'] ?? '',
        );
      }).toList();

      // Pobierz aktualne rezerwacje
      final now = DateTime.now();
      
      // Pobierz wszystkie rezerwacje które mogą być aktywne teraz
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('endTime', isGreaterThan: now)
          .get();

      final currentBookings = <String, Booking?>{};
      
      for (final room in rooms) {
        currentBookings[room.id] = null;
      }

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final booking = Booking(
          id: doc.id,
          roomId: data['roomId'] ?? '',
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          participants: List<String>.from(data['participants'] ?? []),
          participantNames: List<String>.from(data['participantNames'] ?? []),
          title: data['title'] ?? '',
        );

        // Sprawdź czy rezerwacja jest aktywna teraz
        if (booking.startTime.isBefore(now) && booking.endTime.isAfter(now)) {
          currentBookings[booking.roomId] = booking;
        }
      }

      setState(() {
        _rooms = rooms;
        _currentBookings = currentBookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Szczegóły rezerwacji'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tytuł: ${booking.title}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Zarezerwowane przez: ${booking.userName}'),
              SizedBox(height: 8),
              Text('Czas: ${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
              if (booking.participantNames.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Uczestnicy: ${booking.participantNames.join(', ')}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
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
        title: const Text('Wybierz pomieszczenie'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(
                  child: Text('Brak dostępnych pomieszczeń'),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final currentBooking = _currentBookings[room.id];
                      final isOccupied = currentBooking != null;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOccupied ? Colors.red : Colors.green,
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
                                    Text(
                                      room.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOccupied ? Colors.red : Colors.green,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        isOccupied ? 'ZAJĘTE' : 'WOLNE',
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
                                Text(
                                  'Pojemność: ${room.capacity} osób',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (room.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    room.description,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (isOccupied) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Zarezerwowane przez: ${currentBooking.userName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Czas: ${_formatTime(currentBooking.startTime)} - ${_formatTime(currentBooking.endTime)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (currentBooking.title.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tytuł: ${currentBooking.title}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                  if (currentBooking.participantNames.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Uczestnicy: ${currentBooking.participantNames.join(', ')}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (isOccupied) ...[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _showBookingDetails(currentBooking);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
                                          child: const Text(
                                            'Pokaż szczegóły',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => RoomBookingScreen(room: room),
                                            ),
                                          ).then((_) => _loadRooms());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text(
                                          'Zarezerwuj pokój',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}