import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/barcode_scanner_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddProductSerialSheet extends ConsumerStatefulWidget {
  const AddProductSerialSheet({super.key});

  @override
  ConsumerState<AddProductSerialSheet> createState() =>
      _AddProductSerialSheetState();
}

class _AddProductSerialSheetState extends ConsumerState<AddProductSerialSheet> {
  late TextEditingController _serialController;

  @override
  void initState() {
    super.initState();
    _serialController = TextEditingController();
    _serialController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  void _confirm() {
    final serial = _serialController.text.trim();
    if (serial.isNotEmpty) {
      Navigator.pop(context, serial);
    }
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      setState(() {
        _serialController.text = scannedCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(
              text: 'Confirmar',
              isFullWidth: false,
              onPressed: _serialController.text.trim().isNotEmpty
                  ? _confirm
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];

    return CustomActionSheet(
      title: 'Añadir serial',
      showDivider: false,
      actions: actions,
      content: CustomTextField(
        label: 'Número de serial',
        controller: _serialController,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        suffixIcon: IconButton(
          icon: const Icon(Symbols.barcode_scanner),
          tooltip: 'Escanear código',
          onPressed: _scanBarcode,
        ),
      ),
    );
  }
}
