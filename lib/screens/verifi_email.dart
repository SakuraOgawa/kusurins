// verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _message = '登録したメールに届いた認証リンクを開いてください。';
  bool _checking = false; // ← 重複タップ防止

  // ▼ 旧データ混在に備えた安全パーサ（role を bool に変換）
  bool _parseRole(dynamic raw) {
    if (raw is bool) return raw;                     // いまの正しい形
    if (raw is String) return raw.toLowerCase() == 'true' || raw == 'admin';
    if (raw is num) return raw == 1;                 // 0/1 を許容する保険
    return false;                                    // 既定：服薬者(false)
  }

  // =========================
  // 1) 認証済みかチェック → 画面分岐
  // =========================
  Future<void> _checkVerifiedAndRoute() async {
    if (_checking) return;                 // ★ 二重押し防止
    setState(() => _checking = true);

    try {
      // ▼ 認証状態を最新化
      await FirebaseAuth.instance.currentUser?.reload();
      final u = FirebaseAuth.instance.currentUser;

      if (u == null) {
        setState(() => _message = '未サインインです。ログインし直してください。');
        return;
      }

      if (!u.emailVerified) {
        setState(() => _message = 'まだ未認証です。メール内のリンクを開いてください。');
        return;
      }

      // ▼ 認証済みになったら、Firestoreの role を読んで分岐
      final snap =
      await FirebaseFirestore.instance.collection('user').doc(u.uid).get();
      final data = snap.data();
      final role = _parseRole(data?['role']); // false=服薬者, true=見守る

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, role ? '/adminHome' : '/userHome');
    } catch (e) {
      setState(() => _message = '確認中にエラーが発生しました：$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  // =========================
  // 2) 認証メールを再送
  // =========================
  Future<void> _resend() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _message = '未サインインです。ログインし直してください。');
      return;
    }
    if (u.emailVerified) {
      setState(() => _message = 'すでに認証済みです。下のボタンで確認してください。');
      return;
    }

    try {
      await u.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('認証メールを再送しました。受信箱をご確認ください。')),
      );
    } catch (e) {
      setState(() => _message = '再送に失敗しました：$e');
    }
  }

  // =========================
  // 3) ログアウト（必要なら）
  // =========================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); // ← ルート名はプロジェクトに合わせて
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メール認証の確認')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ▼ 案内メッセージ
            Text(_message),
            const SizedBox(height: 16),

            // ▼ 認証済みか再チェック
            ElevatedButton(
              onPressed: _checking ? null : _checkVerifiedAndRoute,
              child: Text(_checking ? '確認中…' : '認証済みか再チェック'),
            ),
            const SizedBox(height: 8),

            // ▼ 認証メールを再送
            TextButton(
              onPressed: _resend,
              child: const Text('認証メールを再送する'),
            ),
            const SizedBox(height: 8),

            // ▼ 任意：ログアウト
            TextButton(
              onPressed: _logout,
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }
}
