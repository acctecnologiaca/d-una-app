import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.all],
    // autoStart: true, // Default
  );

  bool _isScanned = false; // Prevent multiple pops

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        _isScanned = true;
        // Check if mounted before popping
        if (mounted) {
          Navigator.of(context).pop(code);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
            // overlay param removed in v5/6, we use Stack instead
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            // Corners could be drawn with CustomPainter for better performance/look
            // but keeping simple Container border for MVP
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _corner(),
                    Transform.rotate(angle: 1.57, child: _corner()),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.rotate(angle: -1.57, child: _corner()),
                    Transform.rotate(angle: 3.14, child: _corner()),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Apunta al código de barras',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _corner() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.red, width: 3),
          left: BorderSide(color: Colors.red, width: 3),
        ),
      ),
    );
  }
}
