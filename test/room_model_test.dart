// test/models/room_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zpo/pages/room_model.dart'; 

void main() {
  group('Room Model', () {
    final roomData = {
      'name': 'Sala Konferencyjna A',
      'capacity': 10,
      'description': 'Sala z rzutnikiem',
    };
    const roomId = 'room123';

    test('Tworzenie obiektu Room z Firestore', () {
      final room = Room.fromFirestore(roomId, roomData);

      expect(room.id, roomId);
      expect(room.name, 'Sala Konferencyjna A');
      expect(room.capacity, 10);
      expect(room.description, 'Sala z rzutnikiem');
    });

    test('Tworzenie obiektu Room z niekompletnych danych', () {
      final room = Room.fromFirestore('room456', {'name': 'Sala B'});

      expect(room.id, 'room456');
      expect(room.name, 'Sala B');
      expect(room.capacity, 0); // Oczekiwana wartość domyślna
      expect(room.description, ''); // Oczekiwana wartość domyślna
    });

    test('Konwersja obiektu Room do mapy Firestore', () {
      final room = Room(
        id: roomId,
        name: 'Sala Konferencyjna A',
        capacity: 10,
        description: 'Sala z rzutnikiem',
      );

      final firestoreMap = room.toFirestore();

      expect(firestoreMap, roomData);
    });
  });
}