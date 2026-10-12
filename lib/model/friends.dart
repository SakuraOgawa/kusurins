import 'package:cloud_firestore/cloud_firestore.dart';
// コメントはfirebaseでのフィールド名
class Friends {
  bool active;//active
  Timestamp createdTime; //created_time.
  String paitient; //patient_uid
  String topic; //topic
  List<String> uids;
  String watcherUid; //watcher_uid
  Friends({
    required this.active,
    required this.createdTime,
    required this.paitient,
    required this.topic,
    required this.uids,
    required this.watcherUid,
  });
}
