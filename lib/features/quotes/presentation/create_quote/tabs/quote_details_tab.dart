import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import 'package:intl/intl.dart';
import '../../../../portfolio/data/models/category_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../collaborators/domain/models/collaborator.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../settings/presentation/widgets/add_edit_category_sheet.dart';
import 'package:go_router/go_router.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createQuoteProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fecha de la cotización
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
              onAddPressed: () async {
                final newCategory = await AddEditCategorySheet.show(context);
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
          // Asesor responsable
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
                        .setDetails(advisorId: c.id, advisorName: c.fullName);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 16),
          // Etiqueta
          CustomTextField(
            label: 'Etiqueta*',
            controller: _labelController,
            helperText:
                'Descripción corta que identifique a la cotización (Máx. 35 caracteres).',
            onChanged: (val) {
              if (val.length > 35) {
                _labelController.text = val.substring(0, 35);
              }
              ref.read(createQuoteProvider.notifier).setDetails(label: val);
            },
          ),
          const SizedBox(height: 16),
          // Notas adicionales
          CustomTextField(
            label: 'Notas adicionales',
            controller: _notesController,
            helperText:
                'Estas notas quedarán reflejadas en el PDF de la cotización (Máx. 250 caracteres).',
            maxLines: 5,
            minLines: 3,
            onChanged: (val) {
              if (val.length > 250) {
                _notesController.text = val.substring(0, 250);
              }
              ref.read(createQuoteProvider.notifier).setDetails(notes: val);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
