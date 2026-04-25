import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../providers/view_quote_provider.dart';

class ViewQuoteClientTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteClientTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final quote = state.quote;
    if (quote == null) {
      return const Center(child: Text('No se pudo cargar la información del cliente'));
    }

    final isCompany = quote.clientType == 'company';
    final fullAddress = [
      quote.clientAddress,
      quote.clientCity,
      quote.clientState,
      quote.clientCountry,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fiscal Info Section
          Text(
            'Información fiscal',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          if (isCompany) ...[
            InfoBlock.text(
              icon: Icons.domain_outlined,
              label: 'Razón Social',
              value: quote.clientName ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'RIF/NIF/RUT',
              value: quote.clientTaxId ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección Fiscal',
              value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
            ),
          ] else ...[
            InfoBlock.text(
              icon: Icons.person_outline,
              label: 'Nombre y apellido',
              value: quote.clientName ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'Número de identificación',
              value: quote.clientTaxId ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección',
              value: fullAddress.isNotEmpty ? fullAddress : 'Dirección no registrada',
            ),
          ],

          const SizedBox(height: 32),

          // Contact Info Section
          Text(
            isCompany ? 'Contacto seleccionado' : 'Información de contácto',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          if (isCompany) ...[
            InfoBlock.text(
              icon: Icons.person_outline,
              label: 'Persona de contacto',
              value: quote.contactName ?? 'No especificado',
            ),
          ] else ...[
            InfoBlock.text(
              icon: Icons.contact_phone_outlined,
              label: 'Teléfono',
              value: _formatPhone(quote.clientPhone),
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.alternate_email_outlined,
              label: 'Correo Electrónico',
              value: quote.clientEmail ?? 'No registrado',
            ),
          ],
        ],
      ),
    );
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No registrado';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return phone;
  }
}
