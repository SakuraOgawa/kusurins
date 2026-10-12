import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _db = FirebaseFirestore.instance;

String _genToken(int len) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final r = Random.secure();
  return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
}

/// 招待トークンを作成（friendInvites/{token}）
Future<String> createInviteToken() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final token = _genToken(24);
  await _db.collection('friendInvites').doc(token).set({
    'inviterUid': uid,
  });
  return token;
}

/// トークン受理 → friends/room 作成（重複はTxで回避）
Future<void> acceptInviteByToken(String token) async {
  final me = FirebaseAuth.instance.currentUser!.uid;

  await _db.runTransaction((tx) async {
    final inviteRef = _db.collection('friendInvites').doc(token);
    final inviteSnap = await tx.get(inviteRef);
    if (!inviteSnap.exists) throw '招待が見つかりません';
    final inviter = inviteSnap.data()!['inviterUid'] as String;
    if (inviter == me) throw '自分自身は追加できません';

    final a = (me.compareTo(inviter) < 0) ? me : inviter;
    final b = (me.compareTo(inviter) < 0) ? inviter : me;
    final pairId = '${a}_$b';

    final friendRef = _db.collection('friends').doc(pairId);
    if (!(await tx.get(friendRef)).exists) {
      tx.set(friendRef, {
        'uids': [a, b],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final existing = await _db.collection('rooms')
        .where('type', isEqualTo: 'dm')
        .where('members.$a', isEqualTo: true)
        .where('members.$b', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      final roomRef = _db.collection('rooms').doc();
      tx.set(roomRef, {
        'type': 'dm',
        'members': {a: true, b: true},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  });
}
