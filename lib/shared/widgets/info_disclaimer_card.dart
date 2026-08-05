import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_dialog.dart';

/// Widget global reutilizable para mostrar avisos informativos, notas aclaratorias
/// o disclaimers en la interfaz.
class InfoDisclaimerCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showCloseButton;
  final bool askDismissForever;
  final String? dismissKey;
  final VoidCallback? onDismissed;

  const InfoDisclaimerCard({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.showCloseButton = false,
    this.askDismissForever = false,
    this.dismissKey,
    this.onDismissed,
  });

  @override
  State<InfoDisclaimerCard> createState() => _InfoDisclaimerCardState();
}

class _InfoDisclaimerCardState extends State<InfoDisclaimerCard> {
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _checkDismissedStatus();
  }

  Future<void> _checkDismissedStatus() async {
    if (widget.dismissKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(widget.dismissKey!) ?? false;
      if (isDismissed && mounted) {
        setState(() {
          _isHidden = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleClose() async {
    if (widget.askDismissForever) {
      final choice = await CustomDialog.show<String>(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Icons.visibility_off_outlined,
          title: 'Ocultar aviso',
          contentText:
              '¿Deseas ocultar este aviso solo por esta vez o no volver a mostrarlo más?',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop('once'),
              child: const Text('Solo esta vez'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop('forever'),
              child: const Text('No volver a mostrar'),
            ),
          ],
        ),
      );

      if (choice == null || !mounted) return;

      if (choice == 'forever' && widget.dismissKey != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(widget.dismissKey!, true);
        } catch (_) {}
      }

      setState(() {
        _isHidden = true;
      });
      widget.onDismissed?.call();
    } else {
      setState(() {
        _isHidden = true;
      });
      widget.onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final effectiveIconColor = widget.iconColor ?? colors.primary;
    final effectiveBgColor =
        widget.backgroundColor ??
        colors.primaryContainer.withValues(alpha: 0.12);
    final effectiveBorderColor =
        widget.borderColor ?? colors.primary.withValues(alpha: 0.2);

    return Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 18, color: effectiveIconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.showCloseButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleClose,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
