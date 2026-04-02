import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/dynamic_material_symbol.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../domain/models/quote_product_source.dart';
import '../../../../profile/presentation/screens/verification_screen.dart';

class QuoteProductSourceCard extends StatefulWidget {
  final QuoteProductSource source;
  final double selectedQty;
  final String uom;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final ValueChanged<double> onQtyChanged;

  const QuoteProductSourceCard({
    super.key,
    required this.source,
    required this.selectedQty,
    required this.uom,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onQtyChanged,
  });

  @override
  State<QuoteProductSourceCard> createState() => _QuoteProductSourceCardState();
}

class _QuoteProductSourceCardState extends State<QuoteProductSourceCard> {
  bool? _isExpandedManual;

  @override
  void didUpdateWidget(QuoteProductSourceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedQty == 0 && widget.selectedQty > 0) {
      _isExpandedManual = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOwn = widget.source.sourceType == ProductSourceType.own;
    final maxQty = isOwn ? 999999.0 : widget.source.maxStock;

    // Access Level Parsing
    final isRestricted = !widget.source.isAccessible; // Locked + SnackBar
    // final isPartial = false; // Unlocked + Blurred Price
    final shouldShowSnackBar = isRestricted; // || isPartial;

    // Determine the checkbox state
    bool? checkboxState;
    if (widget.selectedQty == 0) {
      checkboxState = false;
    } else if (isOwn || widget.selectedQty == widget.source.maxStock) {
      checkboxState = true;
    } else {
      checkboxState = null; // Indeterminate
    }

    // Let the stepper visibility be toggleable
    final showStepper = _isExpandedManual ?? (widget.selectedQty > 0);

    // Visual State Logic for Trade Type
    final isWholesale = widget.source.tradeType == 'WHOLESALE';
    final badgeColor = isWholesale ? Colors.blue.shade50 : Colors.green.shade50;
    final badgeTextColor = isWholesale
        ? Colors.blue.shade700
        : Colors.green.shade700;
    final badgeText = isOwn
        ? 'PROPIO'
        : (isWholesale ? 'MAYORISTA' : 'MINORISTA');

    // Stock Styling
    final hasStock = isOwn ? true : widget.source.maxStock > 0;
    final stockColor = hasStock
        ? colors.onSecondaryContainer
        : colors.onErrorContainer;
    final stockBgColor = hasStock
        ? colors.secondaryContainer
        : colors.errorContainer;
    final formattedMaxStock =
        widget.source.maxStock.truncateToDouble() == widget.source.maxStock
        ? widget.source.maxStock.toInt().toString()
        : widget.source.maxStock.toString();

    final formattedSelectedQty =
        widget.selectedQty.truncateToDouble() == widget.selectedQty
        ? widget.selectedQty.toInt().toString()
        : widget.selectedQty.toString();

    final stockText = isOwn
        ? (widget.selectedQty > 0
              ? '$formattedSelectedQty/$formattedMaxStock ${widget.uom}'
              : '$formattedMaxStock ${widget.uom}')
        : (hasStock
              ? (widget.selectedQty > 0
                    ? '$formattedSelectedQty/$formattedMaxStock ${widget.uom}'
                    : '$formattedMaxStock ${widget.uom}')
              : 'Sin stock');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              if (shouldShowSnackBar) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 5),
                    content: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Requiere que estés verificado con una compañía o firma personal',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VerificationScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Verificar',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ],
                    ),
                  ),
                );
                return;
              }

              setState(() {
                _isExpandedManual = !showStepper;
              });

              if (!showStepper) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }
            },
            borderRadius: showStepper
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: isOwn
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isOwn
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!isOwn) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          widget.source.sourceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.source.location != null &&
                            widget.source.location!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.source.location!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        color: colors.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isOwn
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (shouldShowSnackBar)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ImageFiltered(
                            imageFilter: shouldShowSnackBar
                                ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
                                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Text(
                              CurrencyFormatter.format(widget.source.price),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DynamicMaterialSymbol(
                              symbolName: widget.source.uomIconName,
                              size: 14,
                              color: stockColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stockText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showStepper) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 16,
                bottom: 12,
                top: 8,
              ),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: checkboxState,
                          tristate: true,
                          activeColor: colors.primary,
                          side: BorderSide(
                            color: checkboxState == false
                                ? colors.onSurfaceVariant
                                : colors.primary,
                            width: 2,
                          ),
                          onChanged: shouldShowSnackBar
                              ? null
                              : (bool? newValue) {
                                  if (checkboxState == false) {
                                    widget.onSelectAll();
                                  } else {
                                    widget.onDeselectAll();
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        checkboxState == null ? 'Parcial' : 'Todos',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Cantidad:',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  EditableQuantityStepper(
                    value: widget.selectedQty,
                    min: 0,
                    max: maxQty,
                    onChanged: widget.onQtyChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
