import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication_settings_screen.dart';
import 'medication_view_screen.dart';

class MedicationListScreen extends StatefulWidget {
  final String userName;

  const MedicationListScreen({Key? key, required this.userName})
      : super(key: key);

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 色名からColorを取得
  Color _getColorFromName(String? name) {
    switch (name) {
      case '白':
        return Colors.white;
      case '赤':
        return Colors.red;
      case '青':
        return Colors.blue;
      case '緑':
        return Colors.green;
      case '黄色':
        return Colors.yellow;
      case 'ピンク':
        return Colors.pink;
      case 'オレンジ':
        return Colors.orange;
      case '透明':
        return Colors.grey;
      default:
        return Colors.grey[300]!;
    }
  }

  Future<void> _addMedication() async {
    final newDoc = _firestore
        .collection('users')
        .doc(widget.userName)
        .collection('medications')
        .doc();

    await newDoc.set({
      'name': '新しいおくすり',
      'color': null,
      'shape': null,
      'time': null,
      'startDate': null,
      'endDate': null,
      'notification': false,
      'memo': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationSettingsScreen(
          userName: widget.userName,
          medId: newDoc.id,
          existingData: {
            'name': '新しいおくすり',
            'color': null,
            'shape': null,
            'time': null,
            'startDate': null,
            'endDate': null,
            'notification': false,
            'memo': '',
          },
        ),
      ),
    );
  }

  Future<void> _deleteMedication(String medId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[100],
        title: const Text('削除の確認'),
        content: const Text('このおくすり情報を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[200]),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore
          .collection('users')
          .doc(widget.userName)
          .collection('medications')
          .doc(medId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final medsRef = _firestore
        .collection('users')
        .doc(widget.userName)
        .collection('medications')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      backgroundColor: Colors.red[100],
      appBar: AppBar(
        title: Text('${widget.userName} さんのおくすり一覧'),
        backgroundColor: Colors.red[200],
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: medsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'まだおくすりが登録されていません',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final medId = docs[index].id;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 上段：お薬情報
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getColorFromName(data['color']),
                            radius: 22,
                            child: const Icon(Icons.medication, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['name'] ?? '未設定のおくすり',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// 下段：ボタン群
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: const Text('確認'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[100],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationViewScreen(
                                    username: widget.userName,
                                    medId: medId,
                                  ),
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: const Text('設定'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[200],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationSettingsScreen(
                                    userName: widget.userName,
                                    medId: medId,
                                    existingData: data,
                                  ),
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('削除'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[300],
                              //foregroundColor: Colors.black87,
                            ),
                            onPressed: () => _deleteMedication(medId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedication,
        backgroundColor: Colors.red[200],
        icon: const Icon(Icons.add),
        label: const Text('おくすりを追加'),
      ),
    );
  }
}