import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationCompleteScreen extends StatelessWidget {
  final String userName;
  final List<Map<String, dynamic>> medsToTake;

  const MedicationCompleteScreen({
    super.key,
    required this.userName,
    required this.medsToTake,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd

    Future<void> _markAsComplete() async {
      final batch = FirebaseFirestore.instance.batch();

      for (var med in medsToTake) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userName)
            .collection('medications')
            .doc(med['medId'])
            .collection('completed')
            .doc(todayStr);

        batch.set(docRef, {
          'times': FieldValue.arrayUnion([med['time']])
        }, SetOptions(merge: true));
      }

      await batch.commit();
      Navigator.pop(context); // 完了したらホームに戻る
    }

    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(title: const Text('服薬完了')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '次のおくすりを飲みましょう',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: medsToTake.length,
                itemBuilder: (context, index) {
                  final med = medsToTake[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _colorFromName(med['color']),
                      ),
                      title: Text('${med['name']}'),
                      subtitle: Text(
                          '${med['dose']}錠・形状: ${med['shape']}・時間: ${med['time']}'),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _markAsComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[500],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text('完了'),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case '赤':
        return Colors.red;
      case '青':
        return Colors.blue;
      case '緑':
        return Colors.green;
      case '黄色':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}