import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_button.dart';

class RegisterLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress; // 0.0 to 1.0 (or step index based on total)
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final bool isNextEnabled;
  final String nextButtonText;
  final String cancelButtonText;
  final String backButtonText;

  const RegisterLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    required this.content,
    required this.onNext,
    this.onBack,
    this.onCancel,
    this.isNextEnabled = true,
    this.nextButtonText = 'Siguiente',
    this.cancelButtonText = 'Cancelar',
    this.backButtonText = 'Atrás',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 22.0, 16.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row (Back Arrow + Title)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                    onPressed: onBack ?? () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Crea una cuenta',
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: const Color(0xFFFFDBCD), // Secondary container color
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(height: 4, color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Title/Question
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 16),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Form Content
              content,

              const SizedBox(height: 60),

              // Footer Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel ?? () => context.go('/login'),
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (onBack != null || Navigator.canPop(context))
                        TextButton(
                          onPressed: onBack ?? () => context.pop(),
                          child: Text(
                            backButtonText,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: CustomButton(
                          text: nextButtonText,
                          onPressed: isNextEnabled ? onNext : null,
                          type: ButtonType.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
