// lib/models/booking_model.dart
class Booking {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;
  final List<String> participantNames;

  Booking({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.participantNames,
  });

  factory Booking.fromFirestore(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      title: data['title'] ?? '',
      startTime: data['startTime']?.toDate() ?? DateTime.now(),
      endTime: data['endTime']?.toDate() ?? DateTime.now(),
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: List<String>.from(data['participantNames'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'participants': participants,
      'participantNames': participantNames,
    };
  }
}