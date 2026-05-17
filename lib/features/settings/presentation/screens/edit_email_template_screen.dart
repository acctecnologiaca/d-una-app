import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/email_template.dart';
import '../providers/email_templates_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
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
  ConsumerState<EditEmailTemplateScreen> createState() => _EditEmailTemplateScreenState();
}

class _EditEmailTemplateScreenState extends ConsumerState<EditEmailTemplateScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.template?.subjectTemplate ?? EmailContentGenerator.getDefaultSubject(widget.typeId),
    );
    _bodyController = TextEditingController(
      text: widget.template?.bodyTemplate ?? EmailContentGenerator.getDefaultBody(widget.typeId),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final template = EmailTemplate(
        id: widget.template?.id ?? '', // ID handled by upsert if empty
        userId: widget.template?.userId ?? '', // Handled by repository
        documentType: widget.typeId,
        subjectTemplate: _subjectController.text.trim(),
        bodyTemplate: _bodyController.text.trim(),
      );

      await ref.read(emailTemplatesListProvider.notifier).saveTemplate(template);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada correctamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Plantilla: ${widget.label}'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational banner about template usage
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.primaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta plantilla se utiliza tanto para correos electrónicos como para mensajes de WhatsApp.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(colors, 'Asunto del Correo'),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Asunto',
              controller: _subjectController,
              hintText: 'Ej: Cotización #{{number}}',
            ),
            const SizedBox(height: 8),
            _buildVariablesLegend(colors, ['{{number}}', '{{category}}', '{{tag}}']),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader(colors, 'Cuerpo del Mensaje'),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Mensaje',
              controller: _bodyController,
              maxLines: 12,
              minLines: 6,
              hintText: 'Estimado(a) {{client_name}}...',
            ),
            const SizedBox(height: 8),
            _buildVariablesLegend(colors, ['{{client_name}}', '{{user_name}}', '{{company_name}}']),
            
            const SizedBox(height: 48),
            
            CustomButton(
              text: 'Guardar Plantilla',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildVariablesLegend(ColorScheme colors, List<String> variables) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: variables.map((v) => Container(
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
      )).toList(),
    );
  }
}
