import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../pages/top_page.dart';
import 'medication_complete_screen.dart';
import 'medicine_info_screen.dart';
import 'qr_code_screen.dart';
import 'admin_list_screen.dart';
import 'package:kusurins/pages/top_page.dart';

class UserHomeScreen extends StatefulWidget {
  final String uid;
  const UserHomeScreen({super.key, required this.uid});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayMeds = [];
  Map<String, dynamic>? _nextMed;
  Timer? _timer;
  bool _isNowTaking = false;
  bool _isLoadingMeds = false;

  String _userName = '名無しさん';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadTodayMeds();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isLoadingMeds) _loadTodayMeds();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _userName = (data != null && data['name'] is String && (data['name'] as String).isNotEmpty)
            ? data['name'] as String
            : '名無しさん';
      });
    } catch (_) {
      // エラー時もとりあえず「名無しさん」
      if (!mounted) return;
      setState(() => _userName = '名無しさん');
    }
  }

  Future<void> _loadTodayMeds() async {
    setState(() {
      _isLoading = true;
      _isLoadingMeds = true;
    });

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    try {
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('medications')
          .get();

      List<Map<String, dynamic>> todayMeds = [];

      final futures = medsSnapshot.docs.map((doc) async {
        final data = doc.data();
        final medId = doc.id;

        DateTime? startDate = (data['startDate'] as Timestamp?)?.toDate();
        DateTime? endDate = (data['endDate'] as Timestamp?)?.toDate();
        List<dynamic> times = data['time'] ?? [];

        if (startDate != null &&
            endDate != null &&
            !startDate.isAfter(now) &&
            !endDate.isBefore(now)) {
          final completedSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .doc(widget.uid)
              .collection('medications')
              .doc(medId)
              .collection('completed')
              .doc(todayStr)
              .get();

          List<String> completedTimes = [];
          if (completedSnapshot.exists) {
            final data = completedSnapshot.data();
            completedTimes = List<String>.from(data?['times'] ?? []);
          }

          for (var t in times) {
            if (t is String && !completedTimes.contains(t)) {
              final medTime = DateFormat('HH:mm').parse(t);
              final medDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                medTime.hour,
                medTime.minute,
              );

              todayMeds.add({
                'medId': medId,
                'name': data['name'] ?? '未設定のおくすり',
                'time': t,
                'color': data['color'] ?? '白',
                'shape': data['shape'] ?? '',
                'dose': data['dose'] ?? 1,
                'dateTime': medDateTime,
              });
            }
          }
        }
      }).toList();

      await Future.wait(futures);

      todayMeds.sort((a, b) =>
          (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));

      final nextMed = todayMeds.isEmpty
          ? null
          : todayMeds.firstWhere(
              (m) =>
                  (m['dateTime'] as DateTime).isAfter(now) ||
                  ((m['dateTime'] as DateTime).hour == now.hour &&
                      (m['dateTime'] as DateTime).minute >= now.minute),
              orElse: () => todayMeds.first,
            );

      setState(() {
        _todayMeds = todayMeds;
        _nextMed = nextMed;
        _isLoading = false;
        _isLoadingMeds = false;
      });
    } catch (e) {
      print('エラー: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMeds = false;
      });
    }
  }

  void _openMedicationScreen(List<Map<String, dynamic>> medsToTake) async {
    setState(() => _isNowTaking = true);
    _timer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationCompleteScreen(
          userName: _userName,
          medsToTake: medsToTake,
        ),
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isLoadingMeds) _loadTodayMeds();
    });
    setState(() => _isNowTaking = false);
    await _loadTodayMeds();
  }

  // 👇 高齢者向け・改行防止対応ボタン
  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    double fontSize = 28,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 5,
        minimumSize: const Size(double.infinity, 120),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: fontSize + 12, color: Colors.white),
          const SizedBox(height: 10),
          AutoSizeText(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: 18,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String buttonText;
    List<Map<String, dynamic>> medsToTake = [];
    bool isButtonEnabled = false;

    if (_nextMed != null) {
      final medTime = _nextMed!['dateTime'] as DateTime;
      if (now.hour > medTime.hour ||
          (now.hour == medTime.hour && now.minute >= medTime.minute)) {
        buttonText =
            '${DateFormat('HH:mm').format(medTime)}です！おくすりを飲みましょう！';
        medsToTake = _todayMeds
            .where((m) =>
                (m['dateTime'] as DateTime).hour == medTime.hour &&
                (m['dateTime'] as DateTime).minute == medTime.minute)
            .toList();
        isButtonEnabled = true;
      } else {
        buttonText = '次のおくすりは ${DateFormat('HH:mm').format(medTime)} です';
        isButtonEnabled = false;
      }
    } else {
      buttonText = '今日の服薬はありません';
      isButtonEnabled = false;
    }

    final List<Map<String, dynamic>> lowerButtons = [
      {
        'label': 'おくすり',
        'icon': Icons.medication_rounded,
        'color': Colors.amber,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicineInfoScreen(userName: _userName),
            ),
          );
        }
      },
      {
        'label': 'チャット',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.green,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopPage(),
            ),
          );
        }
      },
      {
        'label': '見守り',
        'icon': Icons.people_alt_rounded,
        'color': Colors.pinkAccent,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminListScreen()),
          );
        }
      },
      {
        'label': 'QR',
        'icon': Icons.qr_code_2_rounded,
        'color': Colors.orange,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRCodeScreen()),
          );
        }
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        automaticallyImplyLeading: false, // ← 戻る矢印・ハテナを消す
        title: Text(
          '${_userName} さんのホーム',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
        actions: const [], // ← 右上のハテナやメニューを消す
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 350,
                        child: _buildButton(
                          buttonText,
                          Icons.medication_liquid_rounded,
                          Colors.red,
                          isButtonEnabled
                              ? () => _openMedicationScreen(medsToTake)
                              : null,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 32,
                crossAxisSpacing: 32,
                childAspectRatio: 1.1,
                physics: const NeverScrollableScrollPhysics(),
                children: lowerButtons.map((btn) {
                  return _buildButton(
                    btn['label'] as String,
                    btn['icon'] as IconData,
                    btn['color'] as Color,
                    btn['onPressed'] as VoidCallback?,
                    fontSize: 28,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}