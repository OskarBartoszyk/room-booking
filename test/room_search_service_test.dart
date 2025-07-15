// test/services/room_search_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zpo/pages/booking_model.dart';
import 'package:zpo/pages/room_model.dart';
import 'package:zpo/pages/room_search_service.dart';
import 'package:firebase_core/firebase_core.dart';

class RoomSearchServiceTestable extends RoomSearchService {
  List<Room> mockRooms = [];
  List<Booking> mockBookings = [];

  @override
  Future<List<Room>> _getAllRooms() async {
    return mockRooms;
  }

  @override
  Future<List<Booking>> _getBookingsForPeriod(DateTime startDate, DateTime endDate) async {
    return mockBookings;
  }
}

void main(){
  group('RoomSearchService Logic', () {
    late RoomSearchServiceTestable service;
    late Room roomA;
    late Room roomB;

    setUp(() {
      service = RoomSearchServiceTestable();
      roomA = Room(id: 'A', name: 'Sala A', capacity: 5, description: '');
      roomB = Room(id: 'B', name: 'Sala B', capacity: 10, description: '');
      service.mockRooms = [roomA, roomB];
    });

    // Definiowanie stałej daty dla testów
    final testDate = DateTime(2025, 7, 21);

    test('Znajdź wolne sloty, gdy nie ma żadnych rezerwacji', () async {
      // Arrange
      service.mockBookings = [];
      final criteria = SearchCriteria(
        minCapacity: 1,
        startDate: testDate,
        endDate: testDate,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        duration: 60,
      );

      // Act
      final results = await service.searchAvailableRooms(criteria);

      // Assert
      // Oczekujemy, że dla każdej sali znajdzie jeden duży slot na cały dzień
      expect(results.length, 2);
      expect(results[0].room.id, 'B'); // Sortowanie po pojemności
      expect(results[0].startTime.hour, 8);
      expect(results[0].endTime.hour, 20);
      expect(results[1].room.id, 'A');
    });

    test('Znajdź wolne sloty z jedną rezerwacją pośrodku dnia', () async {
      // Arrange
      service.mockBookings = [
        Booking(
          id: 'booking1',
          roomId: 'A',
          userId: 'u1', userName: 'u1', title: 't1',
          startTime: DateTime(testDate.year, testDate.month, testDate.day, 12, 0),
          endTime: DateTime(testDate.year, testDate.month, testDate.day, 13, 0),
          participants: [], participantNames: [],
        )
      ];
      final criteria = SearchCriteria(
        minCapacity: 1,
        startDate: testDate,
        endDate: testDate,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        duration: 60,
      );

      // Act
      final results = await service.searchAvailableRooms(criteria);

      // Assert
      // Oczekujemy 3 slotów: cała sala B, sala A przed rezerwacją, sala A po rezerwacji
      expect(results.length, 3);

      final roomASlots = results.where((s) => s.room.id == 'A').toList();
      expect(roomASlots.length, 2);
      expect(roomASlots[0].startTime.hour, 8);
      expect(roomASlots[0].endTime.hour, 12);
      expect(roomASlots[1].startTime.hour, 13);
      expect(roomASlots[1].endTime.hour, 20);
    });

    test('Nie znajduje slotu, gdy czas trwania jest za długi', () async {
      // Arrange
      service.mockBookings = [
        Booking(
          id: 'booking1',
          roomId: 'A',
          userId: 'u1', userName: 'u1', title: 't1',
          startTime: DateTime(testDate.year, testDate.month, testDate.day, 8, 0),
          endTime: DateTime(testDate.year, testDate.month, testDate.day, 18, 0),
          participants: [], participantNames: [],
        )
      ];
      // Szukamy slotu na 3 godziny, ale wolne są tylko 2 godziny na końcu dnia
      final criteria = SearchCriteria(
        minCapacity: 1,
        startDate: testDate,
        endDate: testDate,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        duration: 180, // 3 godziny
      );

      // Act
      final results = await service.searchAvailableRooms(criteria);

      // Assert
      // Oczekujemy tylko jednego slotu dla sali B, która jest całkowicie wolna
      final roomASlots = results.where((s) => s.room.id == 'A').toList();
      expect(roomASlots.isEmpty, isTrue);
      expect(results.length, 1);
      expect(results[0].room.id, 'B');
    });

     test('Filtrowanie po pojemności', () async {
      // Arrange
      service.mockBookings = [];
      final criteria = SearchCriteria(
        minCapacity: 8, // Sala A ma 5, Sala B ma 10
        startDate: testDate,
        endDate: testDate,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        duration: 60,
      );

      // Act
      final results = await service.searchAvailableRooms(criteria);

      // Assert
      // Powinna zostać znaleziona tylko sala B
      expect(results.length, 1);
      expect(results[0].room.id, 'B');
    });
  });
}