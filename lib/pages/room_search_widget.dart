// lib/widgets/room_search_widget.dart
import 'package:flutter/material.dart';
import 'package:zpo/pages/room_booking_screen.dart';
import 'package:zpo/pages/room_search_service.dart';

class RoomSearchWidget extends StatefulWidget {
  const RoomSearchWidget({super.key});

  @override
  State<RoomSearchWidget> createState() => _RoomSearchWidgetState();
}

class _RoomSearchWidgetState extends State<RoomSearchWidget> {
  final RoomSearchService _searchService = RoomSearchService();
  final TextEditingController _nameController = TextEditingController();
  
  int _minCapacity = 1;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _duration = 60; // minuty
  
  List<AvailableSlot> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentlyAvailable();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentlyAvailable() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final availableRooms = await _searchService.findCurrentlyAvailableRooms();
      final slots = availableRooms.map((room) => AvailableSlot(
        room: room,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        isFullyAvailable: true,
      )).toList();
      
      setState(() {
        _searchResults = slots;
        _showResults = true;
      });
    } catch (e) {
      print('Error loading currently available rooms: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data końcowa musi być późniejsza niż początkowa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final criteria = SearchCriteria(
        minCapacity: _minCapacity,
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime,
        endTime: _endTime,
        nameFilter: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        duration: _duration,
      );

      final results = await _searchService.searchAvailableRooms(criteria);
      
      setState(() {
        _searchResults = results;
        _showResults = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas wyszukiwania: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
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
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Wyszukiwarka sal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Szybkie filtry
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa sali',
                      prefixIcon: Icon(Icons.room),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: _minCapacity,
                    decoration: const InputDecoration(
                      labelText: 'Min. osób',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(20, (index) => index + 1)
                        .map((capacity) => DropdownMenuItem(
                              value: capacity,
                              child: Text(capacity.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _minCapacity = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Czas trwania
            Row(
              children: [
                const Text('Czas trwania: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: _duration,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 godzina')),
                      DropdownMenuItem(value: 90, child: Text('1.5 godziny')),
                      DropdownMenuItem(value: 120, child: Text('2 godziny')),
                      DropdownMenuItem(value: 180, child: Text('3 godziny')),
                      DropdownMenuItem(value: 240, child: Text('4 godziny')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _duration = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Zaawansowane filtry (zwijane)
            ExpansionTile(
              title: const Text('Zaawansowane filtry'),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                // Daty
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Od: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Do: ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Godziny
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Od: ${_startTime.format(context)}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Do: ${_endTime.format(context)}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Przyciski
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: constraints.maxWidth * 0.6,
                        child: ElevatedButton.icon(
                          onPressed: _isSearching ? null : _performSearch,
                          icon: _isSearching 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_isSearching ? 'Szukam...' : 'Szukaj'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        width: constraints.maxWidth * 0.4,
                        child: ElevatedButton.icon(
                          onPressed: _loadCurrentlyAvailable,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Dostępne teraz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Wyniki wyszukiwania
            if (_showResults) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Wyniki wyszukiwania (${_searchResults.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showResults = false;
                        });
                      },
                      child: const Text('Ukryj'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Brak dostępnych sal spełniających kryteria',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final slot = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              slot.room.capacity.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(slot.room.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pojemność: ${slot.room.capacity} osób'),
                              Text(
                                'Dostępne: ${_formatDateTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              if (slot.room.description.isNotEmpty)
                                Text(
                                  slot.room.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RoomBookingScreen(room: slot.room),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Rezerwuj', style: TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
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