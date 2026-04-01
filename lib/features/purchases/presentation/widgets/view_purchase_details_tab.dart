import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import '../providers/purchase_details_provider.dart';

class ViewPurchaseDetailsTab extends StatelessWidget {
  final PurchaseDetailsData data;

  const ViewPurchaseDetailsTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final purchase = data.purchase;
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormatter.format(purchase.date);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: 100,
        ),
        child: Column(
          children: [
            InfoBlock.text(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha de compra',
              value: formattedDate,
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.groups_outlined,
              label: 'Proveedor',
              value: purchase.supplierName ?? 'Desconocido',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: purchase.documentType == 'invoice'
                  ? Icons.receipt_long_outlined
                  : Icons.receipt_outlined,
              label: 'Tipo de documento',
              value: purchase.documentType == 'invoice'
                  ? 'Factura'
                  : (purchase.documentType == 'delivery_note'
                        ? 'Nota de Entrega'
                        : purchase.documentType),
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.tag,
              label: 'Número de documento',
              value: purchase.documentNumber,
            ),
          ],
        ),
      ),
    );
  }
}
