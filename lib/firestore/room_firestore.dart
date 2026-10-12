import 'package:kusurins/firestore/user_firestore.dart';
import 'package:kusurins/model/talk_room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

import '../model/user.dart';
import '../utils/shared_prefs.dart';

class RoomFirestore {
  static final FirebaseFirestore firebaseFirestoreInstance = FirebaseFirestore.instance;
  static final _roomCollection = firebaseFirestoreInstance.collection('room');

  static Stream<QuerySnapshot> joinedRoomsSnapshot(String uid) {
    return _roomCollection.where('joined_user_ids', arrayContains: uid).snapshots();
  }

  static Future<void> createRoom(String myUid) async {
    try {
      final docs = await UserFireStore.fetchUsers();
      if(docs == null) return;
      docs.forEach((doc) async{
        if(doc.id == myUid) return;
        await _roomCollection.add({
          'joined_user_ids': [doc.id, myUid],
          'created_time': Timestamp.now()
        });
      });
    } catch(e) {
      print('ルームの作成失敗');
    }
  }

  static Future<List<TalkRoom>> fetchJoinedRooms(String myUid) async {
    try {
      final snapshot = await _roomCollection
          .where('joined_user_ids', arrayContains: myUid)
          .get();

      final List<TalkRoom> talkRooms = [];

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // joined_user_ids を null/型ずれに強くする
        final List<dynamic> rawIds = (data['joined_user_ids'] as List?) ?? const [];
        final List<String> userIds = rawIds.map((e) => e.toString()).toList();

        // デバッグログはそのまま
        print('DEBUG room ${doc.id} joined_user_ids=$userIds (${rawIds.runtimeType})');

        final String talkUserUid =
        userIds.firstWhere((id) => id != myUid, orElse: () => '');

        if (talkUserUid.isEmpty) continue;

        final User? talkUser = await UserFireStore.fetchProfile(talkUserUid);
        if (talkUser == null) continue;

        final String? lastMessage = data['last_message'] as String?;

        talkRooms.add(TalkRoom(
          roomId: doc.id,
          talkUser: talkUser,
          lastMessage: lastMessage,
        ));
      }

      print(talkRooms.length);
      return talkRooms; // ← 常に配列を返す
    } catch (e) {
      print('参加しているトークルームの取得失敗 ----- $e');
      return const <TalkRoom>[]; // ← null を返さない
    }
  }


  static Stream<QuerySnapshot> fetchMessageSnapshot(String roomId) {
    return _roomCollection.doc(roomId).collection('message').orderBy('send_time', descending: true).snapshots();
  }

  static Future<void> sendMessage({required String roomId, required String message}) async {
    try {
      final messageCollection = _roomCollection.doc(roomId).collection('message');
      final uid = FirebaseAuth.instance.currentUser?.uid ?? SharedPrefs.fetchUid();
      if (uid == null || message.trim().isEmpty) return;
      await messageCollection.add({
        'message': message,
        'sender_id': SharedPrefs.fetchUid(),
        'send_time': Timestamp.now()
      });

      await _roomCollection.doc(roomId).update({
        'last_message': message,
      });
    } catch(e) {
      print('メッセージの送信に失敗');
    }
  }
}