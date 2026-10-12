import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  String? currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// SharedPreferences からログイン中のユーザー名を取得
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString('current_user');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            '見守り者一覧',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white, // ← 白文字
            ),
          ),
          backgroundColor: const Color(0xFF1565C0),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Stream<QuerySnapshot<Map<String, dynamic>>> userStream =
        FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: currentUser)
            .limit(1)
            .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 淡い水色背景
      appBar: AppBar(
        title: const Text(
          '見守り者一覧',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ← 白文字
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyMessage();
          }

          final userData = snapshot.data!.docs.first.data();
          final List<dynamic>? adminList = userData['admins'];
          final admins = adminList != null
              ? adminList.map((e) => e.toString()).toList()
              : [];

          if (admins.isEmpty) {
            return const _EmptyMessage();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final adminName = admins[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        size: 36, color: Color(0xFF1976D2)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$adminName さん',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 管理者がいない場合のメッセージ
class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '見守り者が登録されていません',
        style: TextStyle(
          fontSize: 22,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }
}