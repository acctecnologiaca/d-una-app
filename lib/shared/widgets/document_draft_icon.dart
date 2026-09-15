import 'package:flutter/material.dart';
import '../../core/constants/draft_constants.dart';

/// Ícono estandarizado para señalar cambios temporales locales no guardados en BD
/// en tarjetas de documentos y vistas ejecutivas.
class DocumentDraftIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String tooltip;

  const DocumentDraftIcon({
    super.key,
    this.size = 20.0,
    this.color,
    this.tooltip = 'Cambios temporales sin guardar',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: Icon(
        DraftConstants.draftIcon,
        size: size,
        color: effectiveColor,
      ),
    );
  }
}
