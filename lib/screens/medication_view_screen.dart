import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationViewScreen extends StatelessWidget {
  final String username;
  final String medId;

  const MedicationViewScreen({
    super.key,
    required this.username,
    required this.medId,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.green[50], // 🌿背景を淡いグリーンに
      appBar: AppBar(
        title: const Text('おくすり情報の確認'),
        centerTitle: true,
        backgroundColor: Colors.teal[300], // 🌿落ち着いた緑系
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore
            .collection('users')
            .doc(username)
            .collection('medications')
            .doc(medId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(
              child: Text(
                'データが見つかりません',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          final timeData = data['time'] ?? [];
          final timeLabels = ['朝', '昼', '夜', '寝る前'];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication, color: Colors.teal, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['name'] ?? '未設定',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1.2),

                    _buildInfoRow('💊 色', data['color']),
                    _buildInfoRow('🔹 形状', data['shape']),
                    const SizedBox(height: 12),

                    const Text(
                      '⏰ 服用時間・錠数',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTimeList(timeData, timeLabels),

                    const SizedBox(height: 12),
                    _buildInfoRow('🔔 通知', data['notification'] == true ? 'あり' : 'なし'),
                    if (startDate != null && endDate != null)
                      _buildInfoRow(
                        '📅 服薬期間',
                        '${startDate.toLocal().toString().split(' ')[0]} 〜 ${endDate.toLocal().toString().split(' ')[0]}',
                      ),

                    const SizedBox(height: 20),
                    const Text(
                      '📝 メモ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['memo']?.toString().isNotEmpty == true
                            ? data['memo']
                            : 'なし',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 汎用ラベル行（色・形状など）
  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value?.toString() ?? '未設定',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 服用時間＋錠数リストを作成
  Widget _buildTimeList(dynamic timeData, List<String> labels) {
    if (timeData is! List || timeData.isEmpty) {
      return const Text(
        '未設定',
        style: TextStyle(fontSize: 18, color: Colors.black54),
      );
    }

    return Column(
      children: List.generate(labels.length, (i) {
        if (i >= timeData.length) return const SizedBox.shrink();

        final item = timeData[i];
        String time = '';
        String count = '';

        if (item is Map<String, dynamic>) {
          time = item['time'] ?? '';
          count = item['count'] ?? '';
        } else if (item is String) {
          time = item;
        }

        if (time.isEmpty && count.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  time.isNotEmpty ? time : '—',
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  count.isNotEmpty ? '$count 錠' : '',
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}