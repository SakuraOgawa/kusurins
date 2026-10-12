import 'package:flutter/material.dart';
import 'qr_code_display_screen.dart';
import 'qr_code_scan_screen.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコード')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 表示ボタン
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1, // 正方形に近づける
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QRCodeDisplayScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('QRコード表示'),
                  ),
                ),
              ),

              const SizedBox(width: 24), // 間のスペース

              // 読み取りボタン
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanInviteScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('QRコード読み取り'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}