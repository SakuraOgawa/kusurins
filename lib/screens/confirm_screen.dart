import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationConfirmScreen extends StatelessWidget {
  final String userName;
  final String medicineId;

  const MedicationConfirmScreen({
    super.key,
    required this.userName,
    required this.medicineId,
  });

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userName)
        .collection('medications')
        .doc(medicineId);

    return Scaffold(
      backgroundColor: Colors.red[100],
      appBar: AppBar(title: const Text('設定内容の確認')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(child: Text('データが見つかりません'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(children: [
              Text('おくすりの名前: ${data['name']}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              Text('色: ${data['color']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('形状: ${data['shape']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('服用時間: ${(data['time'] as List?)?.join(", ") ?? "未設定"}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text(
                '服薬期間: '
                '${data['startDate'] != null ? (data['startDate'] as Timestamp).toDate().toLocal().toString().split(" ")[0] : "未設定"}'
                '〜'
                '${data['endDate'] != null ? (data['endDate'] as Timestamp).toDate().toLocal().toString().split(" ")[0] : "未設定"}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text('通知: ${data['notification'] ? "あり" : "なし"}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('メモ: ${data['memo']}', style: const TextStyle(fontSize: 18)),
            ]),
          );
        },
      ),
    );
  }
}