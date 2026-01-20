import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/wizard_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/wizard_progress_bar.dart';
import '../../providers/add_client_provider.dart';

class AddClientTypeScreen extends ConsumerStatefulWidget {
  const AddClientTypeScreen({super.key});

  @override
  ConsumerState<AddClientTypeScreen> createState() =>
      _AddClientTypeScreenState();
}

class _AddClientTypeScreenState extends ConsumerState<AddClientTypeScreen> {
  // 'company' or 'person'
  String _selectedType = 'company';

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
    });
  }

  void _onNext() {
    ref.read(addClientProvider.notifier).updateType(_selectedType);
    if (_selectedType == 'company') {
      context.push('/clients/add/company-info');
    } else {
      context.push('/clients/add/person-info');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/clients');
            }
          },
        ),
        title: Text(
          'Agregar cliente',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        bottom: const WizardProgressBar(totalSteps: 4, currentStep: 0),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Tipo de cliente',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 32),

              // Custom Type Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTypeOption(
                    label: 'Empresa',
                    value: 'company',
                    isSelected: _selectedType == 'company',
                    colors: colors,
                  ),
                  _buildTypeOption(
                    label: 'Persona',
                    value: 'person',
                    isSelected: _selectedType == 'person',
                    colors: colors,
                    showLeftBorder: false, // Avoid double border
                  ),
                ],
              ),

              const Spacer(),

              // Footer Buttons
              WizardButtonBar(
                onCancel: () {
                  context.pop();
                },
                onNext: _onNext,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required String value,
    required bool isSelected,
    required ColorScheme colors,
    bool showLeftBorder = true,
  }) {
    // If selected, use secondaryContainer (Peach)
    // If not, use transparent/white
    final backgroundColor = isSelected
        ? colors.secondaryContainer
        : Colors.transparent;
    final textColor = isSelected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final borderColor = colors.outline.withValues(alpha: 0.5);

    return InkWell(
      onTap: () => _onTypeChanged(value),
      borderRadius: value == 'company'
          ? const BorderRadius.horizontal(left: Radius.circular(30))
          : const BorderRadius.horizontal(right: Radius.circular(30)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: value == 'company'
              ? const BorderRadius.horizontal(left: Radius.circular(30))
              : const BorderRadius.horizontal(right: Radius.circular(30)),
          border: Border.all(
            color: isSelected ? colors.secondaryContainer : borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
