import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../data/models/service_model.dart';
import '../../../../../shared/widgets/service_list_item.dart';

class ServiceActionSheet {
  static void show(BuildContext context, ServiceModel service) {
    CustomActionSheet.show(
      context: context,
      title: 'Servicio seleccionado',
      content: ServiceListItem(
        service: service,
        onTap: () {}, // No action in sheet
      ),
      actions: [
        BottomSheetActionItem(
          icon: Icons.request_quote_outlined,
          label: 'Cotizar a cliente',
          onTap: () {
            context.pop();
            // No-op for now
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () {
            context.pop();
            // No-op for now
          },
        ),
        BottomSheetActionItem(
          icon: Icons.info_outline,
          label: 'Detalles del servicio',
          onTap: () {
            context.pop();
            context.push(
              '/portfolio/own-services/details/${service.id}',
              extra: service,
            );
          },
        ),
      ],
    );
  }
}
