import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

/// QR トークン生成（見守り者用）
Future<String> createInviteToken(String adminName) async {
  final token = adminName + '_' + DateTime.now().millisecondsSinceEpoch.toString();
  await _firestore.collection('invites').doc(token).set({
    'adminName': adminName,
    'createdAt': FieldValue.serverTimestamp(),
  });
  return token;
}

/// QR 読み取り後、服薬者側で招待を受け入れる
Future<void> acceptInvite(String userName, String token) async {
  final doc = await _firestore.collection('invites').doc(token).get();
  if (!doc.exists) throw '無効なQRコードです';

  final adminName = doc.data()?['adminName'] as String;

  // 服薬者側：adminsに追加
  final userRef = _firestore.collection('users').doc(userName);
  await userRef.update({
    'admins': FieldValue.arrayUnion([adminName]),
  });

  // 見守り者側：watchingに追加
  final adminRef = _firestore.collection('users').doc(adminName);
  await adminRef.update({
    'watching': FieldValue.arrayUnion([userName]),
  });

  // トークン削除（再利用不可）
  await _firestore.collection('invites').doc(token).delete();
}