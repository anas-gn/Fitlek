import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ClientQrScannerScreen extends StatefulWidget {
  const ClientQrScannerScreen({super.key});

  @override
  State<ClientQrScannerScreen> createState() => _ClientQrScannerScreenState();
}

class _ClientQrScannerScreenState extends State<ClientQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    _handled = true;
    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Cadre de visée
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: 52,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            top: 52,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => _controller.toggleTorch(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Scan the coach QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}