// lib/models/room_model.dart
class Room {
  final String id;
  final String name;
  final int capacity;
  final String description;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.description,
  });

  factory Room.fromFirestore(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 0,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'capacity': capacity,
      'description': description,
    };
  }
}