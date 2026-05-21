import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/email_template.dart';
import '../providers/email_templates_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../core/utils/email_content_generator.dart';

class EditEmailTemplateScreen extends ConsumerStatefulWidget {
  final String typeId;
  final String label;
  final EmailTemplate? template;

  const EditEmailTemplateScreen({
    super.key,
    required this.typeId,
    required this.label,
    this.template,
  });

  @override
  ConsumerState<EditEmailTemplateScreen> createState() =>
      _EditEmailTemplateScreenState();
}

class _EditEmailTemplateScreenState
    extends ConsumerState<EditEmailTemplateScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  late String _initialSubject;
  late String _initialBody;
  bool _isLoading = false;
  bool _hasChanges = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initialSubjectText =
        widget.template?.subjectTemplate ??
        EmailContentGenerator.getDefaultSubject(widget.typeId);
    final initialBodyText =
        widget.template?.bodyTemplate ??
        EmailContentGenerator.getDefaultBody(widget.typeId);

    _subjectController = TextEditingController(text: initialSubjectText);
    _bodyController = TextEditingController(text: initialBodyText);

    _initialSubject = initialSubjectText;
    _initialBody = initialBodyText;

    _subjectController.addListener(_checkForChanges);
    _bodyController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _subjectController.removeListener(_checkForChanges);
    _bodyController.removeListener(_checkForChanges);
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges =
        _subjectController.text != _initialSubject ||
        _bodyController.text != _initialBody;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<bool?> _showDiscardDialog() async {
    final colors = Theme.of(context).colorScheme;
    return CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Descartar cambios?',
        contentText:
            'Si sales ahora, perderás toda la información que has ingresado.',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final template = EmailTemplate(
        id: widget.template?.id ?? '', // ID handled by upsert if empty
        userId: widget.template?.userId ?? '', // Handled by repository
        documentType: widget.typeId,
        subjectTemplate: _subjectController.text.trim(),
        bodyTemplate: _bodyController.text.trim(),
      );

      await ref
          .read(emailTemplatesListProvider.notifier)
          .saveTemplate(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada correctamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showDiscardDialog();
        if (confirmed == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: StandardAppBar(
          title: 'Modificar plantilla',
          subtitle: widget.label,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(colors, 'Asunto del correo'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Asunto',
                        controller: _subjectController,
                        hintText: 'Ej: Cotización #{{numero}}',
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'El asunto es requerido'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _buildVariablesLegend(colors, [
                        '{{numero}}',
                        '{{categoria}}',
                        '{{etiqueta}}',
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionHeader(colors, 'Cuerpo del mensaje'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Mensaje',
                        controller: _bodyController,
                        maxLines: 12,
                        minLines: 6,
                        hintText: 'Estimado(a) {{nombre_cliente}}...',
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'El mensaje es requerido'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _buildVariablesLegend(colors, [
                        '{{nombre_cliente}}',
                        '{{nombre_empresa}}',
                        if (widget.typeId == 'quote') '{{nombre_asesor}}',
                        if (widget.typeId == 'report') '{{nombre_tecnico}}',
                        if (widget.typeId != 'quote' &&
                            widget.typeId != 'report')
                          '{{nombre_asesor}}',
                      ]),
                      const SizedBox(height: 48),
                      FormBottomBar(
                        onCancel: () => Navigator.of(context).maybePop(),
                        onSave: _save,
                        isLoading: _isLoading,
                        isSaveEnabled: _hasChanges && !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        /* bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16.0,
              8.0,
              16.0,

              MediaQuery.of(context).padding.bottom > 0 ? 0.0 : 40.0,
            ),
            child:
          ),
        ),*/
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildVariablesLegend(ColorScheme colors, List<String> variables) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: variables
          .map(
            (v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                v,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
