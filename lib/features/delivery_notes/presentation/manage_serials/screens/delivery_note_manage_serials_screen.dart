import 'package:flutter/material.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/barcode_scanner_screen.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../../../domain/models/delivery_note_serial_model.dart';

class DeliveryNoteManageSerialsScreen extends StatefulWidget {
  final DeliveryNoteItemModel item;
  final ValueChanged<List<DeliveryNoteSerialModel>> onSerialsSaved;
  final ValueChanged<bool>? onRequiresSerialsChanged;

  const DeliveryNoteManageSerialsScreen({
    super.key,
    required this.item,
    required this.onSerialsSaved,
    this.onRequiresSerialsChanged,
  });

  @override
  State<DeliveryNoteManageSerialsScreen> createState() =>
      _DeliveryNoteManageSerialsScreenState();
}

class _DeliveryNoteManageSerialsScreenState
    extends State<DeliveryNoteManageSerialsScreen> {
  late final List<DeliveryNoteSerialModel> _serials;
  late bool _noSerials;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _serials = List<DeliveryNoteSerialModel>.from(widget.item.serials);
    _noSerials = !widget.item.requiresSerials;
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

    if (_serials.any(
      (s) => s.serialNumber.toLowerCase() == code.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El serial "$code" ya está en la lista.'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
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
    final needed = widget.item.quantity.round();
    if (_serials.length >= needed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya se alcanzaron los $needed seriales requeridos.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _addSerial(scannedCode);
    }
  }

  void _saveAndPop() {
    widget.onRequiresSerialsChanged?.call(!_noSerials);
    widget.onSerialsSaved(_noSerials ? [] : _serials);
    Navigator.of(context).pop();
  }

  Future<void> _onConfirmWithCheck() async {
    final needed = widget.item.quantity.round();
    if (!_noSerials && _serials.length < needed) {
      final proceed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Faltan seriales',
          contentText:
              'Has registrado ${_serials.length} de $needed seriales requeridos.\n\n¿Deseas continuar registrando más seriales o deseas hacerlo luego?',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Seguir agregando'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Lo haré más tarde'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _saveAndPop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final needed = widget.item.quantity.round();
    final assigned = _serials.length;
    final isComplete = assigned >= needed;

    final filteredSerials = _serials
        .where(
          (s) => s.serialNumber.toLowerCase().contains(
            _searchQuery.trim().toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestionar seriales',
        isSearchable: true,
        onSearchChanged: (val) => setState(() => _searchQuery = val),
        onSearchClosed: () => setState(() => _searchQuery = ''),
      ),
      body: SafeArea(
        child: Column(
          children: [
          // 1. Tarjeta informativa del producto y progreso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                    [
                      widget.item.brand,
                      widget.item.model,
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                if (!_noSerials) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asignados: $assigned de $needed requeridos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      if (isComplete)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: needed > 0
                        ? (assigned / needed).clamp(0.0, 1.0)
                        : 1.0,
                    backgroundColor: colors.secondaryContainer,
                    color: colors.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),

          // 2. Switch "Este producto no usa seriales"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Este producto no usa seriales',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _noSerials,
                      onChanged: (val) {
                        setState(() {
                          _noSerials = val;
                        });
                      },
                    ),
                  ],
                ),
                if (_noSerials) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Al activar esta opción, no se registrarán seriales para este producto y podrá despacharse sin ellos.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Barra de entrada manual y botón de escáner (visible si usa seriales)
          if (!_noSerials)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      label: 'Número de serial',
                      hintText: isComplete
                          ? 'Todos los seriales registrados'
                          : 'Escriba el serial...',
                      enabled: !isComplete,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: isComplete
                          ? null
                          : (val) {
                              _addSerial(val);
                              _focusNode.requestFocus();
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isComplete
                        ? null
                        : () => _addSerial(_textController.text),
                    icon: const Icon(Icons.add),
                    tooltip: isComplete ? 'Límite alcanzado' : 'Agregar serial',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: isComplete ? null : _openScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: isComplete
                        ? 'Límite alcanzado'
                        : 'Escanear código con cámara',
                  ),
                ],
              ),
            ),

          // 4. Lista de seriales agregados (16px margen horizontal)
          Expanded(
            child: _noSerials
                ? const SizedBox.shrink()
                : _serials.isEmpty
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
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      FabScrollPadding.single,
                    ),
                    itemCount: filteredSerials.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final serial = filteredSerials[index];
                      final originalIndex = _serials.indexOf(serial);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: colors.primaryContainer,
                          child: Text(
                            '${originalIndex + 1}',
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
                          icon: const Icon(Icons.close, size: 20),
                          color: colors.onSurfaceVariant,
                          tooltip: 'Remover serial',
                          onPressed: () {
                            setState(() {
                              _serials.removeAt(originalIndex);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    floatingActionButton: CustomExtendedFab(
        label: _noSerials ? 'Guardar' : 'Guardar ($assigned/$needed)',
        icon: Icons.check,
        onPressed: _onConfirmWithCheck,
      ),
    );
  }
}
