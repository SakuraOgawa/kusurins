import 'package:kusurins/firestore/room_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../model/user.dart';
import '../utils/shared_prefs.dart';

class UserFireStore {
  static final FirebaseFirestore firebaseFirestoreInstance = FirebaseFirestore.instance;
  static final _userCollection = firebaseFirestoreInstance.collection('user');

  static Future<String?> insertNewAccount({
    required bool role,
    String name = '名無し',
    String? imagePath,
  }) async {
    try {

      final u = FirebaseAuth.instance.currentUser; // ← null対策は画面側で先に作成してから呼んでいるのでOK
      if (u == null) {
        print('アカウント作成失敗 ===== 未サインイン');
        return null;
      }

      await _userCollection.doc(u.uid).set({
        'name': name,
        'image_path': 'https://play-lh.googleusercontent.com/3ImQkiRynf23t3kZ3PMtmGNA0OaozdlzjkH0e2OTV_wmHxUdXglyGpnWuxqmofmMAw',
        'role': role,
        'email': u.email ?? '',
        'isEmailVerified': u.emailVerified,          // ★ 認証状態（任意だが便利）
        'createdAt': FieldValue.serverTimestamp(),   // ★ 作成時刻
      }, SetOptions(merge: true));
      print('アカウント作成完了');
      return u.uid;
    } catch(e) {
      print('アカウント作成失敗 ===== $e');
      return null;
    }
  }

  static Future<void> createUser({required bool role}) async {
    final myUid = await insertNewAccount(role: role);
    if(myUid != null) {
      await RoomFirestore.createRoom(myUid);
      await SharedPrefs.setUid(myUid);
    }
  }


  static Future<List<QueryDocumentSnapshot>?> fetchUsers() async{
    try {
      final snapshot = await _userCollection.get();
      return snapshot.docs;
    } catch(e) {
      print('ユーザー情報の取得の失敗 ===== e');
      return null;
    }
  }

  static bool _parseRole(dynamic raw) {
    if (raw is bool) return raw;                         // いまの正しい形
    if (raw is String) {                                  // 旧データ保険
      final s = raw.toLowerCase();
      if (s == 'true' || s == 'admin') return true;      // "admin" をtrue扱い
      if (s == 'false' || s == 'user') return false;
    }
    if (raw is num) return raw == 1;                      // 稀に0/1で持っている場合
    return false;                                         // 既定：服薬者(false)
  }

  static Future<User?> fetchProfile(String uid) async {
    try {
      final snapshot = await _userCollection.doc(uid).get();
      if (!snapshot.exists) return null; // ★ 追加：存在チェック
      final data = snapshot.data();
      if (data == null) return null;     // ★ 追加：nullガード


      // ★ ここで安全に型を吸収
      final roleBool = _parseRole(data['role']);

      User user = User(
        name: snapshot.data()!['name'],
        imagePath: snapshot.data()!['image_path'],
        email: snapshot.data()!['email'],
        isEmailVerified: snapshot.data()!['isEmailVerified'],
        role: roleBool,
        createdAt: snapshot.data()!['createdAt'],
        uid: uid,
        currentQrCode: data['current_qr_code'],
        // モデル側のパラメータ名が snake_case のままならそれに合わせる
        // qrRotatedAt: data['qr_rotated_at'],
      );

      return user;
    } catch(e) {
      print('自分のユーザー情報の取得失敗 ----- $e');
    }
    return null;
  }
}
