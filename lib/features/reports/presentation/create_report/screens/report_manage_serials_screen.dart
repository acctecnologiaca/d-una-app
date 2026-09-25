import 'package:flutter/material.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/barcode_scanner_screen.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../data/models/service_report_item_product.dart';
import '../../../data/models/service_report_serial.dart';

class ReportManageSerialsScreen extends StatefulWidget {
  final ServiceReportItemProduct item;
  final ValueChanged<List<ServiceReportSerial>> onSerialsSaved;
  final ValueChanged<bool>? onRequiresSerialsChanged;

  const ReportManageSerialsScreen({
    super.key,
    required this.item,
    required this.onSerialsSaved,
    this.onRequiresSerialsChanged,
  });

  @override
  State<ReportManageSerialsScreen> createState() =>
      _ReportManageSerialsScreenState();
}

class _ReportManageSerialsScreenState extends State<ReportManageSerialsScreen> {
  late final List<ServiceReportSerial> _serials;
  late final List<String> _initialSerialNumbers;
  late bool _noSerials;
  late final bool _initialNoSerials;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _serials = List<ServiceReportSerial>.from(widget.item.serials);
    _noSerials = !widget.item.requiresSerials && widget.item.serials.isEmpty;
    _initialNoSerials = _noSerials;
    _initialSerialNumbers = List.unmodifiable(
      _serials.map((s) => s.serialNumber).toList(),
    );
  }

  bool get _canSave {
    if (_noSerials) {
      return _initialNoSerials != _noSerials ||
          _initialSerialNumbers.isNotEmpty;
    }
    if (_serials.isEmpty) return false;
    if (_initialNoSerials != _noSerials) return true;
    if (_serials.length != _initialSerialNumbers.length) return true;
    for (int i = 0; i < _serials.length; i++) {
      if (_serials[i].serialNumber != _initialSerialNumbers[i]) return true;
    }
    return false;
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
      AppToast.error(
        context,
        message: 'El serial "$code" ya está en la lista.',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final needed = widget.item.quantity.round();
    if (_serials.length >= needed) {
      AppToast.error(
        context,
        message: 'Ya se alcanzaron los $needed seriales requeridos.',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _serials.add(
        ServiceReportSerial(
          id: '',
          reportItemId: widget.item.id,
          productId: widget.item.productId,
          serialNumber: code,
          createdAt: DateTime.now(),
        ),
      );
      _textController.clear();
    });
  }

  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (code != null && code.isNotEmpty && mounted) {
      _addSerial(code);
    }
  }

  void _onConfirmWithCheck() {
    final needed = widget.item.quantity.round();
    if (!_noSerials && _serials.length < needed) {
      final missing = needed - _serials.length;
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Symbols.warning,
          title: 'Seriales incompletos',
          contentText:
              'Aún faltan $missing serial(es) por asignar a este producto.\n\n¿Deseas guardar de todos modos? El reporte no podrá finalizarse hasta completar todos los seriales.',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                _finalizeSave();
              },
              child: const Text('Guardar pendientes'),
            ),
          ],
        ),
      );
      return;
    }
    _finalizeSave();
  }

  void _finalizeSave() {
    widget.onRequiresSerialsChanged?.call(!_noSerials);
    widget.onSerialsSaved(_noSerials ? const [] : List.unmodifiable(_serials));
    Navigator.of(context).pop();
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
            // Cabecera informativa del producto y progreso
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
                      [widget.item.brand, widget.item.model]
                          .whereType<String>()
                          .join(' · '),
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

            // Switch "Este producto no usa seriales"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Este producto no usa seriales',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    activeThumbColor: colors.primary,
                    value: _noSerials,
                    onChanged: (val) {
                      setState(() {
                        _noSerials = val;
                      });
                    },
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
                              'Al activar esta opción, no se registrarán seriales para este producto y podrá registrarse sin ellos.',
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

            // Entrada manual y escáner
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
                      tooltip: isComplete
                          ? 'Límite alcanzado'
                          : 'Agregar serial',
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: isComplete ? null : _openScanner,
                      icon: const Icon(Symbols.barcode_scanner),
                      tooltip: isComplete
                          ? 'Límite alcanzado'
                          : 'Escanear código con cámara',
                    ),
                  ],
                ),
              ),

            // Lista de seriales agregados
            Expanded(
              child: _noSerials
                  ? const SizedBox.shrink()
                  : _serials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.barcode,
                            size: 48,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
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
        isEnabled: _canSave,
        onPressed: _canSave ? _onConfirmWithCheck : null,
      ),
    );
  }
}
