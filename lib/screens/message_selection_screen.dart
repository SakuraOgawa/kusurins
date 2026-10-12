import 'package:flutter/material.dart';
import 'package:kusurins/pages/top_page.dart';

class MessageSelectionScreen extends StatelessWidget {
  const MessageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メッセージ選択')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // チャットボタン
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,  // 正方形にする
                  child: ElevatedButton(
                    onPressed: () {
                      // チャット画面に遷移する処理
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => TopPage()
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('チャット'),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // ボイスメッセージボタン
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,  // 正方形にする
                  child: ElevatedButton(
                    onPressed: () {
                      // ボイスメッセージ画面に遷移する処理
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('ボイスメッセージ'),
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