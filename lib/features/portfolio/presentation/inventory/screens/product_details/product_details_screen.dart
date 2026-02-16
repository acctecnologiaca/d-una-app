import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import '../../../providers/products_provider.dart';
import '../../../../data/models/product_model.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _showAllSpecs = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    // Attempt to find the updated product from the provider list
    // If not found (e.g. loading, error, or not in list), fallback to widget.product
    final currentProduct =
        productsAsync.valueOrNull?.firstWhere(
          (element) => element.id == widget.product.id,
          orElse: () => widget.product,
        ) ??
        widget.product;

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del producto'),
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        titleSpacing:
            0, // Match default or adjust if needed to align with back button
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: colors.onSurface,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar Producto'),
                  content: const Text(
                    '¿Estás seguro de que deseas eliminar este producto?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(productsProvider.notifier)
                    .deleteProduct(currentProduct.id);
                if (context.mounted) {
                  context.pop(); // Pop details screen
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton(
          onPressed: () {
            context.go(
              '/portfolio/own-inventory/details/${currentProduct.id}/edit',
              extra: currentProduct,
            );
          },
          backgroundColor: colors.primaryContainer,
          // Icon color fix based on ClientDetailsScreen which uses onPrimaryContainer
          child: Icon(Icons.edit, color: colors.onPrimaryContainer),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Top Action Bar (Standardized)
            /*SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.price_check, size: 18),
                    label: const Text('Estimar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.request_quote_outlined, size: 18),
                    label: const Text('Cotizar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Movimientos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), */

            // Main Content Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image Area (Kept as it's specific to Product)
                  Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          (currentProduct.imageUrl != null &&
                              currentProduct.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: currentProduct.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: colors.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: colors.onSurfaceVariant,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Name & Brand (Centered Header)
                  Column(
                    children: [
                      if (currentProduct.brand != null)
                        Text(
                          currentProduct.brand!.name,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors
                                .onSurface, // Or primary? Client uses standard text for values.
                            // But for header, let's keep it distinct as it was.
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        currentProduct.name,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          // 24sp
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      if (currentProduct.model != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentProduct.model!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  if (currentProduct.category != null)
                    InfoBlock.text(
                      icon: Symbols.category,
                      label: 'Categoría',
                      value: currentProduct.category!.name,
                    ),

                  if (currentProduct.category != null)
                    const SizedBox(height: 24),

                  if (currentProduct.specs != null &&
                      currentProduct.specs!.isNotEmpty)
                    InfoBlock(
                      icon: Symbols.description,
                      label: 'Características',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentProduct.specs!,
                            style: textTheme.bodyLarge?.copyWith(
                              // Match InfoBlock.text value style
                              color: colors.onSurface,
                            ),
                            maxLines: _showAllSpecs ? null : 2,
                            overflow: _showAllSpecs
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  if ((currentProduct.specs!.length) > 100)
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllSpecs = !_showAllSpecs;
                              });
                            },
                            child: Text(
                              _showAllSpecs ? 'Ver menos' : 'Ver más',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                        //const SizedBox(height: 16),
                      ],
                    ),

                  InfoBlock(
                    icon: Icons.attach_money,
                    label: 'Precio de compra promedio',
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$101,67', // Static placeholder
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Calculado en base a tus últimas compras',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            Icons.help,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  InfoBlock.text(
                    icon: Symbols.package_2,
                    label: 'Existencia',
                    value: '15 Unidades', // Static placeholder
                  ),

                  const SizedBox(height: 32),

                  // "Mis compras" Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // No action
                      },
                      child: Text(
                        'Mis compras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
