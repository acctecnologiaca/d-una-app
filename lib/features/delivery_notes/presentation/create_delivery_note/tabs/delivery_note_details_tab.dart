import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/collapsible_card_block.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/quotes/data/models/quote.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show QuoteStatus;
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/quotes/presentation/view_quote/providers/view_quote_provider.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../providers/create_delivery_note_provider.dart';

final clientActiveQuotesProvider = FutureProvider.autoDispose
    .family<List<Quote>, String>((ref, clientId) async {
      if (clientId.trim().isEmpty) return [];
      final repo = ref.watch(quotesRepositoryProvider);
      final quotes = await repo.getQuotes(
        clientId: clientId,
        includeArchived: false,
      );
      return quotes
          .where((q) => q.status != 'finalized' && q.status != 'cancelled')
          .toList();
    });

class DeliveryNoteDetailsTab extends ConsumerStatefulWidget {
  const DeliveryNoteDetailsTab({super.key});

  @override
  ConsumerState<DeliveryNoteDetailsTab> createState() =>
      _DeliveryNoteDetailsTabState();
}

class _DeliveryNoteDetailsTabState
    extends ConsumerState<DeliveryNoteDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _clientPoController;
  late final TextEditingController _tagController;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ExpansibleController _controllerClient = ExpansibleController();
  final ExpansibleController _controllerEmission = ExpansibleController();
  final ExpansibleController _controllerTag = ExpansibleController();
  int? _expandedIndex = 0;

  void _onExpandBlock(int index) {
    if (_expandedIndex != index) {
      if (_expandedIndex == 0 && _controllerClient.isExpanded) {
        _controllerClient.collapse();
      }
      if (_expandedIndex == 1 && _controllerEmission.isExpanded) {
        _controllerEmission.collapse();
      }
      if (_expandedIndex == 2 && _controllerTag.isExpanded) {
        _controllerTag.collapse();
      }
      setState(() => _expandedIndex = index);
    }
  }

  void _onCollapseBlock(int index) {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
    }
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _dateController = TextEditingController(
      text: _dateFormat.format(state.date),
    );
    _clientPoController = TextEditingController(
      text: state.clientPoNumber ?? '',
    );
    _tagController = TextEditingController(text: state.tag ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _clientPoController.dispose();
    _tagController.dispose();
    _controllerClient.dispose();
    _controllerEmission.dispose();
    _controllerTag.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = ref.read(createDeliveryNoteProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      ref.read(createDeliveryNoteProvider.notifier).setDate(picked);
      _dateController.text = _dateFormat.format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DeliveryNoteCreateState>(createDeliveryNoteProvider, (
      previous,
      next,
    ) {
      final formattedDate = _dateFormat.format(next.date);
      if (_dateController.text != formattedDate) {
        _dateController.text = formattedDate;
      }
      if (next.clientPoNumber != previous?.clientPoNumber &&
          _clientPoController.text != (next.clientPoNumber ?? '')) {
        _clientPoController.text = next.clientPoNumber ?? '';
      }
      if (next.tag != previous?.tag &&
          _tagController.text != (next.tag ?? '')) {
        _tagController.text = next.tag ?? '';
      }
    });

    final state = ref.watch(createDeliveryNoteProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final activeClients = clientsAsync.value ?? [];

    final selectedClient =
        activeClients.where((c) => c.id == state.clientId).firstOrNull ??
        (state.clientId != null
            ? Client(
                id: state.clientId!,
                name: state.clientName ?? '',
                userId: '',
                type: 'company',
                createdAt: DateTime.now(),
                isArchived: true,
              )
            : null);

    final clients = [
      ...activeClients,
      if (selectedClient != null &&
          !activeClients.any((c) => c.id == selectedClient.id))
        selectedClient,
    ];

    final contacts = selectedClient?.contacts ?? [];
    final selectedContact = contacts
        .where((c) => c.id == state.contactId)
        .firstOrNull;

    final isCompany =
        selectedClient != null && selectedClient.type == 'company';

    final clientQuotes =
        (selectedClient != null && selectedClient.id.isNotEmpty)
        ? ref
                  .watch(clientActiveQuotesProvider(selectedClient.id))
                  .valueOrNull ??
              []
        : <Quote>[];
    final selectedQuoteItem = clientQuotes.cast<Quote?>().firstWhere(
      (q) => q?.id == state.quoteId,
      orElse: () => null,
    );

    final clientSubtitle = selectedClient != null
        ? '${selectedClient.name} • ${selectedClient.taxId ?? "Sin RIF"}${selectedContact != null ? " • ${selectedContact.name}" : ""}${state.quoteId != null ? " • Cotización vinculada" : ""}'
        : 'Pendiente de seleccionar cliente';

    final emissionSubtitle =
        'Emisión: ${_dateFormat.format(state.date)}${state.clientPoNumber != null && state.clientPoNumber!.isNotEmpty ? " • OC: ${state.clientPoNumber}" : ""}';

    final tagSubtitle = (state.tag != null && state.tag!.trim().isNotEmpty)
        ? state.tag!
        : 'Pendiente de etiqueta';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, FabScrollPadding.none),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Bloque Cliente, Contacto y Cotización Vinculada
          CollapsibleCardBlock(
            controller: _controllerClient,
            initiallyExpanded: _expandedIndex == 0,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(0) : _onCollapseBlock(0),
            leading: const Icon(Symbols.person, size: 22),
            title: 'Cliente y Contacto',
            subtitle: clientSubtitle,
            isComplete: state.clientId != null && state.clientId!.isNotEmpty,
            children: [
              CustomDropdown<Client>(
                value: selectedClient,
                items: clients,
                label: 'Nombre o razón social',
                searchable: true,
                itemLabelBuilder: (c) => c.alias != null && c.alias!.isNotEmpty
                    ? '${c.name} (${c.alias})'
                    : c.name,
                showAddOption: true,
                addOptionValue: Client(
                  id: '___ADD___',
                  name: '___ADD___',
                  userId: 'dummy',
                  type: 'company',
                  createdAt: DateTime.now(),
                ),
                addOptionLabel: 'Agregar cliente',
                onAddPressed: () async {
                  final previousClients = clientsAsync.value ?? [];
                  final noteId = state.id;
                  final returnPath = noteId != null
                      ? '/delivery-notes/edit/$noteId?tab=0'
                      : '/delivery-notes/create?tab=0';
                  final returnToParam = Uri.encodeComponent(returnPath);
                  await context.push('/clients/add?returnTo=$returnToParam');

                  final newClientsResult = await ref.refresh(
                    clientsProvider.future,
                  );

                  if (mounted &&
                      newClientsResult.length > previousClients.length) {
                    final oldIds = previousClients.map((c) => c.id).toSet();
                    final newClient = newClientsResult.firstWhere(
                      (c) => !oldIds.contains(c.id),
                      orElse: () => newClientsResult.last,
                    );
                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .setClient(newClient);
                  }
                },
                onChanged: (client) {
                  if (client != null) {
                    if (state.clientId != client.id) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .setClient(client);
                    }
                  } else {
                    ref.read(createDeliveryNoteProvider.notifier).clearClient();
                  }
                },
              ),

              if (selectedClient != null) ...[
                const SizedBox(height: 16),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'Identificación Fiscal',
                  value: selectedClient.taxId ?? 'No especificada',
                ),
                const SizedBox(height: 16),
                InfoBlock.text(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección Fiscal',
                  value: [
                    selectedClient.address,
                    selectedClient.city,
                    selectedClient.state,
                    selectedClient.country,
                  ].where((e) => e != null && e.isNotEmpty).join(', '),
                ),
                if (selectedClient.phone != null &&
                    selectedClient.phone!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InfoBlock.text(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: selectedClient.phone!,
                  ),
                ],
                if (selectedClient.email != null &&
                    selectedClient.email!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InfoBlock.text(
                    icon: Icons.email_outlined,
                    label: 'Correo Electrónico',
                    value: selectedClient.email!,
                  ),
                ],
              ],

              if (selectedClient == null ||
                  selectedClient.type == 'company') ...[
                const SizedBox(height: 16),
                CustomDropdown<Contact>(
                  value: isCompany ? selectedContact : null,
                  items: isCompany ? contacts : const [],
                  label: 'Persona de contacto',
                  searchable: true,
                  itemLabelBuilder: (c) => c.role != null && c.role!.isNotEmpty
                      ? '${c.name} — ${c.role}'
                      : c.name,
                  enabled: isCompany,
                  showAddOption: isCompany,
                  addOptionValue: Contact(
                    id: '___ADD___',
                    name: '___ADD___',
                    clientId: selectedClient?.id ?? '',
                    isPrimary: false,
                    createdAt: DateTime.now(),
                  ),
                  addOptionLabel: 'Agregar contacto',
                  onAddPressed: !isCompany
                      ? null
                      : () async {
                          final previousContacts = selectedClient.contacts;
                          final noteId = state.id;
                          final returnPath = noteId != null
                              ? '/delivery-notes/edit/$noteId?tab=0'
                              : '/delivery-notes/create?tab=0';
                          final returnToParam = Uri.encodeComponent(returnPath);
                          await context.push(
                            '/clients/${selectedClient.id}/contacts/add?returnTo=$returnToParam',
                            extra: selectedClient.name,
                          );

                          final newClientsResult = await ref.refresh(
                            clientsProvider.future,
                          );

                          if (mounted) {
                            final updatedClient = newClientsResult.firstWhere(
                              (c) => c.id == selectedClient.id,
                              orElse: () => selectedClient,
                            );
                            if (updatedClient.contacts.length >
                                previousContacts.length) {
                              final oldIds = previousContacts
                                  .map((c) => c.id)
                                  .toSet();
                              final newContact = updatedClient.contacts
                                  .firstWhere(
                                    (c) => !oldIds.contains(c.id),
                                    orElse: () => updatedClient.contacts.last,
                                  );
                              ref
                                  .read(createDeliveryNoteProvider.notifier)
                                  .setContact(newContact.id, newContact.name);
                            }
                          }
                        },
                  onChanged: (contact) {
                    if (contact != null) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .setContact(contact.id, contact.name);
                    } else {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .clearContact();
                    }
                  },
                ),
              ],

              if (isCompany && selectedContact != null) ...[
                if (selectedContact.phone != null &&
                    selectedContact.phone!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InfoBlock.text(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono Contacto',
                    value: selectedContact.phone!,
                  ),
                ],
                if (selectedContact.email != null &&
                    selectedContact.email!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InfoBlock.text(
                    icon: Icons.email_outlined,
                    label: 'Correo Contacto',
                    value: selectedContact.email!,
                  ),
                ],
              ],

              // Vincular cotización (Opcional)
              if (selectedClient != null && clientQuotes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Cotización asociada',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomDropdown<Quote>(
                  value: selectedQuoteItem,
                  items: clientQuotes,
                  label: 'Vincular cotización (Opcional)',
                  searchable: true,
                  itemLabelBuilder: (q) =>
                      '${q.quoteNumber ?? (q.id.length >= 8 ? q.id.substring(0, 8) : q.id)} — ${CurrencyFormatter.format(q.total)} USD (${QuoteStatus.fromDbValue(q.status).label})',
                  onChanged: (quote) async {
                    if (quote == null) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .setLinkedQuote(null);
                      return;
                    }
                    var fullQuote = await ref
                        .read(quotesRepositoryProvider)
                        .getQuoteWithDetails(quote.id);
                    if (!context.mounted) return;

                    // 1. Salvaguarda de Monetización y Proveedores Afiliados
                    final ocRepo = ref.read(supplierOrdersRepositoryProvider);
                    final supplierStatuses = await ocRepo
                        .getQuoteSuppliersOcStatus(fullQuote.id);

                    if (supplierStatuses.isNotEmpty) {
                      final orders = await ocRepo.getSupplierOrdersByQuoteId(
                        fullQuote.id,
                      );
                      final approvedSupplierIds = orders
                          .where(
                            (o) =>
                                o.status == SupplierOrderStatus.approved ||
                                o.status == SupplierOrderStatus.finalized,
                          )
                          .map((o) => o.supplierId)
                          .toSet();

                      final pendingSuppliers = supplierStatuses
                          .where(
                            (s) => !approvedSupplierIds.contains(s.supplierId),
                          )
                          .toList();

                      if (pendingSuppliers.isNotEmpty && context.mounted) {
                        await CustomDialog.show(
                          context: context,
                          dialog: CustomDialog.confirmation(
                            icon: Symbols.lock,
                            title: 'Orden de Compra Requerida',
                            contentText:
                                'Esta cotización contiene productos de proveedores afiliados (${pendingSuppliers.map((s) => s.supplierName).join(', ')}) que no cuentan con una Orden de Compra aprobada o finalizada en la plataforma.\n\nPara garantizar el despacho formal y la correcta trazabilidad, las órdenes de compra deben estar aprobadas por sus respectivos proveedores para generar la Nota de Entrega.',
                            actions: [
                              Builder(
                                builder: (c) => TextButton(
                                  onPressed: () => Navigator.of(c).pop(),
                                  child: const Text('Entendido'),
                                ),
                              ),
                            ],
                          ),
                        );
                        setState(() {});
                        return;
                      }
                    }

                    if (!context.mounted) return;

                    // 2. Aprobación Consentida de Cotización
                    if (fullQuote.status != QuoteStatus.approved.dbValue) {
                      final quoteNumber =
                          fullQuote.quoteNumber ??
                          (fullQuote.id.length >= 8
                              ? fullQuote.id.substring(0, 8)
                              : fullQuote.id);
                      final statusLabel = QuoteStatus.fromDbValue(
                        fullQuote.status,
                      ).label;

                      final confirmApproval = await CustomDialog.show<bool>(
                        context: context,
                        dialog: CustomDialog.confirmation(
                          icon: Symbols.check_circle,
                          title: 'Aprobar Cotización para Despacho',
                          contentText:
                              'La cotización $quoteNumber se encuentra en estatus \'$statusLabel\'. Para poder generar la nota de entrega y reservar formalmente el inventario, la cotización debe ser aprobada.\n\n¿Deseas aprobarla y continuar con la nota de entrega?',
                          actions: [
                            Builder(
                              builder: (c) => TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            Builder(
                              builder: (c) => FilledButton(
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text('Aprobar y Despachar'),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmApproval != true) {
                        setState(() {});
                        return;
                      }
                      if (!context.mounted) return;

                      await ref
                          .read(quotesRepositoryProvider)
                          .updateQuoteStatus(
                            fullQuote.id,
                            QuoteStatus.approved.dbValue,
                          );
                      ref.invalidate(quotesListProvider);
                      ref.invalidate(clientActiveQuotesProvider);
                      ref.invalidate(viewQuoteProvider(fullQuote.id));

                      fullQuote = await ref
                          .read(quotesRepositoryProvider)
                          .getQuoteWithDetails(quote.id);
                      if (!context.mounted) return;
                    }

                    if (state.items.isNotEmpty) {
                      final replace = await CustomDialog.show<bool>(
                        context: context,
                        dialog: CustomDialog.confirmation(
                          title: 'Cargar productos',
                          contentText:
                              '¿Deseas reemplazar los productos actuales de la nota con los productos de la cotización seleccionada?',
                          actions: [
                            Builder(
                              builder: (c) => TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Solo vincular'),
                              ),
                            ),
                            Builder(
                              builder: (c) => FilledButton(
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text('Reemplazar'),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      if (replace == true) {
                        ref
                            .read(createDeliveryNoteProvider.notifier)
                            .loadFromQuote(fullQuote);
                      } else {
                        ref
                            .read(createDeliveryNoteProvider.notifier)
                            .setLinkedQuote(fullQuote);
                      }
                    } else {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .loadFromQuote(fullQuote);
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Bloque Emisión y Referencias
          CollapsibleCardBlock(
            controller: _controllerEmission,
            initiallyExpanded: _expandedIndex == 1,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(1) : _onCollapseBlock(1),
            leading: const Icon(Symbols.calendar_today, size: 22),
            title: 'Emisión y Referencias',
            subtitle: emissionSubtitle,
            isComplete: true,
            children: [
              CustomTextField(
                controller: _dateController,
                label: 'Fecha de emisión*',
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _clientPoController,
                label: 'Orden de compra del cliente (Opcional)',
                onChanged: (val) {
                  ref
                      .read(createDeliveryNoteProvider.notifier)
                      .setClientPoNumber(
                        val.trim().isEmpty ? null : val.trim(),
                      );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Bloque Identificación
          CollapsibleCardBlock(
            controller: _controllerTag,
            initiallyExpanded: _expandedIndex == 2,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(2) : _onCollapseBlock(2),
            leading: const Icon(Symbols.label, size: 22),
            title: 'Identificación',
            subtitle: tagSubtitle,
            isComplete: state.tag != null && state.tag!.trim().isNotEmpty,
            children: [
              CustomTextField(
                controller: _tagController,
                label: 'Etiqueta*',
                helperText:
                    'Descripción corta que identifique a la nota de entrega.',
                maxLength: 35,
                onChanged: (val) {
                  ref
                      .read(createDeliveryNoteProvider.notifier)
                      .setTag(val.trim().isEmpty ? null : val.trim());
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}
