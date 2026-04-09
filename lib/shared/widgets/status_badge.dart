import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final Widget? icon;
  final String? text;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double fontSize;

  const StatusBadge({
    super.key,
    this.icon,
    this.text,
    required this.backgroundColor,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.borderRadius = 12.0,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final text = this.text;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?icon,
          if (icon != null && text != null)
            const SizedBox(width: 4), // Espacio solo si hay ambos
          if (text != null)
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}
