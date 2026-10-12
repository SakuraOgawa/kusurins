import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication_list_screen.dart';
import 'add_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<String> users = [];
  String? adminId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersFromFirestore();
  }

  /// Firestoreから見守り対象ユーザーを読み込む
  Future<void> _loadUsersFromFirestore() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final currentAdmin = prefs.getString('current_user'); // ログイン中の管理者

    if (currentAdmin == null) {
      setState(() {
        users = [];
        adminId = null;
        _isLoading = false;
      });
      return;
    }

    try {
      // Firestoreで「username = currentAdmin」の管理者ドキュメントを取得
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: currentAdmin)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          users = [];
          _isLoading = false;
        });
        return;
      }

      final userDoc = snapshot.docs.first;
      final userData = userDoc.data();
      List<dynamic>? watchingList = userData['watching'];

      setState(() {
        adminId = userDoc.id; // FirestoreのドキュメントIDを保持
        users = watchingList != null
            ? watchingList.map((e) => e.toString()).toList()
            : [];
      });
    } catch (e) {
      debugPrint('Firestoreから服薬者を取得できませんでした: $e');
      setState(() {
        users = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 服薬者追加画面に移動
  Future<void> _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserScreen()),
    );
    if (result == true) {
      _loadUsersFromFirestore(); // Firestoreから再読み込み
    }
  }

  /// Firestoreから服薬者を削除する（服薬者側adminsにも反映）
  Future<void> _deleteUser(String userName) async {
    if (adminId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAdmin = prefs.getString('current_user');

      // ① 管理者側の watching から削除
      await FirebaseFirestore.instance.collection('users').doc(adminId).update({
        'watching': FieldValue.arrayRemove([userName]),
      });

      // ② 服薬者側の admins からも削除
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: userName)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userDocId = userSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .update({
          'admins': FieldValue.arrayRemove([currentAdmin]),
        });
      }

      // ③ ローカル反映
      setState(() {
        users.remove(userName);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName さんを削除しました')),
      );
    } catch (e) {
      debugPrint('服薬者削除エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      appBar: AppBar(
        title: const Text('服薬者一覧'),
        backgroundColor: Colors.red[200],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddUser,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('服薬者が登録されていません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userName = users[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MedicationListScreen(
                                      userName: userName,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                textStyle: const TextStyle(fontSize: 20),
                              ),
                              child: Text('$userName さん'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('削除の確認'),
                                  content: Text(
                                      '$userName さんを削除してもよろしいですか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        '削除する',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                _deleteUser(userName);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}