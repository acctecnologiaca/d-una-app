import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../domain/models/supplier_order.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';

class ViewSupplierOrderDetailsTab extends ConsumerWidget {
  final SupplierOrder order;
  final double bottomPadding;

  const ViewSupplierOrderDetailsTab({
    super.key,
    required this.order,
    this.bottomPadding = 112.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Obtener proveedores y resolver nombre formateado
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];
    Supplier? matchedSupplier;
    for (final s in suppliers) {
      if (s.id == order.supplierId) {
        matchedSupplier = s;
        break;
      }
    }
    final supplierDisplayName = matchedSupplier != null
        ? matchedSupplier.name
        : order.supplierName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: bottomPadding,
        ),
        child: Column(
          children: [
            InfoBlock.text(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha de la orden',
              value: dateFormat.format(order.date),
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.warehouse_outlined,
              label: 'Proveedor',
              value: supplierDisplayName,
            ),
            if (order.branchName != null) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.location_on_outlined,
                label: 'Sucursal de canalización',
                value: order.branchName!,
              ),
            ],
            if (order.shippingMethodLabel != null) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.local_shipping_outlined,
                label: 'Método de envío',
                value: order.shippingMethodLabel!,
              ),
            ],
            if (order.receiverName != null) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.person_outline,
                label: 'Persona que retira',
                value: order.receiverName!,
              ),
            ],
            if (order.paymentMethod != null &&
                order.paymentMethod!.isNotEmpty) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.payment,
                label: 'Condiciones de pago',
                value: order.paymentMethod!,
              ),
            ],
            if (order.supplierFeedback != null &&
                order.supplierFeedback!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.chat_bubble_outline,
                label: 'Motivo de rechazo (Proveedor)',
                value: order.supplierFeedback!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
