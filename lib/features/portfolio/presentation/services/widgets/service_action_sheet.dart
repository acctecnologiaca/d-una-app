import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../data/models/service_model.dart';
import '../../../../../shared/widgets/service_list_item.dart';
import 'package:uuid/uuid.dart';
import '../../../../quotes/domain/models/quote_model.dart';
import '../../../../quotes/data/models/quote_item_service.dart';
import '../../../../quotes/presentation/create_quote/providers/create_quote_provider.dart';
import '../../../../quotes/presentation/create_quote/widgets/quote_service_sale_details_sheet.dart';

class ServiceActionSheet {
  static void show(BuildContext context, WidgetRef ref, ServiceModel service) {
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
          label: 'Agregar a cotización nueva',
          onTap: () async {
            context.pop();
            
            // 1. Reset the provider to start a new quote
            ref.read(createQuoteProvider.notifier).reset();
            
            // 2. Show the details sheet
            final result = await QuoteServiceSaleDetailsSheet.show(
              context,
              service: service,
            );
            if (result == null) return; // User cancelled
            
            // 3. Add the service to the quote
            ref.read(createQuoteProvider.notifier).addService(result);
            
            // 4. Navigate to the create quote screen on the Services tab (tab=1)
            if (context.mounted) {
              context.push('/quotes/create?tab=1');
            }
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () async {
            context.pop();
            final selectedQuote = await context.push<Quote>(
              '/quotes/select',
              extra: {'rejected', 'finalized', 'cancelled'},
            );
            if (selectedQuote == null || !context.mounted) return;

            await ref
                .read(createQuoteProvider.notifier)
                .loadQuote(selectedQuote.id);

            if (context.mounted) {
              await _addServiceToExistingQuote(context, ref, service);
            }
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

  static Future<void> _addServiceToExistingQuote(
    BuildContext context,
    WidgetRef ref,
    ServiceModel service,
  ) async {
    final quoteState = ref.read(createQuoteProvider);
    final existingServices = quoteState.services;

    // Check if this service is already present in the current quote
    QuoteItemService? existingItem;
    for (final s in existingServices) {
      if (s.serviceId == service.id) {
        existingItem = s;
        break;
      }
    }

    if (existingItem != null) {
      final newQty = existingItem.quantity + 1.0;
      final taxAmount = existingItem.unitPrice * (existingItem.taxRate / 100);
      final totalPrice = (existingItem.unitPrice + taxAmount) * newQty;

      final updatedItem = existingItem.copyWith(
        quantity: newQty,
        taxAmount: taxAmount,
        totalPrice: totalPrice,
      );

      ref.read(createQuoteProvider.notifier).updateService(updatedItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'Este servicio ya se encuentra en la cotización. Se ha actualizado la cantidad a ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 2)}',
            ),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );

        final quoteId = quoteState.quote?.id;
        if (quoteId != null) {
          context.push('/quotes/edit/$quoteId?tab=1');
        } else {
          context.push('/quotes/create?tab=1');
        }
      }
      return;
    }

    if (!context.mounted) return;

    final result = await QuoteServiceSaleDetailsSheet.show(
      context,
      service: service,
    );

    if (result == null) return;

    final quoteId = ref.read(createQuoteProvider).quote?.id ?? 'draft';
    final generatedId = const Uuid().v4();
    final updatedResult = result.copyWith(
      id: result.id.isEmpty ? generatedId : result.id,
      quoteId: result.quoteId.isEmpty ? quoteId : result.quoteId,
    );

    ref.read(createQuoteProvider.notifier).addService(updatedResult);

    if (context.mounted) {
      final quoteId = ref.read(createQuoteProvider).quote?.id;
      if (quoteId != null) {
        context.push('/quotes/edit/$quoteId?tab=1');
      } else {
        context.push('/quotes/create?tab=1');
      }
    }
  }
}
