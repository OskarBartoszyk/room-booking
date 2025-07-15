// lib/screens/room_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zpo/pages/room_model.dart';

class RoomBookingScreen extends StatefulWidget {
  final Room room;

  const RoomBookingScreen({super.key, required this.room});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _selectedParticipants = [];
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final currentUserId = _auth.currentUser?.uid;
      
      final users = usersSnapshot.docs
          .where((doc) => doc.id != currentUserId) // Wykluczamy aktualnego użytkownika
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Automatycznie ustaw czas końcowy na godzinę później
          _endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _toggleParticipant(Map<String, dynamic> user) {
    setState(() {
      if (_selectedParticipants.any((p) => p['id'] == user['id'])) {
        _selectedParticipants.removeWhere((p) => p['id'] == user['id']);
      } else {
        if (_selectedParticipants.length < widget.room.capacity - 1) {
          _selectedParticipants.add(user);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maksymalna liczba uczestników: ${widget.room.capacity - 1}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<bool> _checkAvailability() async {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: widget.room.id)
          .where('startTime', isLessThan: endDateTime)
          .get();

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final existingStart = (data['startTime'] as Timestamp).toDate();
        final existingEnd = (data['endTime'] as Timestamp).toDate();

        // Sprawdź czy nowa rezerwacja koliduje z istniejącą
        if (startDateTime.isBefore(existingEnd) && endDateTime.isAfter(existingStart)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  Future<void> _bookRoom() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podaj tytuł spotkania'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endTime.hour < _startTime.hour || 
        (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Czas końcowy musi być późniejszy niż początkowy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final isAvailable = await _checkAvailability();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sala jest zajęta w wybranym terminie'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isBooking = false;
        });
        return;
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}';

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final participantIds = _selectedParticipants.map((p) => p['id'] as String).toList();
      final participantNames = _selectedParticipants
          .map((p) => '${p['firstName']} ${p['lastName']}')
          .toList();

      await _firestore.collection('bookings').add({
        'roomId': widget.room.id,
        'userId': currentUser.uid,
        'userName': userName.trim(),
        'title': _titleController.text,
        'startTime': startDateTime,
        'endTime': endDateTime,
        'participants': participantIds,
        'participantNames': participantNames,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezerwacja została utworzona pomyślnie!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error booking room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas rezerwacji: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rezerwacja - ${widget.room.name}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informacje o sali
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.room.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Pojemność: ${widget.room.capacity} osób'),
                                if (widget.room.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(widget.room.description),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Formularz rezerwacji
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Szczegóły rezerwacji',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Tytuł spotkania
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tytuł spotkania',
                                    prefixIcon: Icon(Icons.title),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Data
                                InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 12),
                                        const Text('Data: '),
                                        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Godzina rozpoczęcia
                                InkWell(
                                  onTap: () => _selectTime(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time),
                                        const SizedBox(width: 12),
                                        const Text('Początek: '),
                                        Text(_startTime.format(context)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Godzina zakończenia
                                InkWell(
                                  onTap: () => _selectTime(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_filled),
                                        const SizedBox(width: 12),
                                        const Text('Koniec: '),
                                        Text(_endTime.format(context)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Lista uczestników - SIMPLIFIED
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uczestnicy (${_selectedParticipants.length}/${widget.room.capacity - 1})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                if (_allUsers.isEmpty)
                                  const Text('Brak dostępnych użytkowników')
                                else
                                  ..._allUsers.map((user) {
                                    final isSelected = _selectedParticipants
                                        .any((p) => p['id'] == user['id']);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            child: Text(
                                              user['firstName'].isNotEmpty 
                                                  ? user['firstName'][0].toUpperCase()
                                                  : '?',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${user['firstName']} ${user['lastName']}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  user['email'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 70,
                                            child: TextButton(
                                              onPressed: () => _toggleParticipant(user),
                                              style: TextButton.styleFrom(
                                                backgroundColor: isSelected ? Colors.red : Colors.blue,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                              child: Text(
                                                isSelected ? 'Usuń' : 'Dodaj',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  
                  const SizedBox(height: 16),
                  // Przycisk rezerwacji
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _bookRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: _isBooking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Zarezerwuj salę',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}