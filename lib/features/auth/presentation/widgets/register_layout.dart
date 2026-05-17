import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../shared/widgets/wizard_progress_bar.dart';

class RegisterLayout extends StatelessWidget {
  final String title;
  final dynamic subtitle;
  final int progress;
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final bool isNextEnabled;
  final bool isLoading;
  final String nextButtonText;
  final String cancelButtonText;
  final String backButtonText;
  final bool showBackButton;

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
    this.isLoading = false,
    this.nextButtonText = 'Siguiente',
    this.cancelButtonText = 'Cancelar',
    this.backButtonText = 'Atrás',
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: showBackButton ? colors.onSurface : Colors.grey.shade400,
          ),
          onPressed: showBackButton ? (onBack ?? () => context.pop()) : null,
        ),
        title: Text(
          'Crea una cuenta',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: WizardProgressBar(
            totalSteps: 5, // Estimated total steps for registration
            currentStep: progress, // Map progress (0-5) to steps roughly
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: subtitle is String
                      ? Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : subtitle, // It's already a Widget
                ),
              ],

              const SizedBox(height: 32),

              // Form Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: content,
              ),

              const SizedBox(height: 60),

              // Footer Navigation
              // Footer Navigation
              WizardButtonBar(
                onCancel: onCancel ?? () => context.go('/login'),
                onBack: showBackButton
                    ? (onBack ??
                        (Navigator.canPop(context)
                            ? () => context.pop()
                            : null))
                    : null,
                onNext: onNext,
                labelNext: nextButtonText,
                labelCancel: cancelButtonText,
                labelBack: backButtonText,
                isNextEnabled: isNextEnabled,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
