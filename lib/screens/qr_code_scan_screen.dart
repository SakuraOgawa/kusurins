import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen>
    with WidgetsBindingObserver {
  // コントローラを用意（推奨設定値付き）
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // 多重検出を抑制
    detectionTimeoutMs: 800,                     // 同一検出のクールダウン
    formats: const [BarcodeFormat.qrCode],       // 使うフォーマットに絞る
    torchEnabled: false,                         // 起動時ライトOFF（ボタンで切替）
    autoZoom: true,                              // 自動ズームON（端末次第）
    // cameraResolution: // 未指定でOK（端末に任せる）
    // returnImage: false,
    // invertImage: false,
  );

  bool _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose(); // ★ カメラを必ず解放
    super.dispose();
  }

  // ライフサイクルで止める/再開（クラッシュ回避に有効）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スキャン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        fit: BoxFit.cover,
        onDetect: (capture) async {
          if (_handling) return;
          final codes = capture.barcodes;
          if (codes.isEmpty) return;
          final raw = codes.first.rawValue ?? '';
          if (raw.isEmpty) return;

          setState(() => _handling = true);
          await controller.stop();   // ★ 先に止めて多重発火防止

          // ここでrawを処理（例：token抽出 → Firestore処理）
          debugPrint('DETECTED: $raw');

          if (!mounted) return;
          Navigator.pop(context, raw); // 呼び出し元に返すなど
        },
      ),
    );
  }
}
