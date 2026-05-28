import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../domain/models/supplier_order.dart';

class ViewSupplierOrderDetailsTab extends StatelessWidget {
  final SupplierOrder order;

  const ViewSupplierOrderDetailsTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 100),
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
              value: order.supplierName,
            ),
            if (order.branchName != null) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.location_on_outlined,
                label: 'Sucursal del Proveedor',
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
                label: 'Persona que recibe/retira',
                value: order.receiverName!,
              ),
            ],
            if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.payment,
                label: 'Condiciones de pago',
                value: order.paymentMethod!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
