import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  final String watcherName; // 管理者名
  const ScheduleScreen({super.key, required this.watcherName});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Map<String, List<Map<String, String>>> _scheduleMap = {}; // 時間 -> [{user, name, count}]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.watcherName)
          .limit(1)
          .get();

      if (adminDoc.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final adminData = adminDoc.docs.first.data();
      final watchingList = List<String>.from(adminData['watching'] ?? []);

      if (watchingList.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      Map<String, List<Map<String, String>>> tempMap = {};
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      for (final userName in watchingList) {
        final medsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userName)
            .collection('medications')
            .get();

        for (final medDoc in medsSnapshot.docs) {
          final medData = medDoc.data();

          DateTime? startDate = (medData['startDate'] as Timestamp?)?.toDate();
          DateTime? endDate = (medData['endDate'] as Timestamp?)?.toDate();

          if (startDate != null &&
              endDate != null &&
              !startDate.isAfter(todayEnd) &&
              !endDate.isBefore(todayStart)) {
            List<dynamic> times = medData['time'] ?? [];

            for (var t in times) {
              // 🔽 新データ形式 {time: "08:30", count: "2"} に対応
              if (t is Map<String, dynamic> &&
                  (t['time'] ?? '').toString().isNotEmpty) {
                String timeStr = t['time'];
                String count = t['count']?.toString() ?? '';

                tempMap[timeStr] ??= [];
                tempMap[timeStr]!.add({
                  'user': userName,
                  'name': medData['name'] ?? '未設定のおくすり',
                  'count': count,
                });
              }
              // 🔙 旧データ形式（文字列だけ）
              else if (t is String && t.isNotEmpty) {
                tempMap[t] ??= [];
                tempMap[t]!.add({
                  'user': userName,
                  'name': medData['name'] ?? '未設定のおくすり',
                  'count': '',
                });
              }
            }
          }
        }
      }

      // 時間順にソート
      final sortedKeys = tempMap.keys.toList()
        ..sort((a, b) {
          try {
            return DateFormat('HH:mm').parse(a).compareTo(DateFormat('HH:mm').parse(b));
          } catch (_) {
            return a.compareTo(b);
          }
        });

      Map<String, List<Map<String, String>>> sortedMap = {};
      for (var key in sortedKeys) {
        sortedMap[key] = tempMap[key]!;
      }

      setState(() {
        _scheduleMap = sortedMap;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ スケジュール取得エラー: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      appBar: AppBar(
        title: const Text('今日の服薬スケジュール'),
        centerTitle: true,
        backgroundColor: Colors.red[200],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _scheduleMap.isEmpty
              ? const Center(
                  child: Text(
                    '今日の服薬スケジュールはありません',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _scheduleMap.entries.map((entry) {
                    final time = entry.key;
                    final meds = entry.value;

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            ...meds.map(
                              (med) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.medication,
                                        color: Colors.redAccent, size: 22),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${med['name']}（${med['user']}）',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (med['count']?.isNotEmpty == true)
                                      Text(
                                        '${med['count']}錠',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}