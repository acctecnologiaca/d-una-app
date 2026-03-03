import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import 'package:intl/intl.dart';
import '../../../../portfolio/data/models/category_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../data/models/collaborator.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';

class QuoteDetailsTab extends ConsumerStatefulWidget {
  const QuoteDetailsTab({super.key});

  @override
  ConsumerState<QuoteDetailsTab> createState() => _QuoteDetailsTabState();
}

class _QuoteDetailsTabState extends ConsumerState<QuoteDetailsTab> {
  late final TextEditingController _validityQuantityController;
  late final TextEditingController _labelController;
  late final TextEditingController _notesController;
  String _validityPeriod = 'Días';

  @override
  void initState() {
    super.initState();
    final quoteState = ref.read(createQuoteProvider);
    _validityQuantityController = TextEditingController(
      text: quoteState.validityDays.toString(),
    );
    _labelController = TextEditingController(text: quoteState.label ?? '');
    _notesController = TextEditingController(text: quoteState.notes ?? '');
  }

  @override
  void dispose() {
    _validityQuantityController.dispose();
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createQuoteProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fecha de la cotización
          CustomTextField(
            label: 'Fecha de la cotización*',
            controller: TextEditingController(
              text: dateFormat.format(state.dateIssued),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.dateIssued,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                ref
                    .read(createQuoteProvider.notifier)
                    .setDetails(dateIssued: date);
              }
            },
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 16),
          // Vigencia de la cotización
          Text(
            'Vigencia de la cotización',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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
                          int.tryParse(_validityQuantityController.text) ?? 0;
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
          // Categoría
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
              onAddPressed: () {
                // TODO: add category logic
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
            error: (e, st) => Text('Error al cargar categorías: $e'),
          ),
          const SizedBox(height: 16),
          // Asesor responsable
          collaboratorsAsync.when(
            data: (fetchedCollaborators) {
              final userProfile = ref.watch(userProfileProvider).value;

              // Create a list combining the user and the fetched collaborators
              final List<Collaborator> allCollaborators = [];
              Collaborator? userCollaborator;

              if (userProfile != null) {
                final firstName = userProfile.firstName ?? '';
                final lastName = userProfile.lastName ?? '';
                final fullName = [
                  firstName,
                  lastName,
                ].where((s) => s.isNotEmpty).join(' ').trim();

                if (fullName.isNotEmpty) {
                  userCollaborator = Collaborator(
                    id: userProfile.id,
                    fullName: fullName,
                    isActive: true,
                  );
                  allCollaborators.add(userCollaborator);
                }
              }

              allCollaborators.addAll(fetchedCollaborators);

              final defaultCollab =
                  userCollaborator ?? allCollaborators.firstOrNull;

              final selectedCollab = state.advisorId != null
                  ? allCollaborators
                        .where((c) => c.id == state.advisorId)
                        .firstOrNull
                  : defaultCollab;

              // Preselect default if not set
              if (state.advisorId == null && selectedCollab != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(createQuoteProvider.notifier)
                      .setDetails(
                        advisorId: selectedCollab.id,
                        advisorName: selectedCollab.fullName,
                      );
                });
              }

              return CustomDropdown<Collaborator>(
                value: selectedCollab,
                items: allCollaborators,
                label: 'Asesor responsable',
                searchable: true,
                showAddOption: true,
                addOptionLabel: 'Agregar asesor',
                addOptionValue: Collaborator(
                  id: '___ADD___',
                  fullName: '___ADD___',
                  isActive: true,
                ),
                itemLabelBuilder: (c) => c.fullName,
                onAddPressed: () {
                  // TODO: add collaborator logic
                },
                onChanged: (c) {
                  if (c != null && c.id != '___ADD___') {
                    ref
                        .read(createQuoteProvider.notifier)
                        .setDetails(advisorId: c.id, advisorName: c.fullName);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error al cargar asesores: $e'),
          ),
          const SizedBox(height: 16),
          // Etiqueta
          CustomTextField(
            label: 'Etiqueta*',
            controller: _labelController,
            helperText: 'Frase corta que identifique la cotización',
            onChanged: (val) =>
                ref.read(createQuoteProvider.notifier).setDetails(label: val),
          ),
          const SizedBox(height: 16),
          // Notas adicionales
          CustomTextField(
            label: 'Notas adicionales',
            controller: _notesController,
            hintText: 'Quedarán reflejadas en la cotización...',
            maxLines: 5,
            minLines: 3,
            onChanged: (val) =>
                ref.read(createQuoteProvider.notifier).setDetails(notes: val),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
