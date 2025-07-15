// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zpo/pages/booking_model.dart';
import 'package:zpo/pages/room_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Room> _rooms = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  DateTime _selectedWeek = DateTime.now();
  
  // Kolory dla różnych rezerwacji
  final List<Color> _bookingColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pobierz pokoje
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final rooms = roomsSnapshot.docs.map((doc) {
        return Room.fromFirestore(doc.id, doc.data());
      }).toList();

      // Pobierz rezerwacje dla aktualnego tygodnia
      final weekStart = _getWeekStart(_selectedWeek);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('startTime', isGreaterThanOrEqualTo: weekStart)
          .where('startTime', isLessThan: weekEnd)
          .orderBy('startTime')
          .get();

      final bookings = bookingsSnapshot.docs.map((doc) {
        return Booking.fromFirestore(doc.id, doc.data());
      }).toList();

      setState(() {
        _rooms = rooms;
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    final weekStart = _getWeekStart(_selectedWeek);
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
    _loadData();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
    _loadData();
  }

  void _goToToday() {
    setState(() {
      _selectedWeek = DateTime.now();
    });
    _loadData();
  }

  Color _getBookingColor(String bookingId) {
    final hash = bookingId.hashCode;
    return _bookingColors[hash.abs() % _bookingColors.length];
  }

  Widget _buildTimeSlot(int hour) {
    return Container(
      height: 60,
      alignment: Alignment.topCenter,
      child: Text(
        '${hour.toString().padLeft(2, '0')}:00',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBookingBlock(Booking booking, DateTime day) {
    final startHour = booking.startTime.hour;
    final startMinute = booking.startTime.minute;
    final endHour = booking.endTime.hour;
    final endMinute = booking.endTime.minute;
    
    final duration = booking.endTime.difference(booking.startTime);
    final durationInMinutes = duration.inMinutes;
    final height = (durationInMinutes / 60) * 60.0; // 60px per hour
    
    final topOffset = (startMinute / 60) * 60.0;
    
    return Positioned(
      top: topOffset,
      left: 2,
      right: 2,
      height: height,
      child: GestureDetector(
        onTap: () => _showBookingDetails(booking),
        child: Container(
          decoration: BoxDecoration(
            color: _getBookingColor(booking.id).withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getBookingColor(booking.id), width: 1),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 30) ...[
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
              if (height > 50) ...[
                const SizedBox(height: 2),
                Text(
                  booking.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayColumn(DateTime day) {
    final dayBookings = _bookings
        .where((booking) => 
            booking.startTime.year == day.year &&
            booking.startTime.month == day.month &&
            booking.startTime.day == day.day)
        .toList();

    return Expanded(
      child: Column(
        children: [
          // Header dnia
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  _getDayName(day.weekday),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isToday(day) ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isToday(day) ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Godziny i rezerwacje
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 24 * 60, // 24 hours * 60px per hour
                child: Stack(
                  children: [
                    // Linie godzin
                    ...List.generate(24, (hour) {
                      return Positioned(
                        top: hour * 60.0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      );
                    }),
                    // Rezerwacje
                    ...dayBookings.map((booking) {
                      final hourOffset = booking.startTime.hour * 60.0;
                      return Positioned(
                        top: hourOffset,
                        left: 0,
                        right: 0,
                        child: _buildBookingBlock(booking, day),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Pn', 'Wt', 'Śr', 'Czw', 'Pt', 'Sb', 'Nd'];
    return days[weekday - 1];
  }

  bool _isToday(DateTime day) {
    final today = DateTime.now();
    return day.year == today.year &&
           day.month == today.month &&
           day.day == today.day;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingDetails(Booking booking) {
    final room = _rooms.firstWhere(
      (r) => r.id == booking.roomId,
      orElse: () => Room(id: '', name: 'Nieznana sala', capacity: 0, description: ''),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(booking.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.room, 'Sala', room.name),
              _buildDetailRow(Icons.person, 'Organizator', booking.userName),
              _buildDetailRow(Icons.access_time, 'Czas', 
                '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
              _buildDetailRow(Icons.calendar_today, 'Data', 
                '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}'),
              if (booking.participantNames.isNotEmpty)
                _buildDetailRow(Icons.people, 'Uczestnicy', 
                  booking.participantNames.join(', ')),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendarz rezerwacji'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Dziś',
          ),
        ],
      ),
      body: Column(
        children: [
          // Nawigacja tygodnia
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousWeek,
                ),
                Text(
                  '${_formatWeekRange()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Kalendarz
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // Kolumna z godzinami
                      Container(
                        width: 60,
                        child: Column(
                          children: [
                            const SizedBox(height: 80), // Offset dla header
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: List.generate(24, (hour) {
                                    return _buildTimeSlot(hour);
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Kolumny z dniami
                      Expanded(
                        child: Row(
                          children: _getWeekDays().map((day) {
                            return _buildDayColumn(day);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatWeekRange() {
    final weekStart = _getWeekStart(_selectedWeek);
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
  }
}