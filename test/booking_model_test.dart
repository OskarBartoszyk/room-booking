// test/models/booking_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zpo/pages/booking_model.dart'; // Upewnij się, że ścieżka jest poprawna

void main() {
  group('Booking Model', () {
    final startTime = DateTime(2025, 7, 20, 10, 0);
    final endTime = DateTime(2025, 7, 20, 11, 0);

    final bookingData = {
      'roomId': 'room1',
      'userId': 'user1',
      'userName': 'Jan Kowalski',
      'title': 'Spotkanie projektowe',
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'participants': ['user2', 'user3'],
      'participantNames': ['Anna Nowak', 'Piotr Wiśniewski'],
    };
    const bookingId = 'booking123';

    test('Tworzenie obiektu Booking z Firestore', () {
      final booking = Booking.fromFirestore(bookingId, bookingData);

      expect(booking.id, bookingId);
      expect(booking.roomId, 'room1');
      expect(booking.userId, 'user1');
      expect(booking.userName, 'Jan Kowalski');
      expect(booking.title, 'Spotkanie projektowe');
      expect(booking.startTime, startTime);
      expect(booking.endTime, endTime);
      expect(booking.participants, ['user2', 'user3']);
      expect(booking.participantNames, ['Anna Nowak', 'Piotr Wiśniewski']);
    });

    test('Konwersja obiektu Booking do mapy Firestore', () {
      final booking = Booking(
        id: bookingId,
        roomId: 'room1',
        userId: 'user1',
        userName: 'Jan Kowalski',
        title: 'Spotkanie projektowe',
        startTime: startTime,
        endTime: endTime,
        participants: ['user2', 'user3'],
        participantNames: ['Anna Nowak', 'Piotr Wiśniewski'],
      );

      final firestoreMap = booking.toFirestore();

      // W toFirestore nie ma konwersji na Timestamp, więc porównujemy bez tego pola
      expect(firestoreMap['roomId'], 'room1');
      expect(firestoreMap['userName'], 'Jan Kowalski');
      expect(firestoreMap['participants'], ['user2', 'user3']);
      // Porównanie dat
      expect(firestoreMap['startTime'], startTime);
      expect(firestoreMap['endTime'], endTime);
    });
  });
}