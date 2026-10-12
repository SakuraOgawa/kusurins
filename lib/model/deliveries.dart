//コメントで書かれている変数名はFirestoreに登録されている名前
import 'package:cloud_firestore/cloud_firestore.dart';

class Deliveries {
  String friendId; //friend_id
  String medicineId; //medicine_id
  int attempt; // attempt
  Timestamp firedAt; // fired_at
  Timestamp completedAt; //completed_at
  Timestamp expiresAt; // expires_at
  Deliveries({
    required this.friendId,
    required this.medicineId,
    required this.attempt,
    required this.firedAt,
    required this.completedAt,
    required this.expiresAt
  });
}
