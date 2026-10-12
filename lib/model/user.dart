import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String name; //メッセージルームの名前
  String uid; // Authの主キー
  String email; // email
  bool isEmailVerified; // メール認証を行ったか.
  bool role; // false: お薬を飲む人, true: 見守る人.
  String? imagePath; // チャットルームのイメージ画像選択.
  final Timestamp createdAt; // アカウント作成の日時.
  String currentQrCode; // current_qr_code
  // Timestamp qrRotatedAt;

  User({
    required this.name,
    required this.uid,
    required this.email,
    required this.isEmailVerified,
    required this.role,
    this.imagePath,
    required this.createdAt,
    required this.currentQrCode,
    // required this.qrRotatedAt,
  });
}