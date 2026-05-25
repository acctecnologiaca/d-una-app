import 'package:flutter/material.dart';
import '../providers/purchase_details_provider.dart';
import 'purchase_added_product_card.dart';

class ViewPurchaseProductsTab extends StatelessWidget {
  final PurchaseDetailsData data;
  final String? highlightProductId;

  const ViewPurchaseProductsTab({
    super.key,
    required this.data,
    this.highlightProductId,
  });

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return Center(
        child: Text(
          'No hay productos registrados',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outlineVariant,
            fontSize: 16,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        itemCount: data.items.length,
        itemBuilder: (context, index) {
          final item = data.items[index];
          final hasMissingSerials =
              item.requiresSerials &&
              data.serials.where((s) => s.productId == item.productId).length <
                  item.quantity;

          Widget buildCard(Color? highlightColor) {
            return PurchaseAddedProductCard(
              item: item,
              isReadOnly: true,
              hasError: hasMissingSerials,
              backgroundColor: highlightColor,
              onDelete: () {},
              onEdit: () {},
              onAddSerials: () {},
              onQuantityChanged: (_) {},
            );
          }

          if (item.productId == highlightProductId) {
            return HighlightableWidget(
              builder: (context, highlightColor) => buildCard(highlightColor),
            );
          }
          return buildCard(null);
        },
      ),
    );
  }
}

class HighlightableWidget extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  const HighlightableWidget({super.key, required this.builder});

  @override
  State<HighlightableWidget> createState() => _HighlightableWidgetState();
}

class _HighlightableWidgetState extends State<HighlightableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 500ms per half-blink cycle
    );

    _colorAnimation = ColorTween(
      begin: null, // Let it default to the card's default background
      end: Colors.yellow.withValues(alpha: 0.25),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Repeat the blink animation (reverse is true to go back to transparent)
    _controller.repeat(reverse: true);
    
    // Stop blinking after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.stop();
        _controller.value = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return widget.builder(context, _colorAnimation.value);
      },
    );
  }
}
