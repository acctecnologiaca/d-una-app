import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';
import '../../profile/presentation/providers/occupations_provider.dart';
import '../../../shared/widgets/custom_dropdown.dart';
import '../../../shared/widgets/custom_multi_dropdown.dart';
import '../../../core/utils/error_handler.dart';

class RegisterOccupationScreen extends ConsumerStatefulWidget {
  const RegisterOccupationScreen({super.key});

  @override
  ConsumerState<RegisterOccupationScreen> createState() =>
      _RegisterOccupationScreenState();
}

class _RegisterOccupationScreenState
    extends ConsumerState<RegisterOccupationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _primaryOccupationId;
  List<String> _secondaryOccupationIds = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(registerProvider);
    _primaryOccupationId = state.primaryOccupationId;
    _secondaryOccupationIds = List.from(state.secondaryOccupationIds);
  }

  Future<void> _onNext() async {
    if (_formKey.currentState!.validate()) {
      ref
          .read(registerProvider.notifier)
          .updateOccupations(
            primaryId: _primaryOccupationId,
            secondaryIds: _secondaryOccupationIds,
          );

      try {
        await ref.read(registerProvider.notifier).signUp();
        if (mounted) {
          context.push('/register/verification');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, message: ErrorHandler.getFriendlyMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupationsAsync = ref.watch(occupationsProvider);
    final registerState = ref.watch(registerProvider);

    return RegisterLayout(
      title: '¿A qué te dedicas?',
      subtitle:
          'Saber esto, nos permitirá conectarte con los proveedores adecuados.',
      progress: 4,
      onNext: _onNext,
      isLoading: registerState.isLoading,
      content: occupationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => FriendlyErrorWidget(error: e),
        data: (occupationsList) {
          final secondaryItems = occupationsList
              .map((e) => e['id'] as String)
              .where((id) => id != _primaryOccupationId)
              .toList();

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Primary Occupation Dropdown (Searchable)
                CustomDropdown<String>(
                  label: 'Ocupación principal',
                  searchable: true,
                  isRequired: true,
                  value: _primaryOccupationId,
                  items: occupationsList
                      .map((e) => e['id'] as String)
                      .toList(),
                  itemLabelBuilder: (id) {
                    final occ = occupationsList.firstWhere(
                      (element) => element['id'] == id,
                      orElse: () => {'name': 'Desconocido'},
                    );
                    return occ['name'] as String;
                  },
                  onChanged: (val) {
                    setState(() {
                      _primaryOccupationId = val;
                      // Auto-remove from secondary if selected as primary
                      if (val != null &&
                          _secondaryOccupationIds.contains(val)) {
                        _secondaryOccupationIds.remove(val);
                      }
                    });
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Selecciona una ocupación principal';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Secondary Occupations (CustomMultiDropdown with Search and max 2 selections)
                CustomMultiDropdown<String>(
                  label: 'Otras ocupaciones',
                  isRequired: false,
                  maxSelections: 2,
                  selectedValues: _secondaryOccupationIds,
                  items: secondaryItems,
                  itemLabelBuilder: (id) {
                    final occ = occupationsList.firstWhere(
                      (element) => element['id'] == id,
                      orElse: () => {'name': 'Desconocido'},
                    );
                    return occ['name'] as String;
                  },
                  onChanged: (newIds) {
                    setState(() {
                      _secondaryOccupationIds = newIds;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
