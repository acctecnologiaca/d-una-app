import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Zoom inicial calibrado (~1.3x) para cerrar el ángulo de apertura natural del lente
  double _currentZoom = 0.15;

  late final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 300,
    formats: const [BarcodeFormat.all],
    initialZoom: _currentZoom,
  );

  bool _isScanned = false; // Prevenir múltiples pops
  String? _stabilizingCode; // Código en proceso de confirmación
  Timer? _stabilityTimer;
  Timer? _resetTimer;
  bool _isResolvingAmbiguity = false;

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    _resetTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  String _sanitizeBarcode(String raw) {
    var code = raw.trim();
    // Elimina prefijo AIM Symbology Identifier (ej. ]C1, ]e0, ]d2, etc. según ISO/IEC 15424)
    final aimRegex = RegExp(r'^\][A-Za-z0-9]{2}');
    if (aimRegex.hasMatch(code)) {
      code = code.substring(3).trim();
    }
    return code;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned || _isResolvingAmbiguity) return;

    final validCodes = capture.barcodes
        .map((b) => b.rawValue != null ? _sanitizeBarcode(b.rawValue!) : '')
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();

    if (validCodes.isEmpty) return;

    // Caso: Varios códigos detectados simultáneamente en la ventana
    if (validCodes.length > 1) {
      _cancelStability();
      _showMultipleCodesSheet(validCodes);
      return;
    }

    final code = validCodes.first;

    // Si ya estamos estabilizando este mismo código, renovamos el reset timer y esperamos
    if (_stabilizingCode == code) {
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !_isScanned) {
          setState(() {
            _stabilizingCode = null;
          });
        }
      });
      return;
    }

    // Nuevo código detectado: iniciamos período de estabilización (~350ms)
    _cancelStability();
    setState(() {
      _stabilizingCode = code;
    });

    _resetTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_isScanned) {
        setState(() {
          _stabilizingCode = null;
        });
      }
    });

    _stabilityTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _isScanned || _stabilizingCode != code) return;
      _confirmCode(code);
    });
  }

  void _confirmCode(String code) {
    _isScanned = true;
    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.of(context).pop(code);
    }
  }

  void _cancelStability() {
    _stabilityTimer?.cancel();
    _resetTimer?.cancel();
    _stabilityTimer = null;
    _resetTimer = null;
  }

  void _showMultipleCodesSheet(List<String> codes) {
    setState(() {
      _isResolvingAmbiguity = true;
    });

    showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.barcode, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Múltiples códigos detectados',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona cuál de los códigos deseas agregar:',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: codes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final itemCode = codes[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        tileColor: colors.surfaceContainerLow,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          itemCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () => Navigator.of(context).pop(itemCode),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((selectedCode) {
      if (!mounted) return;
      if (selectedCode != null && selectedCode.isNotEmpty) {
        _confirmCode(selectedCode);
      } else {
        setState(() {
          _isResolvingAmbiguity = false;
        });
      }
    });
  }

  void _setZoom(double zoom) {
    setState(() {
      _currentZoom = zoom;
    });
    controller.setZoomScale(zoom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.sizeOf(context);

    // Ranura horizontal calibrada para códigos 1D/2D (~310px ancho x ~130px alto)
    final double windowWidth = min(screenSize.width * 0.85, 320.0);
    const double windowHeight = 130.0;
    final scanWindow = Rect.fromCenter(
      center: Offset(screenSize.width / 2, (screenSize.height - 100) / 2),
      width: windowWidth,
      height: windowHeight,
    );

    final bool isFocusing = _stabilizingCode != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Escanear Código',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 22,
            color: colors.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            color: colors.onSurface,
            tooltip: 'Linterna',
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            color: colors.onSurface,
            tooltip: 'Cambiar cámara',
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cámara con scanWindow de hardware activo
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: _onDetect,
          ),

          // 2. Overlay sombreado con recorte nativo de la ventana
          ScanWindowOverlay(
            controller: controller,
            scanWindow: scanWindow,
            borderColor: Colors.transparent, // Lo personalizamos arriba
            color: Colors.black.withValues(alpha: 0.65),
          ),

          // 3. Marco visual dinámico con feedback de lectura
          Positioned.fromRect(
            rect: scanWindow,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocusing ? const Color(0xFF2E7D32) : Colors.white,
                    width: isFocusing ? 3.0 : 2.0,
                  ),
                  boxShadow: isFocusing
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _corner(isFocusing),
                        Transform.rotate(
                          angle: 1.57,
                          child: _corner(isFocusing),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.rotate(
                          angle: -1.57,
                          child: _corner(isFocusing),
                        ),
                        Transform.rotate(
                          angle: 3.14,
                          child: _corner(isFocusing),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Indicador de texto superior
          Positioned(
            top: scanWindow.top - 48,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFocusing
                      ? 'Confirmando: ${_stabilizingCode!}'
                      : 'Ubica el código dentro de la ranura',
                  style: TextStyle(
                    color: isFocusing ? const Color(0xFF81C784) : Colors.white,
                    fontWeight: isFocusing ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // 5. Barra inferior de control de Zoom rápido
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      _zoomButton('1x', 0.0),
                      const SizedBox(width: 6),
                      _zoomButton('1.3x', 0.15),
                      const SizedBox(width: 6),
                      _zoomButton('2x', 0.35),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomButton(String label, double zoomValue) {
    final isSelected = (_currentZoom - zoomValue).abs() < 0.05;

    return InkWell(
      onTap: () => _setZoom(zoomValue),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _corner(bool isFocusing) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isFocusing ? const Color(0xFF4CAF50) : Colors.red,
            width: 3.5,
          ),
          left: BorderSide(
            color: isFocusing ? const Color(0xFF4CAF50) : Colors.red,
            width: 3.5,
          ),
        ),
      ),
    );
  }
}
