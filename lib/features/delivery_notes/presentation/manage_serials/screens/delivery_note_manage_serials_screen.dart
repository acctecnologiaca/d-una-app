import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/barcode_scanner_screen.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../../../domain/models/delivery_note_serial_model.dart';

class DeliveryNoteManageSerialsScreen extends StatefulWidget {
  final DeliveryNoteItemModel item;
  final ValueChanged<List<DeliveryNoteSerialModel>> onSerialsSaved;

  const DeliveryNoteManageSerialsScreen({
    super.key,
    required this.item,
    required this.onSerialsSaved,
  });

  @override
  State<DeliveryNoteManageSerialsScreen> createState() =>
      _DeliveryNoteManageSerialsScreenState();
}

class _DeliveryNoteManageSerialsScreenState
    extends State<DeliveryNoteManageSerialsScreen> {
  late final List<DeliveryNoteSerialModel> _serials;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _serials = List<DeliveryNoteSerialModel>.from(widget.item.serials);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addSerial(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    if (_serials.any((s) => s.serialNumber.toLowerCase() == code.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El serial "$code" ya está en la lista.'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final needed = widget.item.quantity.round();
    if (_serials.length >= needed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya se alcanzaron los $needed seriales requeridos.'),
          backgroundColor: Colors.amber.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _serials.add(
        DeliveryNoteSerialModel(
          id: '',
          deliveryNoteItemId: widget.item.id,
          productId: widget.item.productId,
          serialNumber: code,
          createdAt: DateTime.now(),
        ),
      );
      _textController.clear();
    });
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _addSerial(scannedCode);
    }
  }

  void _saveAndPop() {
    widget.onSerialsSaved(_serials);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final needed = widget.item.quantity.round();
    final assigned = _serials.length;
    final isComplete = assigned >= needed;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestionar Seriales',
        subtitle: widget.item.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _saveAndPop,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tarjeta informativa del producto y progreso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.item.brand != null || widget.item.model != null)
                  Text(
                    [widget.item.brand, widget.item.model]
                        .whereType<String>()
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Asignados: $assigned de $needed requeridos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                    if (isComplete)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: needed > 0 ? (assigned / needed).clamp(0.0, 1.0) : 1.0,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: isComplete ? Colors.green.shade600 : colors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),

          // 2. Barra de entrada manual y botón de escáner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    label: 'Número de serial',
                    hintText: 'Escriba el serial...',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _addSerial(_textController.text),
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar serial',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear código con cámara',
                ),
              ],
            ),
          ),

          // 3. Lista de seriales agregados
          Expanded(
            child: _serials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2_outlined,
                          size: 48,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay seriales registrados',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Escanea o escribe el número de serial arriba',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _serials.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                    itemBuilder: (context, index) {
                      final serial = _serials[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
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
                          serial.serialNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: colors.error,
                          onPressed: () {
                            setState(() {
                              _serials.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: CustomExtendedFab(
        label: 'Guardar ($assigned/$needed)',
        icon: Icons.check,
        onPressed: _saveAndPop,
      ),
    );
  }
}
