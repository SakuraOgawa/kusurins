import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';
  bool _loading = false; // ボタン連打＆UIフィードバック用

  @override
  void dispose() {
    // ★ 忘れがち：メモリリーク防止
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // ▼ 旧データ混在に備えた安全パーサ（role を bool に変換）
  bool _parseRole(dynamic raw) {
    if (raw is bool) return raw;                       // いまの正しい形
    if (raw is String) return raw.toLowerCase() == 'true' || raw == 'admin';
    if (raw is num) return raw == 1;                   // 0/1 を許容（保険）
    return false;                                      // 既定：服薬者(false)
  }
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'メールアドレスとパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 認証状態を最新化してから確認
      await FirebaseAuth.instance.currentUser?.reload();
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) {
        setState(() => _errorMessage = 'サインイン状態が確認できませんでした');
        return;
      }
      // メール未認証なら、認証待ち画面へ
      if (!u.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/verifyEmail');
        return;
      }
      // 認証済みなら、Firestore の user/{uid}.role を読んで分岐
      final snap = await FirebaseFirestore.instance.collection('user').doc(u.uid).get();
      final data = snap.data();
      final roleBool = _parseRole(data?['role']); // false=服薬者, true=見守る

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, roleBool ? '/adminHome' : '/userHome');

    } on FirebaseAuthException catch (e) {
      //  代表的なエラーの日本語化
      String msg = 'ログインに失敗しました';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        msg = 'メールアドレスまたはパスワードが違います';
      } else if (e.code == 'invalid-email') {
        msg = 'メールアドレスの形式が正しくありません';
      } else if (e.code == 'user-disabled') {
        msg = 'このアカウントは無効化されています';
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = '不明なエラーが発生しました：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // 新規登録画面と同じやさしい緑
      appBar: AppBar(
        title: const Text(
          'ログイン',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal, // 登録画面と同じ緑
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24), // 新規登録と同じ余白
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30), // 新規登録画面と同じ上部スペース
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'ユーザー名',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワード',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            const SizedBox(height: 20),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('ログイン'),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: const Text(
                '新規登録はこちら',
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}