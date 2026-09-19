import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/collapsible_card_block.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_category_sheet.dart';
import '../providers/create_quote_provider.dart';

class QuoteDetailsTab extends ConsumerStatefulWidget {
  const QuoteDetailsTab({super.key});

  @override
  ConsumerState<QuoteDetailsTab> createState() => _QuoteDetailsTabState();
}

class _QuoteDetailsTabState extends ConsumerState<QuoteDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _validityQuantityController;
  late final TextEditingController _labelController;
  late final TextEditingController _notesController;
  String _validityPeriod = 'Días';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ExpansibleController _controllerClient = ExpansibleController();
  final ExpansibleController _controllerEmission = ExpansibleController();
  final ExpansibleController _controllerClassification = ExpansibleController();
  int? _expandedIndex = 0; // Inicia con Cliente desplegado

  void _onExpandBlock(int index) {
    if (_expandedIndex != index) {
      if (_expandedIndex == 0 && _controllerClient.isExpanded) {
        _controllerClient.collapse();
      }
      if (_expandedIndex == 1 && _controllerEmission.isExpanded) {
        _controllerEmission.collapse();
      }
      if (_expandedIndex == 2 && _controllerClassification.isExpanded) {
        _controllerClassification.collapse();
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
    final quoteState = ref.read(createQuoteProvider);
    _dateController = TextEditingController(
      text: _dateFormat.format(quoteState.dateIssued),
    );
    _validityQuantityController = TextEditingController(
      text: quoteState.validityDays.toString(),
    );
    _labelController = TextEditingController(text: quoteState.label ?? '');
    _notesController = TextEditingController(text: quoteState.notes ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _validityQuantityController.dispose();
    _labelController.dispose();
    _notesController.dispose();
    _controllerClient.dispose();
    _controllerEmission.dispose();
    _controllerClassification.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuoteState>(createQuoteProvider, (previous, next) {
      final formattedDate = _dateFormat.format(next.dateIssued);
      if (_dateController.text != formattedDate) {
        _dateController.text = formattedDate;
      }
      final validityText = next.validityDays.toString();
      if (_validityQuantityController.text != validityText) {
        _validityQuantityController.text = validityText;
      }
      if (previous?.label != next.label &&
          _labelController.text != (next.label ?? '')) {
        _labelController.text = next.label ?? '';
      }
      if (previous?.notes != next.notes &&
          _notesController.text != (next.notes ?? '')) {
        _notesController.text = next.notes ?? '';
      }
    });

    final state = ref.watch(createQuoteProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final activeClients = clientsAsync.value ?? [];

    final selectedClient =
        activeClients.where((c) => c.id == state.clientId).firstOrNull ??
        (state.quote?.clientId == state.clientId && state.clientId != null
            ? Client(
                id: state.clientId!,
                name: state.quote?.clientName ?? '',
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

    final categoriesAsync = ref.watch(categoriesProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. Bloque Cliente y Contacto
          CollapsibleCardBlock(
            controller: _controllerClient,
            initiallyExpanded: _expandedIndex == 0,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(0) : _onCollapseBlock(0),
            leading: const Icon(Symbols.person, size: 22),
            title: 'Cliente y Contacto',
            subtitle: selectedClient != null
                ? '${selectedClient.name} • ${selectedClient.taxId ?? "Sin RIF"}${selectedContact != null ? " • ${selectedContact.name}" : ""}'
                : 'Pendiente de seleccionar cliente',
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
                  final quoteId = state.quote?.id;
                  final returnPath = quoteId != null
                      ? '/quotes/edit/$quoteId?tab=0'
                      : '/quotes/create?tab=0';
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
                    ref.read(createQuoteProvider.notifier).setClient(newClient);
                  }
                },
                onChanged: (client) {
                  if (client != null) {
                    if (state.clientId != client.id) {
                      ref.read(createQuoteProvider.notifier).setClient(client);
                    }
                  } else {
                    ref.read(createQuoteProvider.notifier).clearClient();
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
                  const SizedBox(height: 8),
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
                          final quoteId = state.quote?.id;
                          final returnPath = quoteId != null
                              ? '/quotes/edit/$quoteId?tab=0'
                              : '/quotes/create?tab=0';
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
                                  .read(createQuoteProvider.notifier)
                                  .setContact(newContact.id, newContact.name);
                            }
                          }
                        },
                  onChanged: (contact) {
                    if (contact != null) {
                      ref
                          .read(createQuoteProvider.notifier)
                          .setContact(contact.id, contact.name);
                    } else {
                      ref.read(createQuoteProvider.notifier).clearContact();
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (isCompany && selectedContact != null) ...[
                if (selectedContact.phone != null &&
                    selectedContact.phone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                const SizedBox(height: 8),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 2. Bloque Emisión, Vigencia y Asesor
          CollapsibleCardBlock(
            controller: _controllerEmission,
            initiallyExpanded: _expandedIndex == 1,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(1) : _onCollapseBlock(1),
            leading: const Icon(Symbols.calendar_today, size: 22),
            title: 'Emisión, Vigencia y Asesor',
            subtitle:
                'Emisión: ${_dateFormat.format(state.dateIssued)} • ${state.validityDays} días • Asesor: ${state.advisorName ?? "Sin asesor"}',
            isComplete: state.validityDays > 0 && state.advisorId != null,
            children: [
              CustomTextField(
                label: 'Fecha de emisión*',
                controller: _dateController,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.dateIssued,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateController.text = _dateFormat.format(date);
                    ref
                        .read(createQuoteProvider.notifier)
                        .setDetails(dateIssued: date);
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: 'Cantidad*',
                      controller: _validityQuantityController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final qty = int.tryParse(val) ?? 0;
                        int multiplier = _validityPeriod == 'Días'
                            ? 1
                            : (_validityPeriod == 'Semanas' ? 7 : 30);
                        ref
                            .read(createQuoteProvider.notifier)
                            .setDetails(validity: qty * multiplier);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CustomDropdown<String>(
                      value: _validityPeriod,
                      items: const ['Días', 'Semanas', 'Meses'],
                      label: 'Período',
                      itemLabelBuilder: (item) => item,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _validityPeriod = val);
                          final qty =
                              int.tryParse(_validityQuantityController.text) ??
                              0;
                          int multiplier = _validityPeriod == 'Días'
                              ? 1
                              : (_validityPeriod == 'Semanas' ? 7 : 30);
                          ref
                              .read(createQuoteProvider.notifier)
                              .setDetails(validity: qty * multiplier);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              collaboratorsAsync.when(
                data: (fetchedCollaborators) {
                  final defaultCollab =
                      fetchedCollaborators
                          .where((c) => c.isUserRecord)
                          .firstOrNull ??
                      fetchedCollaborators.firstOrNull;
                  final selectedCollab =
                      fetchedCollaborators
                          .where((c) => c.id == state.advisorId)
                          .firstOrNull ??
                      defaultCollab;
                  return CustomDropdown<Collaborator>(
                    value: selectedCollab,
                    items: fetchedCollaborators,
                    label: 'Asesor responsable (colaborador)',
                    searchable: true,
                    showAddOption: true,
                    addOptionLabel: 'Agregar colaborador',
                    addOptionValue: Collaborator(
                      id: '___ADD___',
                      userId: '',
                      fullName: '___ADD___',
                      isActive: true,
                    ),
                    itemLabelBuilder: (c) => c.fullName,
                    onAddPressed: () async {
                      final newCollab = await context.push<Collaborator?>(
                        '/collaborators/add',
                      );
                      if (newCollab != null && mounted) {
                        ref
                            .read(createQuoteProvider.notifier)
                            .setDetails(
                              advisorId: newCollab.id,
                              advisorName: newCollab.fullName,
                            );
                        ref.invalidate(collaboratorsProvider);
                      }
                    },
                    onChanged: (c) {
                      if (c != null && c.id != '___ADD___') {
                        ref
                            .read(createQuoteProvider.notifier)
                            .setDetails(
                              advisorId: c.id,
                              advisorName: c.fullName,
                            );
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => FriendlyErrorWidget(error: e),
              ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Bloque Clasificación y Notas
          CollapsibleCardBlock(
            controller: _controllerClassification,
            initiallyExpanded: _expandedIndex == 2,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(2) : _onCollapseBlock(2),
            leading: const Icon(Symbols.category, size: 22),
            title: 'Clasificación y Notas',
            subtitle:
                '${state.categoryName ?? "Sin categoría"} • ${state.label?.trim().isNotEmpty == true ? state.label : "Sin etiqueta"}${state.notes?.trim().isNotEmpty == true ? " • Con notas" : ""}',
            isComplete:
                state.categoryId != null &&
                state.label != null &&
                state.label!.trim().isNotEmpty,
            children: [
              categoriesAsync.when(
                data: (categories) => CustomDropdown<Category>(
                  value: categories
                      .where((c) => c.id == state.categoryId)
                      .firstOrNull,
                  items: categories,
                  label: 'Categoría',
                  searchable: true,
                  showAddOption: true,
                  addOptionLabel: 'Agregar categoría',
                  addOptionValue: Category(
                    id: '___ADD___',
                    name: '___ADD___',
                    type: '',
                  ),
                  itemLabelBuilder: (c) => c.name,
                  onAddPressed: () async {
                    final newCategory = await AddEditCategorySheet.show(
                      context,
                    );
                    if (newCategory != null && mounted) {
                      ref
                          .read(createQuoteProvider.notifier)
                          .setDetails(
                            categoryId: newCategory.id,
                            categoryName: newCategory.name,
                          );
                      ref.invalidate(categoriesProvider);
                    }
                  },
                  onChanged: (c) {
                    if (c != null && c.id != '___ADD___') {
                      ref
                          .read(createQuoteProvider.notifier)
                          .setDetails(categoryId: c.id, categoryName: c.name);
                    }
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => FriendlyErrorWidget(error: e),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Etiqueta*',
                controller: _labelController,
                helperText:
                    'Descripción corta que identifique a la cotización.',
                maxLength: 35,
                onChanged: (val) => ref
                    .read(createQuoteProvider.notifier)
                    .setDetails(label: val),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notas adicionales',
                controller: _notesController,
                helperText: 'Estas notas quedarán reflejadas en la cotización.',
                maxLines: 3,
                maxLength: 250,
                onChanged: (val) => ref
                    .read(createQuoteProvider.notifier)
                    .setDetails(notes: val),
              ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
