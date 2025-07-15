import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zpo/pages/booking_model.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  Map<String, String> _roomNames = {};
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, upcoming, past
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Pobierz wszystkie rezerwacje
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .orderBy('startTime', descending: true)
          .get();

      // Pobierz nazwy sal
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final roomNames = <String, String>{};
      for (final doc in roomsSnapshot.docs) {
        roomNames[doc.id] = doc.data()['name'] ?? 'Nieznana sala';
      }

      final bookings = bookingsSnapshot.docs.map((doc) {
        return Booking.fromFirestore(doc.id, doc.data());
      }).toList();

      setState(() {
        _bookings = bookings;
        _roomNames = roomNames;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
      
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

  void _applyFilters() {
    final now = DateTime.now();
    List<Booking> filtered = _bookings;

    // Filtruj według statusu
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((booking) => 
          booking.startTime.isBefore(now) && booking.endTime.isAfter(now)
        ).toList();
        break;
      case 'upcoming':
        filtered = filtered.where((booking) => 
          booking.startTime.isAfter(now)
        ).toList();
        break;
      case 'past':
        filtered = filtered.where((booking) => 
          booking.endTime.isBefore(now)
        ).toList();
        break;
    }

    // Filtruj według wyszukiwania
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        final roomName = _roomNames[booking.roomId]?.toLowerCase() ?? '';
        return booking.title.toLowerCase().contains(_searchQuery) ||
               booking.userName.toLowerCase().contains(_searchQuery) ||
               roomName.contains(_searchQuery) ||
               booking.participantNames.any((name) => 
                 name.toLowerCase().contains(_searchQuery)
               );
      }).toList();
    }

    setState(() {
      _filteredBookings = filtered;
    });
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezerwacja została usunięta'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas usuwania: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usuń rezerwację'),
          content: Text('Czy na pewno chcesz usunąć rezerwację "${booking.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBooking(booking.id);
              },
              child: const Text('Usuń', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Booking booking) {
    final titleController = TextEditingController(text: booking.title);
    DateTime selectedDate = booking.startTime;
    TimeOfDay startTime = TimeOfDay.fromDateTime(booking.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(booking.endTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edytuj rezerwację'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tytuł spotkania',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Data
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
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
                            Text('Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Godzina rozpoczęcia
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startTime = picked;
                          });
                        }
                      },
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
                            Text('Początek: ${startTime.format(context)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Godzina zakończenia
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endTime = picked;
                          });
                        }
                      },
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
                            Text('Koniec: ${endTime.format(context)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateBooking(booking.id, titleController.text, selectedDate, startTime, endTime);
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateBooking(String bookingId, String title, DateTime date, TimeOfDay startTime, TimeOfDay endTime) async {
    try {
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Czas końcowy musi być późniejszy niż początkowy'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'title': title,
        'startTime': startDateTime,
        'endTime': endDateTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezerwacja została zaktualizowana'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas aktualizacji: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(booking.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Sala:', _roomNames[booking.roomId] ?? 'Nieznana sala'),
                _buildDetailRow('Organizator:', booking.userName),
                _buildDetailRow('Data:', '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}'),
                _buildDetailRow('Godzina:', '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
                if (booking.participantNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Uczestnicy:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...booking.participantNames.map((name) => 
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text('• $name'),
                    ),
                  ),
                ],
              ],
            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(Booking booking) {
    final now = DateTime.now();
    if (booking.startTime.isBefore(now) && booking.endTime.isAfter(now)) {
      return 'AKTYWNE';
    } else if (booking.startTime.isAfter(now)) {
      return 'NADCHODZĄCE';
    } else {
      return 'ZAKOŃCZONE';
    }
  }

  Color _getStatusColor(Booking booking) {
    final now = DateTime.now();
    if (booking.startTime.isBefore(now) && booking.endTime.isAfter(now)) {
      return Colors.green;
    } else if (booking.startTime.isAfter(now)) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzaj rezerwacjami'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtry i wyszukiwanie
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Pasek wyszukiwania
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Szukaj po tytule, organizatorze, sali...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filtry statusu
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Wszystkie', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aktywne', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nadchodzące', 'upcoming'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Zakończone', 'past'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista rezerwacji
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Brak rezerwacji',
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
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            final roomName = _roomNames[booking.roomId] ?? 'Nieznana sala';
                            final statusColor = _getStatusColor(booking);
                            final statusText = _getStatusText(booking);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor, width: 1),
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
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
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
                                          Text(roomName),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(booking.userName)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('${_formatDateTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
                                        ],
                                      ),
                                      
                                      if (booking.participantNames.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.people, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Uczestnicy: ${booking.participantNames.join(', ')}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showBookingDetails(booking),
                                            icon: const Icon(Icons.info_outline, size: 16),
                                            label: const Text('Szczegóły'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _showEditDialog(booking),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Edytuj'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _showDeleteDialog(booking),
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Usuń'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilters();
      },
      selectedColor: Colors.orange.withOpacity(0.3),
      checkmarkColor: Colors.orange,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}