import 'package:flutter/material.dart';
import 'package:zpo/admin/admin_service.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _adminService.getAllRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń salę'),
        content: Text('Czy na pewno chcesz usunąć salę "${room['name']}"?\n\nTa operacja usunie także wszystkie powiązane rezerwacje.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteRoom(room['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sala została usunięta'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRooms();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addRoom() {
    showDialog(
      context: context,
      builder: (context) => _AddEditRoomDialog(
        onSave: (roomData) async {
          try {
            await _adminService.addRoom(roomData);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sala została dodana'),
                backgroundColor: Colors.green,
              ),
            );
            _loadRooms();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Błąd: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _editRoom(Map<String, dynamic> room) {
    showDialog(
      context: context,
      builder: (context) => _AddEditRoomDialog(
        room: room,
        onSave: (roomData) async {
          try {
            await _adminService.updateRoom(room['id'], roomData);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sala została zaktualizowana'),
                backgroundColor: Colors.green,
              ),
            );
            _loadRooms();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Błąd: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie salami'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _addRoom,
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj salę',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: _rooms.isEmpty
                  ? const Center(
                      child: Text(
                        'Brak sal',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.meeting_room,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            room['name'] ?? 'Brak nazwy',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (room['description'] != null && room['description'].isNotEmpty)
                                            Text(
                                              room['description'],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (room['capacity'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.people,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${room['capacity']} osób',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Usunięto wyświetlanie piętra
                                  ],
                                ),
                                // Usunięto wyświetlanie wyposażenia
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _editRoom(room),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edytuj'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _deleteRoom(room),
                                      icon: const Icon(Icons.delete, size: 18),
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
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoom,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddEditRoomDialog extends StatefulWidget {
  final Map<String, dynamic>? room;
  final Function(Map<String, dynamic>) onSave;

  const _AddEditRoomDialog({
    this.room,
    required this.onSave,
  });

  @override
  State<_AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends State<_AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  // Usunięto kontrolery dla piętra i wyposażenia

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameController.text = widget.room!['name'] ?? '';
      _descriptionController.text = widget.room!['description'] ?? '';
      _capacityController.text = widget.room!['capacity']?.toString() ?? '';
      // Usunięto inicjalizację dla piętra i wyposażenia
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Dodaj salę' : 'Edytuj salę'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa sali *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa sali jest wymagana';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Pojemność (liczba osób)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final capacity = int.tryParse(value);
                    if (capacity == null || capacity <= 0) {
                      return 'Pojemność musi być liczbą większą od 0';
                    }
                  }
                  return null;
                },
              ),
              // Usunięto pola formularza dla piętra i wyposażenia
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final roomData = <String, dynamic>{
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
              };

              if (_capacityController.text.isNotEmpty) {
                roomData['capacity'] = int.parse(_capacityController.text);
              }
              // Usunięto logikę zapisu dla piętra i wyposażenia

              widget.onSave(roomData);
              Navigator.pop(context);
            }
          },
          child: Text(widget.room == null ? 'Dodaj' : 'Zapisz'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    // Usunięto dispose dla kontrolerów piętra i wyposażenia
    super.dispose();
  }
}