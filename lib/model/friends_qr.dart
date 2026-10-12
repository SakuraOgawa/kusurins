import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsQr {
  Timestamp createdAt;// created_at
  bool inviterRole; //inviter_role
  String inviterUid; //inviter_uid
  bool paired; //paired
  FriendsQr({
    required this.createdAt,
    required this.inviterRole,
    required this.inviterUid,
    required this.paired,
  });
}