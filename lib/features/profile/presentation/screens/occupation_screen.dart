import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/occupations_provider.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/custom_multi_dropdown.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class OccupationScreen extends ConsumerStatefulWidget {
  const OccupationScreen({super.key});

  @override
  ConsumerState<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends ConsumerState<OccupationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _primaryOccupationId;
  List<String> _secondaryOccupationIds = [];
  bool _isLoading = false;

  // Initial state for change detection
  String? _initialPrimaryOccupationId;
  List<String> _initialSecondaryOccupationIds = [];

  bool _isInitialized = false;

  bool get _hasChanges {
    // Check primary
    if (_primaryOccupationId != _initialPrimaryOccupationId) return true;

    // Check secondary (length and content)
    if (_secondaryOccupationIds.length !=
        _initialSecondaryOccupationIds.length) {
      return true;
    }
    final currentSet = _secondaryOccupationIds.toSet();
    final initialSet = _initialSecondaryOccupationIds.toSet();
    return !currentSet.containsAll(initialSet);
  }

  void _initializeData(UserProfile profile) {
    if (_isInitialized) return;

    setState(() {
      _primaryOccupationId = profile.occupationId;
      _secondaryOccupationIds = List.from(profile.secondaryOccupationIds);
      _initialPrimaryOccupationId = profile.occupationId;
      _initialSecondaryOccupationIds = List.from(
        profile.secondaryOccupationIds,
      );
      _isInitialized = true;
    });
  }

  Future<void> _save(UserProfile currentProfile) async {
    final colors = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;

    // Check if verification status is active (verified)
    final isVerified = currentProfile.verificationStatus == 'verified';

    // Calculate if the SET of occupations has changed
    final initialSet = {
      ?_initialPrimaryOccupationId,
      ..._initialSecondaryOccupationIds,
    };
    final currentSet = {?_primaryOccupationId, ..._secondaryOccupationIds};

    final isSubstantiveChange =
        initialSet.length != currentSet.length ||
        !initialSet.containsAll(currentSet);

    if (isSubstantiveChange && isVerified) {
      final confirmed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: 'Cambio de ocupación',
          contentText:
              'Al cambiar tu ocupación (principal o secundaria), perderás tu estado de verificación actual y pasarás a "No verificado". ¿Deseas continuar?',
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedProfile = currentProfile.copyWith(
        occupationId: _primaryOccupationId,
        secondaryOccupationIds: _secondaryOccupationIds,
        verificationStatus: (isVerified && isSubstantiveChange)
            ? 'unverified'
            : currentProfile.verificationStatus,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        AppToast.success(
          context,
          message: 'Ocupación actualizada',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al guardar: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final occupationsAsync = ref.watch(occupationsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ocupación',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => FriendlyErrorWidget(error: e),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil no encontrado'));
          }

          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initializeData(profile);
              }
            });
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return occupationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => FriendlyErrorWidget(error: e),
            data: (occupationsList) {
              final secondaryItems = occupationsList
                  .map((e) => e['id'] as String)
                  .where((id) => id != _primaryOccupationId)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indícanos a qué te dedicas. Esto nos permitirá conectarte con los proveedores adecuados.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

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
                            if (val != null &&
                                _secondaryOccupationIds.contains(val)) {
                              _secondaryOccupationIds.remove(val);
                            }
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Selecciona una ocupación principal.';
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

                      const SizedBox(height: 48),

                      // Buttons
                      FormBottomBar(
                        onCancel: () => context.pop(),
                        onSave: _hasChanges ? () => _save(profile) : null,
                        isSaveEnabled: _hasChanges,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
