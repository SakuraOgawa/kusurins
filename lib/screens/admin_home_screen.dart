import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_code_screen.dart';
import 'user_list_screen.dart';
import 'schedule_screen.dart';
import 'add_user_screen.dart';
import 'package:kusurins/pages/top_page.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<String> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100], // やわらかい背景
      appBar: AppBar(
        title: const Text(
          '見守り者ホーム画面',
          style: TextStyle(fontSize: 22),
        ),
        backgroundColor: Colors.red[200],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ① 服薬者一覧
              _buildExpandedButton(
                context,
                '服薬者一覧',
                Colors.pink[300]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserListScreen()),
                  );
                },
              ),

              // ② チャット
              _buildExpandedButton(
                context,
                'チャット',
                Colors.pink[200]!,
                () async {
                  final currentUser = await _getCurrentUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TopPage(),
                    ),
                  );
                },
              ),

              // ③ 今日のスケジュール
              _buildExpandedButton(
                context,
                '今日のスケジュール',
                Colors.pink[300]!,
                () async {
                  final currentUser = await _getCurrentUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScheduleScreen(watcherName: currentUser),
                    ),
                  );
                },
              ),

              // ④ 服薬者登録
              _buildExpandedButton(
                context,
                '服薬者登録',
                Colors.pink[200]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddUserScreen()),
                  );
                },
              ),

              // ⑤ QRコード
              _buildExpandedButton(
                context,
                'QRコード',
                Colors.pink[300]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRCodeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedButton(
      BuildContext context, String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}