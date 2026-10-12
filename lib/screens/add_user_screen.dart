import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _errorMessage = '';
  String? _currentAdminUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
  }

  Future<void> _loadCurrentAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('current_user');
    print('🟢 ログイン中のユーザー: $currentUser');
    
    setState(() {
      _currentAdminUsername = currentUser;
    });
  }

  Future<void> _addUser() async {
    final inputUsername = _usernameController.text.trim();
    if (inputUsername.isEmpty) {
      setState(() => _errorMessage = 'ユーザー名を入力してください');
      return;
    }

    if (_currentAdminUsername == null) {
      setState(() => _errorMessage = '見守り者情報が取得できませんでした。再ログインしてください。');
      return;
    }

    final firestore = FirebaseFirestore.instance;

    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: inputUsername)
          .where('role', isEqualTo: 'user')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() => _errorMessage = 'そのユーザーは存在しません');
        return;
      }

      final userDoc = querySnapshot.docs.first;

      final adminSnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: _currentAdminUsername)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        setState(() => _errorMessage = '見守り者情報がFirestoreにありません');
        return;
      }

      final adminDocRef = adminSnapshot.docs.first.reference;
      final userDocRef = userDoc.reference;

      await adminDocRef.update({
        'watching': FieldValue.arrayUnion([inputUsername])
      });

      await userDocRef.update({
        'admins': FieldValue.arrayUnion([_currentAdminUsername])
      });

      setState(() {
        _errorMessage = '';
        _usernameController.clear();
      });

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = '登録に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainRed = Colors.red.shade200;
    final Color lightRed = Colors.red.shade100;

    return Scaffold(
      backgroundColor: lightRed,
      appBar: AppBar(
        title: const Text(
          '服薬者登録',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: mainRed,
        foregroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: '服薬者のユーザー名',
                labelStyle: const TextStyle(color: Colors.black),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainRed),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainRed, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainRed,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(55),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}