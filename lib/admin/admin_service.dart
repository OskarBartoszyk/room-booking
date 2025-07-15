
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sprawdź czy użytkownik jest administratorem
  Future<bool> isAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      return userData?['isAdmin'] ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ZARZĄDZANIE UŻYTKOWNIKAMI
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Błąd podczas aktualizacji użytkownika');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Usuń wszystkie rezerwacje użytkownika
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Usuń użytkownika z Firestore
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Błąd podczas usuwania użytkownika');
    }
  }

  Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
    } catch (e) {
      print('Error toggling admin status: $e');
      throw Exception('Błąd podczas zmiany uprawnień');
    }
  }

  // ZARZĄDZANIE SALAMI
  Future<List<Map<String, dynamic>>> getAllRooms() async {
    try {
      final snapshot = await _firestore.collection('rooms').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting rooms: $e');
      return [];
    }
  }

  Future<void> addRoom(Map<String, dynamic> roomData) async {
    try {
  await _firestore.collection('rooms').add(roomData);
} catch (e, stackTrace) {
  print('Błąd dodawania pokoju: $e');
  print('Stack trace: $stackTrace');
}

  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update(data);
    } catch (e) {
      print('Error updating room: $e');
      throw Exception('Błąd podczas aktualizacji sali');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      // Usuń wszystkie rezerwacje dla tej sali
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Usuń salę
      await _firestore.collection('rooms').doc(roomId).delete();
    } catch (e) {
      print('Error deleting room: $e');
      throw Exception('Błąd podczas usuwania sali');
    }
  }

  // ZARZĄDZANIE REZERWACJAMI
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting bookings: $e');
      return [];
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      print('Error deleting booking: $e');
      throw Exception('Błąd podczas usuwania rezerwacji');
    }
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update(data);
    } catch (e) {
      print('Error updating booking: $e');
      throw Exception('Błąd podczas aktualizacji rezerwacji');
    }
  }

  // STATYSTYKI
  Future<Map<String, int>> getStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      
      final now = DateTime.now();
      final activeBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final startTime = (data['startTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();
        return startTime.isBefore(now) && endTime.isAfter(now);
      }).length;

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalRooms': roomsSnapshot.docs.length,
        'totalBookings': bookingsSnapshot.docs.length,
        'activeBookings': activeBookings,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalUsers': 0,
        'totalRooms': 0,
        'totalBookings': 0,
        'activeBookings': 0,
      };
    }
  }
}