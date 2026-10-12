import 'package:cloud_firestore/cloud_firestore.dart';

class Reminders {
  bool active;              // active
  List<int> daysOfWeek;     // days_of_week
  String friendId;          // friend_id
  String medicineId;        // medicine_id
  String name;              // name
  Timestamp nextFireAt;     // next_fire_at (UTC推奨)
  String repeat;        // repeat
  String timezone;          // timezone
  String topic;             // topic
  Timestamp updatedAt;      // update_at

  Reminders({
    required this.active,
    required this.daysOfWeek,
    required this.friendId,
    required this.medicineId,
    required this.name,
    required this.nextFireAt,
    required this.repeat,
    required this.timezone,
    required this.topic,
    required this.updatedAt,
});

}