import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/barcode_scanner_screen.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/purchases/domain/models/models.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';

class ManageProductSerialsScreen extends ConsumerStatefulWidget {
  final Product product;
  final int quantity;
  final String purchaseItemId;

  const ManageProductSerialsScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.purchaseItemId,
  });

  @override
  ConsumerState<ManageProductSerialsScreen> createState() =>
      _ManageProductSerialsScreenState();
}

class _ManageProductSerialsScreenState
    extends ConsumerState<ManageProductSerialsScreen> {
  late bool _noSerials;
  late final bool _initialNoSerials;
  final List<String> _serials = [];
  late final List<String> _initialSerials;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final purchaseState = ref.read(addPurchaseProvider);
    final item = purchaseState.products.firstWhere(
      (p) => p.productId == widget.product.id,
      orElse: () => PurchaseItemProduct(
        id: '',
        productId: widget.product.id,
        name: widget.product.name,
        uom: '',
        quantity: 0,
        unitPrice: 0,
      ),
    );
    _noSerials = !item.requiresSerials;
    _initialNoSerials = _noSerials;

    final existingSerials = purchaseState.serials
        .where((s) => s.productId == widget.product.id)
        .map((s) => s.serialNumber)
        .toList();
    _serials.addAll(existingSerials);
    _initialSerials = List.unmodifiable(existingSerials);
  }

  bool get _canSave {
    if (_noSerials) {
      return _initialNoSerials != _noSerials || _initialSerials.isNotEmpty;
    }
    if (_serials.isEmpty) return false;
    if (_initialNoSerials != _noSerials) return true;
    if (_serials.length != _initialSerials.length) return true;
    for (int i = 0; i < _serials.length; i++) {
      if (_serials[i] != _initialSerials[i]) return true;
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

    if (_serials.any((s) => s.toLowerCase() == code.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El serial "$code" ya está en la lista.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_serials.length >= widget.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya se han registrado todos los seriales (${widget.quantity}) correspondientes a este producto.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _serials.add(code);
      _textController.clear();
    });
  }

  Future<void> _openScanner() async {
    if (_serials.length >= widget.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya se han registrado todos los seriales (${widget.quantity}) correspondientes a este producto.',
          ),
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

  Future<void> _onConfirm() async {
    final notifier = ref.read(addPurchaseProvider.notifier);

    notifier.setProductRequiresSerials(widget.product.id, !_noSerials);

    final now = DateTime.now();
    final newSerials = _noSerials
        ? <ProductSerial>[]
        : _serials
              .map(
                (s) => ProductSerial(
                  id: const Uuid().v4(),
                  purchaseItemId: widget.purchaseItemId,
                  productId: widget.product.id,
                  serialNumber: s,
                  status: 'in_stock',
                  createdAt: now,
                  updatedAt: now,
                ),
              )
              .toList();

    notifier.updateSerialsForProduct(widget.product.id, newSerials);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onConfirmWithCheck() async {
    if (!_noSerials && _serials.length < widget.quantity) {
      final proceed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Faltan seriales',
          contentText:
              'Has registrado ${_serials.length} de ${widget.quantity} seriales requeridos.\n\n¿Deseas continuar registrando más seriales o deseas hacerlo luego?',
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

    _onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final needed = widget.quantity;
    final assigned = _serials.length;
    final isComplete = assigned >= needed;

    final filteredSerials = _serials
        .where(
          (s) => s.toLowerCase().contains(_searchQuery.trim().toLowerCase()),
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
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.product.brand?.name != null ||
                    (widget.product.model != null &&
                        widget.product.model!.isNotEmpty))
                  Text(
                    [widget.product.brand?.name, widget.product.model]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
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
                            'Al activar esta opción, no se registrarán seriales para este producto y podrá guardarse la compra sin ellos.',
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
                          serial,
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
