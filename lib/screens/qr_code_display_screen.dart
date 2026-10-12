// lib/screens/qr_code_display_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../firestore/friend_invite_firestore.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QRCodeDisplayScreen extends StatefulWidget {
  const QRCodeDisplayScreen({super.key});
  @override
  State<QRCodeDisplayScreen> createState() => _QRCodeDisplayScreenState();
}

class _QRCodeDisplayScreenState extends State<QRCodeDisplayScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _issueNew();
  }

  Future<void> _issueNew() async {
    final token = await createInviteToken(); // ← 定義済みに
    setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    final link = _token == null ? '' : 'app://invite?token=$_token';
    return Scaffold(
      appBar: AppBar(title: const Text('友だち招待QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_token == null)
              const CircularProgressIndicator()
            else
            // --- A) pretty_qr_code 3.x（推奨） ---
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: PrettyQrView.data(
                  data: link,                 // ← そのままリンクを渡す
                  decoration: const PrettyQrDecoration(
                    // ここで見た目を調整可能（例：丸み・ドット形状など）
                    shape: PrettyQrSmoothSymbol(), // 丸みのあるドット
                  ),
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _issueNew,
              child: const Text('QRを更新する'),
            ),
            SelectableText(link, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _token == null ? null : () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('リンクをコピーしました')),
                    );
                  },
                  child: const Text('リンクをコピー'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _issueNew,      // ← “更新”で新しいリンク＆QRに差し替え
                  child: const Text('リンク/QRを更新'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('相手は：スキャン（mobile_scanner）またはリンクを開く/貼り付けで追加できます'),
          ],
        ),
      ),
    );
  }
}
