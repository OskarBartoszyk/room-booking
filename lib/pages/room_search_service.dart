// lib/services/room_search_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zpo/pages/room_model.dart';
import 'package:zpo/pages/booking_model.dart';

class SearchCriteria {
  final int minCapacity;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? nameFilter;
  final int duration; // w minutach

  SearchCriteria({
    required this.minCapacity,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.nameFilter,
    required this.duration,
  });
}

class AvailableSlot {
  final Room room;
  final DateTime startTime;
  final DateTime endTime;
  final bool isFullyAvailable;

  AvailableSlot({
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.isFullyAvailable,
  });
}

class RoomSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Główny algorytm wyszukiwania wolnych sal
  Future<List<AvailableSlot>> searchAvailableRooms(SearchCriteria criteria) async {
    try {
      // Krok 1: Pobierz wszystkie sale
      final rooms = await _getAllRooms();
      
      // Krok 2: Filtruj sale według podstawowych kryteriów
      final filteredRooms = _filterRoomsByBasicCriteria(rooms, criteria);
      
      // Krok 3: Pobierz rezerwacje dla okresu wyszukiwania
      final bookings = await _getBookingsForPeriod(
        criteria.startDate,
        criteria.endDate,
      );
      
      // Krok 4: Znajdź dostępne sloty dla każdej sali
      final availableSlots = <AvailableSlot>[];
      
      for (final room in filteredRooms) {
        final roomBookings = bookings.where((b) => b.roomId == room.id).toList();
        final slots = _findAvailableSlots(room, roomBookings, criteria);
        availableSlots.addAll(slots);
      }
      
      // Krok 5: Sortuj wyniki według preferencji
      availableSlots.sort((a, b) => _compareSlots(a, b, criteria));
      
      return availableSlots;
    } catch (e) {
      print('Error searching rooms: $e');
      return [];
    }
  }

  /// Pobierz wszystkie sale z bazy danych
  Future<List<Room>> _getAllRooms() async {
    final snapshot = await _firestore.collection('rooms').get();
    return snapshot.docs.map((doc) {
      return Room.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  /// Filtruj sale według podstawowych kryteriów (pojemność, nazwa)
  List<Room> _filterRoomsByBasicCriteria(List<Room> rooms, SearchCriteria criteria) {
    return rooms.where((room) {
      // Sprawdź pojemność
      if (room.capacity < criteria.minCapacity) {
        return false;
      }
      
      // Sprawdź filtr nazwy (jeśli podany)
      if (criteria.nameFilter != null && criteria.nameFilter!.isNotEmpty) {
        final nameFilter = criteria.nameFilter!.toLowerCase();
        if (!room.name.toLowerCase().contains(nameFilter) &&
            !room.description.toLowerCase().contains(nameFilter)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// Pobierz rezerwacje dla określonego okresu
  Future<List<Booking>> _getBookingsForPeriod(DateTime startDate, DateTime endDate) async {
    // Dodaj margines czasowy dla sprawdzenia konfliktów
    final searchStart = DateTime(startDate.year, startDate.month, startDate.day);
    final searchEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection('bookings')
        .where('startTime', isLessThanOrEqualTo: searchEnd)
        .where('endTime', isGreaterThanOrEqualTo: searchStart)
        .get();
    
    return snapshot.docs.map((doc) {
      return Booking.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  /// Znajdź dostępne sloty czasowe dla danej sali
  List<AvailableSlot> _findAvailableSlots(
    Room room, 
    List<Booking> roomBookings, 
    SearchCriteria criteria
  ) {
    final availableSlots = <AvailableSlot>[];
    
    // Iteruj przez każdy dzień w zakresie wyszukiwania
    DateTime currentDate = criteria.startDate;
    while (currentDate.isBefore(criteria.endDate.add(const Duration(days: 1)))) {
      final daySlots = _findSlotsForDay(room, roomBookings, currentDate, criteria);
      availableSlots.addAll(daySlots);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return availableSlots;
  }

  /// Znajdź dostępne sloty dla konkretnego dnia
  List<AvailableSlot> _findSlotsForDay(
    Room room,
    List<Booking> roomBookings,
    DateTime date,
    SearchCriteria criteria
  ) {
    final slots = <AvailableSlot>[];
    
    // Utwórz listę zajętych okresów dla tego dnia
    final occupiedPeriods = _getOccupiedPeriodsForDay(roomBookings, date);
    
    // Określ zakres czasu pracy (np. 8:00 - 20:00)
    final workStart = DateTime(date.year, date.month, date.day, 8, 0);
    final workEnd = DateTime(date.year, date.month, date.day, 20, 0);
    
    // Określ preferowany zakres czasu użytkownika
    final userStart = DateTime(
      date.year, 
      date.month, 
      date.day, 
      criteria.startTime.hour, 
      criteria.startTime.minute
    );
    final userEnd = DateTime(
      date.year, 
      date.month, 
      date.day, 
      criteria.endTime.hour, 
      criteria.endTime.minute
    );
    
    // Użyj przecięcia zakresu pracy i preferencji użytkownika
    final searchStart = userStart.isAfter(workStart) ? userStart : workStart;
    final searchEnd = userEnd.isBefore(workEnd) ? userEnd : workEnd;
    
    if (searchStart.isAfter(searchEnd)) {
      return slots; // Nieprawidłowy zakres
    }
    
    // Znajdź wolne sloty
    final freeSlots = _findFreeSlots(
      searchStart, 
      searchEnd, 
      occupiedPeriods, 
      criteria.duration
    );
    
    // Konwertuj na AvailableSlot
    for (final slot in freeSlots) {
      slots.add(AvailableSlot(
        room: room,
        startTime: slot['start'],
        endTime: slot['end'],
        isFullyAvailable: slot['duration'] >= criteria.duration,
      ));
    }
    
    return slots;
  }

  /// Pobierz zajęte okresy dla konkretnego dnia
  List<Map<String, DateTime>> _getOccupiedPeriodsForDay(
    List<Booking> bookings, 
    DateTime date
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return bookings
        .where((booking) => 
          booking.startTime.isBefore(dayEnd) && 
          booking.endTime.isAfter(dayStart)
        )
        .map((booking) => {
          'start': booking.startTime.isAfter(dayStart) ? booking.startTime : dayStart,
          'end': booking.endTime.isBefore(dayEnd) ? booking.endTime : dayEnd,
        })
        .toList();
  }

  /// Algorytm znajdowania wolnych slotów czasowych
  List<Map<String, dynamic>> _findFreeSlots(
    DateTime searchStart,
    DateTime searchEnd,
    List<Map<String, DateTime>> occupiedPeriods,
    int minDurationMinutes
  ) {
    final freeSlots = <Map<String, dynamic>>[];
    
    // Sortuj zajęte okresy chronologicznie
    occupiedPeriods.sort((a, b) => a['start']!.compareTo(b['start']!));
    
    DateTime currentTime = searchStart;
    
    for (final occupied in occupiedPeriods) {
      // Sprawdź czy jest wolny slot przed aktualną rezerwacją
      if (currentTime.isBefore(occupied['start']!)) {
        final slotEnd = occupied['start']!;
        final duration = slotEnd.difference(currentTime).inMinutes;
        
        if (duration >= minDurationMinutes) {
          freeSlots.add({
            'start': currentTime,
            'end': slotEnd,
            'duration': duration,
          });
        }
      }
      
      // Przesuń currentTime za koniec aktualnej rezerwacji
      if (occupied['end']!.isAfter(currentTime)) {
        currentTime = occupied['end']!;
      }
    }
    
    // Sprawdź czy jest wolny slot na końcu dnia
    if (currentTime.isBefore(searchEnd)) {
      final duration = searchEnd.difference(currentTime).inMinutes;
      if (duration >= minDurationMinutes) {
        freeSlots.add({
          'start': currentTime,
          'end': searchEnd,
          'duration': duration,
        });
      }
    }
    
    return freeSlots;
  }

  /// Porównuj sloty dla sortowania (preferowane wcześniejsze godziny, większe sale)
  int _compareSlots(AvailableSlot a, AvailableSlot b, SearchCriteria criteria) {
    // Najpierw sortuj według daty
    final dateComparison = a.startTime.compareTo(b.startTime);
    if (dateComparison != 0) return dateComparison;
    
    // Potem według pojemności (większe sale preferowane)
    final capacityComparison = b.room.capacity.compareTo(a.room.capacity);
    if (capacityComparison != 0) return capacityComparison;
    
    // Na końcu alfabetycznie według nazwy
    return a.room.name.compareTo(b.room.name);
  }

  /// Szybkie wyszukiwanie aktualnie dostępnych sal
  Future<List<Room>> findCurrentlyAvailableRooms({int? minCapacity}) async {
    final now = DateTime.now();
    final criteria = SearchCriteria(
      minCapacity: minCapacity ?? 1,
      startDate: now,
      endDate: now,
      startTime: TimeOfDay.fromDateTime(now),
      endTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      duration: 60,
    );
    
    final slots = await searchAvailableRooms(criteria);
    return slots.map((slot) => slot.room).toSet().toList();
  }

  /// Sprawdź dostępność konkretnej sali w określonym czasie
  Future<bool> isRoomAvailableAt(
    String roomId, 
    DateTime startTime, 
    DateTime endTime
  ) async {
    final bookings = await _firestore
        .collection('bookings')
        .where('roomId', isEqualTo: roomId)
        .where('startTime', isLessThan: endTime)
        .where('endTime', isGreaterThan: startTime)
        .get();
    
    return bookings.docs.isEmpty;
  }

  /// Znajdź alternatywne terminy dla sali
  Future<List<AvailableSlot>> findAlternativeSlots(
    String roomId,
    DateTime preferredStart,
    int durationMinutes,
    {int daysToSearch = 7}
  ) async {
    final room = await _firestore.collection('rooms').doc(roomId).get();
    if (!room.exists) return [];
    
    final roomData = Room.fromFirestore(roomId, room.data()!);
    final endDate = preferredStart.add(Duration(days: daysToSearch));
    
    final criteria = SearchCriteria(
      minCapacity: 1,
      startDate: preferredStart,
      endDate: endDate,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 20, minute: 0),
      duration: durationMinutes,
    );
    
    final allBookings = await _getBookingsForPeriod(preferredStart, endDate);
    final roomBookings = allBookings.where((b) => b.roomId == roomId).toList();
    
    return _findAvailableSlots(roomData, roomBookings, criteria);
  }
}