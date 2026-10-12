import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/user_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _role = false;
// false = 服薬者, true = 管理者
  bool _loading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'メールアドレスまたはパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final u = cred.user;
      if(u == null) {
        setState(() => _errorMessage = 'ユーザー作成に失敗しました（userがnull）');
        print('ユーザー作成に失敗しました');
        return;
      }
      await UserFireStore.insertNewAccount(
        role: _role, // ← boolをそのまま保存（false=服薬者, true=見守る）
        name: '名無し',
        // imagePath: null, // 必要なら渡す
      );
      //メールを送る。
      await u.sendEmailVerification();

      //認証まち
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/verifyEmail');

    } on FirebaseAuthException catch(e) {
      String msg = e.message ?? '登録に失敗しました';
      if (e.code == 'email-already-in-use') msg = 'このメールは既に登録されています';
      if (e.code == 'weak-password') msg = 'パスワードが弱すぎます';
      if (e.code == 'invalid-email') msg = 'メールアドレスの形式が不正です';
      setState(() => _errorMessage = msg);
    } catch(e) {
      setState(() => _errorMessage = '予期せぬエラーが発生しました：$e');
    } finally {
      if (mounted) setState(() => _loading = false); // ← ローディング終了
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // やさしい緑背景
      appBar: AppBar(
        title: const Text(
          '新規登録',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal, // 落ち着いた緑
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
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
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('おくすりを飲む'),
                    value: false,
                    groupValue: _role,
                    onChanged: (value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('見守る'),
                    value: true,
                    groupValue: _role,
                    onChanged: (value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                ),
              ],
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
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('登録'),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                '登録済みの方はこちら',
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