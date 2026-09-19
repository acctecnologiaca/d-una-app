import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_multi_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/collapsible_card_block.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_category_sheet.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_quick_phrase_sheet.dart';
import 'package:d_una_app/features/settings/data/models/quick_phrase.dart';
import 'package:d_una_app/features/settings/presentation/providers/quick_phrases_provider.dart';
import '../providers/create_report_provider.dart';
import '../widgets/intervention_type_chips.dart';
import '../../../domain/models/service_report_model.dart';

class ReportDetailsTab extends ConsumerStatefulWidget {
  const ReportDetailsTab({super.key});

  @override
  ConsumerState<ReportDetailsTab> createState() => _ReportDetailsTabState();
}

class _ReportDetailsTabState extends ConsumerState<ReportDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _requestController;
  late final TextEditingController _workController;
  late final TextEditingController _recommendationsController;
  late final TextEditingController _notesController;
  late final TextEditingController _reportTagController;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ExpansibleController _controllerClient = ExpansibleController();
  final ExpansibleController _controller1 = ExpansibleController();
  final ExpansibleController _controller2 = ExpansibleController();
  final ExpansibleController _controller3 = ExpansibleController();
  final ExpansibleController _controller4 = ExpansibleController();
  int? _expandedIndex = 0;

  void _onExpandBlock(int index) {
    if (_expandedIndex != index) {
      if (_expandedIndex == 0 && _controllerClient.isExpanded) {
        _controllerClient.collapse();
      }
      if (_expandedIndex == 1 && _controller1.isExpanded) {
        _controller1.collapse();
      }
      if (_expandedIndex == 2 && _controller2.isExpanded) {
        _controller2.collapse();
      }
      if (_expandedIndex == 3 && _controller3.isExpanded) {
        _controller3.collapse();
      }
      if (_expandedIndex == 4 && _controller4.isExpanded) {
        _controller4.collapse();
      }
      setState(() {
        _expandedIndex = index;
      });
    }
  }

  void _onCollapseBlock(int index) {
    if (_expandedIndex == index) {
      setState(() {
        _expandedIndex = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(createReportProvider);
    _dateController = TextEditingController(
      text: _dateFormat.format(state.serviceDate),
    );
    _requestController = TextEditingController(text: state.requestDescription);
    _workController = TextEditingController(text: state.workDescription);
    _recommendationsController = TextEditingController(
      text: state.recommendations,
    );
    _notesController = TextEditingController(text: state.notes ?? '');
    _reportTagController = TextEditingController(text: state.reportTag ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _requestController.dispose();
    _workController.dispose();
    _recommendationsController.dispose();
    _notesController.dispose();
    _reportTagController.dispose();
    _controllerClient.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

  void _openQuickPhrasesModal({
    required String title,
    required QuickPhraseFieldType fieldType,
    required List<String> phrases,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final state = ref.read(createReportProvider);
    final colors = Theme.of(context).colorScheme;

    FilterBottomSheet.showMulti(
      context: context,
      title: title,
      options: phrases,
      selectedValues: const {},
      sortOptions: false,
      showAllOption: false,
      showLeading: true,
      leadingBuilder: (_) => Icon(Icons.circle, size: 8, color: colors.primary),
      applyButtonLabel: 'Insertar',
      addOptionLabel: 'Agregar frase rápida',
      onAddOption: () {
        Navigator.pop(context);
        AddEditQuickPhraseSheet.show(
          context,
          defaultFieldType: fieldType,
          defaultCategoryId: state.categoryId,
        );
      },
      onApply: (selected) {
        if (selected.isEmpty) return;
        final currentText = controller.text.trim();
        final phrasesToAdd = selected.join(', ');

        final String newText;
        if (currentText.isEmpty) {
          newText = phrasesToAdd;
        } else if (currentText.endsWith(',') || currentText.endsWith('.')) {
          newText = '$currentText $phrasesToAdd';
        } else {
          newText = '$currentText, $phrasesToAdd';
        }

        controller.text = newText;
        onChanged(newText);
      },
    );
  }

  // --- Subtítulos dinámicos de resumen para bloques colapsados ---
  String _getBlock0Subtitle(Client? selectedClient, Contact? selectedContact) {
    if (selectedClient != null) {
      final taxIdStr = selectedClient.taxId ?? 'Sin RIF';
      final contactStr = selectedContact != null
          ? ' • ${selectedContact.name}'
          : '';
      return '${selectedClient.name} • $taxIdStr$contactStr';
    }
    return 'Pendiente de seleccionar cliente';
  }

  bool _isBlock0Complete(ServiceReportCreateState state) =>
      state.clientId != null && state.clientId!.isNotEmpty;

  String _getBlock1Subtitle(ServiceReportCreateState state) {
    final cat = state.categoryName;
    if (cat != null && cat.isNotEmpty) {
      return '${state.interventionType.label} • $cat';
    }
    return '${state.interventionType.label} • Sin categoría';
  }

  String _getBlock2Subtitle(
    BuildContext context,
    ServiceReportCreateState state,
  ) {
    final dateStr = _dateFormat.format(state.serviceDate);
    final startStr = state.startTime != null
        ? state.startTime!.format(context)
        : '--';
    final endStr = state.endTime != null
        ? state.endTime!.format(context)
        : '--';
    final durationStr =
        state.durationMinutes != null && state.durationMinutes! > 0
        ? ' • ⏱️ ${state.durationMinutes! ~/ 60}h ${state.durationMinutes! % 60}m'
        : '';
    final advisorStr =
        state.advisorName != null && state.advisorName!.isNotEmpty
        ? ' • ${state.advisorName}'
        : '';
    return '$dateStr • $startStr a $endStr$durationStr$advisorStr';
  }

  String _getBlock3Subtitle(ServiceReportCreateState state) {
    final work = state.workDescription.trim();
    if (work.isNotEmpty) {
      final firstLine = work.split('\n').first.trim();
      final preview = firstLine.length > 35
          ? '${firstLine.substring(0, 35)}...'
          : firstLine;
      return '✓ $preview';
    }
    return 'Pendiente de informe técnico';
  }

  String _getBlock4Subtitle(ServiceReportCreateState state) {
    final tag = state.reportTag?.trim();
    if (tag != null && tag.isNotEmpty) {
      int extraCount = 0;
      if (state.recommendations.trim().isNotEmpty) extraCount++;
      if (state.notes != null && state.notes!.trim().isNotEmpty) extraCount++;
      if (extraCount > 0) {
        return '$tag • +$extraCount nota(s)';
      }
      return tag;
    }
    return 'Pendiente de etiqueta obligatoria';
  }

  bool _isBlock1Complete(ServiceReportCreateState state) =>
      state.categoryId != null && state.categoryId!.isNotEmpty;

  bool _isBlock2Complete(ServiceReportCreateState state) =>
      state.selectedAdvisors.isNotEmpty ||
      (state.advisorId != null && state.advisorId!.isNotEmpty);

  bool _isBlock3Complete(ServiceReportCreateState state) =>
      state.workDescription.trim().isNotEmpty;

  bool _isBlock4Complete(ServiceReportCreateState state) =>
      state.reportTag != null && state.reportTag!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ref.listen<ServiceReportCreateState>(createReportProvider, (
      previous,
      next,
    ) {
      final formattedDate = _dateFormat.format(next.serviceDate);
      if (_dateController.text != formattedDate) {
        _dateController.text = formattedDate;
      }
      if (previous?.requestDescription != next.requestDescription &&
          _requestController.text != next.requestDescription) {
        _requestController.text = next.requestDescription;
      }
      if (previous?.workDescription != next.workDescription &&
          _workController.text != next.workDescription) {
        _workController.text = next.workDescription;
      }
      if (previous?.recommendations != next.recommendations &&
          _recommendationsController.text != next.recommendations) {
        _recommendationsController.text = next.recommendations;
      }
      if (previous?.notes != next.notes &&
          _notesController.text != (next.notes ?? '')) {
        _notesController.text = next.notes ?? '';
      }
      if (previous?.reportTag != next.reportTag &&
          _reportTagController.text != (next.reportTag ?? '')) {
        _reportTagController.text = next.reportTag ?? '';
      }
    });

    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);
    final clientsAsync = ref.watch(clientsProvider);
    final activeClients = clientsAsync.value ?? [];

    final selectedClient =
        activeClients.where((c) => c.id == state.clientId).firstOrNull ??
        (state.report?.clientId == state.clientId && state.clientId != null
            ? Client(
                id: state.clientId!,
                name: state.clientName ?? '',
                userId: '',
                type: state.clientType ?? 'company',
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final requestPhrases = ref.watch(
      quickPhrasesForFieldProvider(
        QuickPhraseFilterParams(
          fieldType: QuickPhraseFieldType.request,
          categoryId: state.categoryId,
        ),
      ),
    );
    final workPhrases = ref.watch(
      quickPhrasesForFieldProvider(
        QuickPhraseFilterParams(
          fieldType: QuickPhraseFieldType.work,
          categoryId: state.categoryId,
        ),
      ),
    );
    final recommendationPhrases = ref.watch(
      quickPhrasesForFieldProvider(
        QuickPhraseFilterParams(
          fieldType: QuickPhraseFieldType.recommendation,
          categoryId: state.categoryId,
        ),
      ),
    );

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // BLOQUE 0: Cliente y Contacto
          // ==========================================
          CollapsibleCardBlock(
            controller: _controllerClient,
            initiallyExpanded: _expandedIndex == 0,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(0) : _onCollapseBlock(0),
            leading: const Icon(Symbols.person, size: 22),
            title: 'Cliente y Contacto',
            subtitle: _getBlock0Subtitle(selectedClient, selectedContact),
            isComplete: _isBlock0Complete(state),
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
                  final reportId = state.report?.id;
                  final returnPath = reportId != null
                      ? '/reports/edit/$reportId?tab=0'
                      : '/reports/create?tab=0';
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
                    notifier.setClient(newClient);
                  }
                },
                onChanged: (client) {
                  if (client != null && client.id != '___ADD___') {
                    if (state.clientId != client.id) {
                      notifier.setClient(client);
                    }
                  } else {
                    notifier.clearClient();
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
                const SizedBox(height: 8),
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
                          final reportId = state.report?.id;
                          final returnPath = reportId != null
                              ? '/reports/edit/$reportId?tab=0'
                              : '/reports/create?tab=0';
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
                              notifier.setContact(
                                newContact.id,
                                newContact.name,
                              );
                            }
                          }
                        },
                  onChanged: (contact) {
                    if (contact != null && contact.id != '___ADD___') {
                      notifier.setContact(contact.id, contact.name);
                    } else {
                      notifier.clearContact();
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
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 12),

          // ==========================================
          // BLOQUE 1: Tipo de servicio (Clasificación)
          // ==========================================
          CollapsibleCardBlock(
            controller: _controller1,
            initiallyExpanded: _expandedIndex == 1,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(1) : _onCollapseBlock(1),
            leading: Icon(
              Icons.category_outlined,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
            title: 'Tipo de servicio',
            subtitle: _getBlock1Subtitle(state),
            isComplete: _isBlock1Complete(state),
            children: [
              InterventionTypeChips(
                padding: EdgeInsets.zero,
                selectedType: state.interventionType,
                onSelected: (InterventionType type) =>
                    notifier.setInterventionType(type),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  Category? selectedCategory;
                  if (state.categoryId != null) {
                    for (final cat in categories) {
                      if (cat.id == state.categoryId) {
                        selectedCategory = cat;
                        break;
                      }
                    }
                  }

                  return CustomDropdown<Category>(
                    label: 'Categoría',
                    value: selectedCategory,
                    items: categories,
                    searchable: true,
                    itemLabelBuilder: (cat) => cat.name,
                    onChanged: (cat) {
                      notifier.setCategory(cat?.id, cat?.name);
                    },
                    showAddOption: true,
                    addOptionLabel: 'Agregar categoría',
                    addOptionValue: const Category(
                      id: '___ADD___',
                      name: 'Agregar categoría',
                      type: 'service',
                    ),
                    onAddPressed: () async {
                      final result = await showModalBottomSheet<Category>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const AddEditCategorySheet(),
                      );
                      if (result != null) {
                        notifier.setCategory(result.id, result.name);
                      }
                    },
                  );
                },
                loading: () => const CustomDropdown<String>(
                  label: 'Categoría*',
                  value: null,
                  items: [],
                  itemLabelBuilder: _dummyLabelBuilder,
                  enabled: false,
                ),
                error: (err, _) => FriendlyErrorWidget(
                  error: err,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),

          // ==========================================
          // BLOQUE 2: Tiempo y ejecución
          // ==========================================
          CollapsibleCardBlock(
            controller: _controller2,
            initiallyExpanded: _expandedIndex == 2,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(2) : _onCollapseBlock(2),
            leading: Icon(
              Icons.schedule,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
            title: 'Tiempo y ejecución',
            subtitle: _getBlock2Subtitle(context, state),
            isComplete: _isBlock2Complete(state),
            children: [
              CustomTextField(
                label: 'Fecha del Servicio*',
                controller: _dateController,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.serviceDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateController.text = _dateFormat.format(date);
                    notifier.setServiceDate(date);
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () async {
                        final now = TimeOfDay.now();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: state.startTime ?? now,
                        );
                        if (time != null) {
                          int? duration;
                          if (state.endTime != null) {
                            final startMins = time.hour * 60 + time.minute;
                            final endMins =
                                state.endTime!.hour * 60 +
                                state.endTime!.minute;
                            if (endMins >= startMins) {
                              duration = endMins - startMins;
                            }
                          }
                          notifier.setTimes(
                            start: time,
                            durationMinutes: duration,
                          );
                        }
                      },
                      icon: const Icon(Icons.schedule, size: 16),
                      label: Text(
                        state.startTime != null
                            ? 'Inicio: ${state.startTime!.format(context)}'
                            : 'Hora Inicio',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (state.durationMinutes != null &&
                      state.durationMinutes! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.durationMinutes! ~/ 60}h ${state.durationMinutes! % 60}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 8),
                    Text(
                      'a',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () async {
                        final now = TimeOfDay.now();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: state.endTime ?? now,
                        );
                        if (time != null) {
                          int? duration;
                          if (state.startTime != null) {
                            final startMins =
                                state.startTime!.hour * 60 +
                                state.startTime!.minute;
                            final endMins = time.hour * 60 + time.minute;
                            if (endMins >= startMins) {
                              duration = endMins - startMins;
                            }
                          }
                          notifier.setTimes(
                            end: time,
                            durationMinutes: duration,
                          );
                        }
                      },
                      icon: const Icon(Icons.schedule_send, size: 16),
                      label: Text(
                        state.endTime != null
                            ? 'Fin: ${state.endTime!.format(context)}'
                            : 'Hora Fin',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              collaboratorsAsync.when(
                data: (collaborators) {
                  List<Collaborator> selectedList = [];
                  if (state.selectedAdvisors.isNotEmpty) {
                    selectedList = collaborators
                        .where(
                          (c) => state.selectedAdvisors.any(
                            (sel) => sel.id == c.id,
                          ),
                        )
                        .toList();
                  } else if (state.advisorId != null) {
                    selectedList = collaborators
                        .where((c) => c.id == state.advisorId)
                        .toList();
                  }

                  return CustomMultiDropdown<Collaborator>(
                    label: 'Técnicos responsables (colaboradores)',
                    hintText: 'Seleccionar técnicos...',
                    selectedValues: selectedList,
                    items: collaborators,
                    itemLabelBuilder: (c) => c.fullName,
                    addOptionLabel: 'Agregar colaborador',
                    onAddOption: () {
                      Navigator.pop(context);
                      context.push('/collaborators/add');
                    },
                    onChanged: (selected) {
                      notifier.setAdvisors(selected);
                    },
                  );
                },
                loading: () => const CustomMultiDropdown<String>(
                  label: 'Técnicos responsables',
                  selectedValues: [],
                  items: [],
                  itemLabelBuilder: _dummyLabelBuilder,
                  enabled: false,
                ),
                error: (err, _) => FriendlyErrorWidget(
                  error: err,
                  onRetry: () => ref.invalidate(collaboratorsProvider),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),

          // =========================================================================
          // BLOQUE 3: Informe técnico
          // =========================================================================
          CollapsibleCardBlock(
            controller: _controller3,
            initiallyExpanded: _expandedIndex == 3,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(3) : _onCollapseBlock(3),
            leading: Icon(
              Icons.assignment_outlined,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
            title: 'Informe técnico',
            subtitle: _getBlock3Subtitle(state),
            isComplete: _isBlock3Complete(state),
            children: [
              // 1. Requerimiento o Falla reportada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requerimiento o falla reportada',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.quickreply_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Frases de acceso rápido',
                    onPressed: () => _openQuickPhrasesModal(
                      title: 'Frases de acceso rápido',
                      fieldType: QuickPhraseFieldType.request,
                      phrases: requestPhrases,
                      controller: _requestController,
                      onChanged: (val) => notifier.setRequestDescription(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomTextField(
                label: '',
                controller: _requestController,
                helperText:
                    'Motivo o requerimiento reportado por el cliente (opcional).',
                maxLines: 3,
                maxLength: 500,
                onChanged: (val) => notifier.setRequestDescription(val),
              ),
              const SizedBox(height: 12),

              // 2. Diagnóstico y servicio realizado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diagnóstico y/o servicio realizado*',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.quickreply_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Frases de acceso rápido',
                    onPressed: () => _openQuickPhrasesModal(
                      title: 'Frases de acceso rápido',
                      fieldType: QuickPhraseFieldType.work,
                      phrases: workPhrases,
                      controller: _workController,
                      onChanged: (val) => notifier.setWorkDescription(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomTextField(
                label: '',
                controller: _workController,
                helperText:
                    'Detalle de la falla detectada y solución ejecutada.',
                maxLines: 5,
                maxLength: 1000,
                onChanged: (val) => notifier.setWorkDescription(val),
              ),
              const SizedBox(height: 12),

              // 3. Recomendaciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recomendaciones técnicas',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.quickreply_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Frases de acceso rápido',
                    onPressed: () => _openQuickPhrasesModal(
                      title: 'Frases de acceso rápido',
                      fieldType: QuickPhraseFieldType.recommendation,
                      phrases: recommendationPhrases,
                      controller: _recommendationsController,
                      onChanged: (val) => notifier.setRecommendations(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomTextField(
                label: '',
                controller: _recommendationsController,
                helperText:
                    'Observaciones o sugerencias de mejora para el cliente (opcional).',
                maxLines: 3,
                maxLength: 500,
                onChanged: (val) => notifier.setRecommendations(val),
              ),
              const SizedBox(height: 8),
            ],
          ),

          // =========================================================================
          // BLOQUE 4: Detalles opcionales y notas (Acordeón Cerrado por defecto)
          // =========================================================================
          CollapsibleCardBlock(
            controller: _controller4,
            initiallyExpanded: _expandedIndex == 4,
            onExpansionChanged: (expanded) =>
                expanded ? _onExpandBlock(4) : _onCollapseBlock(4),
            leading: Icon(
              Icons.tune_outlined,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
            title: 'Información adicional',
            subtitle: _getBlock4Subtitle(state),
            isComplete: _isBlock4Complete(state),
            children: [
              CustomTextField(
                label: 'Etiqueta*',
                controller: _reportTagController,
                helperText: 'Descripción corta que identifique al reporte.',
                maxLength: 35,
                onChanged: (val) => notifier.setDetails(reportTag: val),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notas internas (opcional)',
                controller: _notesController,
                helperText: 'Notas confidenciales para uso interno.',
                maxLines: 2,
                maxLength: 250,
                onChanged: (val) => notifier.setDetails(notes: val),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}

String _dummyLabelBuilder(String s) => s;
