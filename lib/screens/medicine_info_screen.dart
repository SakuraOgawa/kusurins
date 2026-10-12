import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication_view_screen.dart';

class MedicineInfoScreen extends StatelessWidget {
  final String userName;

  const MedicineInfoScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final medsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userName)
        .collection('medications')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // やさしい青背景
      appBar: AppBar(
        title: const Text(
          'おくすりの情報',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ 白文字に変更
          ),
        ),
        backgroundColor: const Color(0xFF1565C0), // 濃い青
        centerTitle: true,
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: medsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'おくすりが登録されていません',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final medId = docs[index].id;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                    const Icon(Icons.medication, color: Color(0xFF1E88E5), size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        data['name'] ?? '未設定のおくすり',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5), // 明るい青
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('確認'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicationViewScreen(
                              username: userName,
                              medId: medId,
                            ),
                          ),
                        );
                      },
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