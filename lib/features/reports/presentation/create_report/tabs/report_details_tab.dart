import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_category_sheet.dart';
import '../providers/create_report_provider.dart';
import '../widgets/intervention_type_chips.dart';
import '../widgets/quick_phrases_bar.dart';
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

  final List<String> _requestPhrases = const [
    'Cámaras sin señal',
    'Falla en visión nocturna',
    'Sin grabación / Disco duro',
    'Pérdida de enlace WiFi',
    'Cerradura no traba',
    'Mantenimiento programado',
    'Reubicación de equipo',
    'Configuración de acceso remoto',
  ];

  final List<String> _workPhrases = const [
    'Fuente de poder quemada',
    'Conector sulfatado / dañado',
    'Sobretensión eléctrica',
    'Desconfiguración de software',
    'Sustitución de componente',
    'Rehecho de conectores',
    'Calibración y pruebas 100% OK',
    'Limpieza y ajuste mecánico',
  ];

  final List<String> _recommendationPhrases = const [
    'Instalar protector de voltaje / UPS',
    'Reemplazar cableado expuesto a la intemperie',
    'Próximo mantenimiento preventivo en 6 meses',
    'Actualizar contraseñas de seguridad',
  ];

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
    super.dispose();
  }

  void _appendOrSetText(
    TextEditingController controller,
    String phrase,
    Function(String) onUpdate,
  ) {
    if (controller.text.trim().isEmpty) {
      controller.text = phrase;
    } else {
      controller.text = '${controller.text.trim()}, $phrase';
    }
    onUpdate(controller.text);
  }

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
    final categoriesAsync = ref.watch(categoriesProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tipo de Intervención
          Text(
            'Tipo de servicio*',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InterventionTypeChips(
            selectedType: state.interventionType,
            onSelected: (InterventionType type) =>
                notifier.setInterventionType(type),
          ),
          const SizedBox(height: 20),

          // 2. Categoría Técnica
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
                itemLabelBuilder: (cat) => cat.name,
                onChanged: (cat) {
                  notifier.setCategory(cat?.id, cat?.name);
                },
                showAddOption: true,
                addOptionLabel: 'Nueva categoría',
                addOptionValue: const Category(
                  id: '___ADD___',
                  name: 'Nueva categoría',
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
          const SizedBox(height: 20),

          // 3. Solicitud del Cliente
          Text(
            'Solicitud del Cliente',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          QuickPhrasesBar(
            phrases: _requestPhrases,
            onPhraseSelected: (phrase) => _appendOrSetText(
              _requestController,
              phrase,
              (val) => notifier.setRequestDescription(val),
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Solicitud',
            controller: _requestController,
            hintText: '¿Qué problema o requerimiento reportó el cliente?',
            maxLines: 3,
            onChanged: (val) => notifier.setRequestDescription(val),
          ),
          const SizedBox(height: 20),

          // 4. Diagnóstico y Trabajo Realizado
          Text(
            'Diagnóstico y Trabajo Realizado*',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          QuickPhrasesBar(
            phrases: _workPhrases,
            onPhraseSelected: (phrase) => _appendOrSetText(
              _workController,
              phrase,
              (val) => notifier.setWorkDescription(val),
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Diagnóstico y Trabajo',
            controller: _workController,
            hintText:
                'Detalle de la falla detectada y la solución técnica ejecutada...',
            maxLines: 4,
            onChanged: (val) => notifier.setWorkDescription(val),
          ),
          const SizedBox(height: 20),

          // 5. Tiempos en Sitio
          Text(
            'Tiempos y Ejecución',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                          state.startTime ??
                          const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      int? duration;
                      if (state.endTime != null) {
                        final startMins = time.hour * 60 + time.minute;
                        final endMins =
                            state.endTime!.hour * 60 + state.endTime!.minute;
                        if (endMins >= startMins) {
                          duration = endMins - startMins;
                        }
                      }
                      notifier.setTimes(start: time, durationMinutes: duration);
                    }
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    state.startTime != null
                        ? 'Inicio: ${state.startTime!.format(context)}'
                        : 'Hora Inicio',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                          state.endTime ??
                          const TimeOfDay(hour: 11, minute: 30),
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
                      notifier.setTimes(end: time, durationMinutes: duration);
                    }
                  },
                  icon: const Icon(Icons.schedule_send, size: 18),
                  label: Text(
                    state.endTime != null
                        ? 'Fin: ${state.endTime!.format(context)}'
                        : 'Hora Fin',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          if (state.durationMinutes != null && state.durationMinutes! > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⏱️ Duración: ${state.durationMinutes! ~/ 60}h ${state.durationMinutes! % 60}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // 6. Técnicos Responsables
          collaboratorsAsync.when(
            data: (collaborators) {
              Collaborator? selectedCollab;
              if (state.advisorId != null) {
                for (final c in collaborators) {
                  if (c.id == state.advisorId) {
                    selectedCollab = c;
                    break;
                  }
                }
              }

              return CustomDropdown<Collaborator>(
                label: 'Técnicos responsables',
                value: selectedCollab,
                items: collaborators,
                itemLabelBuilder: (c) => c.fullName,
                onChanged: (c) {
                  notifier.setAdvisor(c?.id, c?.fullName);
                },
              );
            },
            loading: () => const CustomDropdown<String>(
              label: 'Técnico Responsable*',
              value: null,
              items: [],
              itemLabelBuilder: _dummyLabelBuilder,
              enabled: false,
            ),
            error: (err, _) => FriendlyErrorWidget(
              error: err,
              onRetry: () => ref.invalidate(collaboratorsProvider),
            ),
          ),
          const SizedBox(height: 20),

          // 7. Recomendaciones Preventivas
          Text(
            'Recomendaciones Técnicas al Cliente',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          QuickPhrasesBar(
            phrases: _recommendationPhrases,
            onPhraseSelected: (phrase) => _appendOrSetText(
              _recommendationsController,
              phrase,
              (val) => notifier.setRecommendations(val),
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Recomendaciones',
            controller: _recommendationsController,
            hintText: 'Observaciones preventivas o sugerencias de mejora...',
            maxLines: 3,
            onChanged: (val) => notifier.setRecommendations(val),
          ),
          const SizedBox(height: 20),

          // Notas internas y etiqueta
          CustomTextField(
            label: 'Etiqueta del Reporte (Opcional)',
            controller: _reportTagController,
            hintText: 'Ej. Edificio B, Planta Alta',
            onChanged: (val) => notifier.setDetails(reportTag: val),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Notas Internas (Opcional)',
            controller: _notesController,
            hintText: 'Notas confidenciales para uso interno del equipo...',
            maxLines: 2,
            onChanged: (val) => notifier.setDetails(notes: val),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

String _dummyLabelBuilder(String s) => s;
