import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/features/purchases/domain/models/models.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_product_serial_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';

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
  bool _noSerials = false;
  final List<String> _serials = []; // Dummy initial list
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load existing serials for this product if any
    final existingSerials = ref.read(addPurchaseProvider).serials
        .where((s) => s.productId == widget.product.id)
        .map((s) => s.serialNumber)
        .toList();
    _serials.addAll(existingSerials);
  }

  void _removeSerial(int index) {
    setState(() {
      _serials.removeAt(index);
    });
  }

  Future<void> _onConfirm() async {
    final notifier = ref.read(addPurchaseProvider.notifier);
    
    // Create new serial objects
    final now = DateTime.now();
    final newSerials = _serials.map((s) => ProductSerial(
      id: const Uuid().v4(),
      purchaseItemId: widget.purchaseItemId,
      productId: widget.product.id,
      serialNumber: s,
      status: 'in_stock',
      createdAt: now,
      updatedAt: now,
    )).toList();

    // Update provider (we need a way to set the entire list or replace)
    // For now, I'll use a hack or suggest adding a specific method to the notifier
    // state = state.copyWith(serials: [...otherSerials, ...newSerials]);
    // Since I can't modify the state directly here, I'll assume I'll add a method to the notifier.
    notifier.updateSerialsForProduct(widget.product.id, newSerials);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onConfirmWithCheck() async {
    if (!_noSerials && _serials.length < widget.quantity) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Faltan seriales'),
          content: Text(
              'Has registrado ${_serials.length} de ${widget.quantity} seriales requeridos.\n\n¿Deseas continuar registrando solo estos seriales por ahora o quieres seguir agregando?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Seguir agregando'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar lo registrado'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _onConfirm();
  }

  Future<void> _showAddSerialSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AddProductSerialSheet(),
    );

    if (result != null && result.isNotEmpty) {
      if (_serials.contains(result)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El serial "$result" ya está en la lista.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        setState(() {
          _serials.add(result);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredSerials = _serials
        .where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestionar seriales',
        isSearchable: true,
        onSearchChanged: (val) => setState(() => _searchQuery = val),
        onSearchClosed: () => setState(() => _searchQuery = ''),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            // Product info section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Producto',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StandardListItem(
                    padding: EdgeInsets.zero,
                    overline: Text(widget.product.brand?.name ?? 'Sin marca'),
                    title: widget.product.name,
                    subtitle: Text(widget.product.model ?? 'Sin modelo'),
                    trailing: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Icon(Icons.image, size: 24),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image, size: 24),
                            )
                          : Icon(Icons.image, color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),

            // No serials switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
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
            ),

            const SizedBox(height: 16),

            // Serials stats
            if (!_noSerials) ...[
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'Seriales registrados: '),
                    TextSpan(
                      text: '${_serials.length} de ${widget.quantity} unidades',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Serials List
              if (_serials.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    'No has agregado seriales.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSerials.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final serial = filteredSerials[index];
                    return StandardListItem(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.qr_code_2),
                      title: serial,
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _removeSerial(_serials.indexOf(serial)),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0, right: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_noSerials) ...[
              FloatingActionButton(
                heroTag: 'add_serial_fab',
                onPressed: _showAddSerialSheet,
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
            ],
            CustomExtendedFab(
              onPressed: _onConfirmWithCheck,
              label: 'Confirmar',
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}
