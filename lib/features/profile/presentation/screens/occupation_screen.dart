import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/occupations_provider.dart'; // Import Provider
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class OccupationScreen extends ConsumerStatefulWidget {
  const OccupationScreen({super.key});

  @override
  ConsumerState<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends ConsumerState<OccupationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _primaryOccupationId; // Store ID
  List<String> _secondaryOccupationIds = []; // Store IDs
  bool _isSecondaryExpanded = false;
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
    // Sort and compare to ignore order if that matters, or just strict set comparison
    final currentSet = _secondaryOccupationIds.toSet();
    final initialSet = _initialSecondaryOccupationIds.toSet();
    return !currentSet.containsAll(initialSet);
  }

  @override
  void initState() {
    super.initState();
    // Data loading handled by Riverpod listener in build
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
    if (!_formKey.currentState!.validate()) return;

    // Check if verification status is active (verified or pending)
    final isVerifiedOrPending =
        currentProfile.verificationStatus == 'verified' ||
        currentProfile.verificationStatus == 'pending';

    // Calculate if the SET of occupations has changed
    final initialSet = {
      if (_initialPrimaryOccupationId != null) _initialPrimaryOccupationId!,
      ..._initialSecondaryOccupationIds,
    };
    final currentSet = {
      if (_primaryOccupationId != null) _primaryOccupationId!,
      ..._secondaryOccupationIds,
    };

    final isSubstantiveChange =
        initialSet.length != currentSet.length ||
        !initialSet.containsAll(currentSet);

    if (isSubstantiveChange && isVerifiedOrPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambio de ocupación'),
          content: const Text(
            'Al cambiar tu ocupación (principal o secundaria), perderás tu estado de verificación actual y pasarás a "No verificado". ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Aceptar', style: TextStyle(color: Colors.red)),
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
        // Reset verification status if it was verified/pending and substantive changes were made
        verificationStatus: (isVerifiedOrPending && isSubstantiveChange)
            ? 'unverified'
            : currentProfile.verificationStatus,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocupación actualizada')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSecondary(String occupationId) {
    setState(() {
      if (_secondaryOccupationIds.contains(occupationId)) {
        _secondaryOccupationIds.remove(occupationId);
      } else {
        if (_secondaryOccupationIds.length < 2) {
          _secondaryOccupationIds.add(occupationId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máximo 2 ocupaciones secundarias')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final occupationsAsync = ref.watch(
      occupationsProvider,
    ); // Watch Occupations

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
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil no encontrado'));
          }

          // Initialize data once only
          if (!_isInitialized) {
            // Defer state update to next frame to avoid build error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeData(profile);
            });
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return occupationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) =>
                Center(child: Text('Error al cargar ocupaciones: $e')),
            data: (occupationsList) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indícanos a que te dedicas. Esto nos permitirá conectarte con los proveedores adecuados',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Primary Occupation Dropdown
                      CustomDropdown<String>(
                        label: 'Ocupación principal',
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
                            return 'Selecciona una ocupación principal.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Secondary Occupations Custom Dropdown/Expander
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(
                            color: _isSecondaryExpanded
                                ? colors.primary
                                : Colors.grey.shade400,
                            width: _isSecondaryExpanded ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(
                                  () => _isSecondaryExpanded =
                                      !_isSecondaryExpanded,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_secondaryOccupationIds.isEmpty)
                                            Text(
                                              'Otras ocupaciones',
                                              style: TextStyle(
                                                color: Colors
                                                    .grey
                                                    .shade600, // Hint style
                                                fontSize:
                                                    16, // Match input text size
                                              ),
                                            )
                                          else
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Otras ocupaciones',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _secondaryOccupationIds
                                                      .map((id) {
                                                        final occ = occupationsList
                                                            .firstWhere(
                                                              (element) =>
                                                                  element['id'] ==
                                                                  id,
                                                              orElse: () => {
                                                                'name':
                                                                    'Desconocido',
                                                              },
                                                            );
                                                        return occ['name'];
                                                      })
                                                      .join(', '),
                                                  style: TextStyle(
                                                    color: colors.onSurface,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _isSecondaryExpanded
                                          ? Icons.remove
                                          : Icons.add,
                                      color: colors.onSurface,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isSecondaryExpanded)
                              Container(
                                height: 200, // Fixed height scrollable area
                                decoration: BoxDecoration(
                                  border: const Border(
                                    top: BorderSide(color: Colors.grey),
                                  ),
                                  color: Colors.grey.shade100,
                                ),
                                child: ListView.builder(
                                  itemCount: occupationsList.length,
                                  itemBuilder: (context, index) {
                                    final occ = occupationsList[index];
                                    final id = occ['id'] as String;
                                    final name = occ['name'] as String;

                                    // Skip primary if selected
                                    if (id == _primaryOccupationId) {
                                      return const SizedBox.shrink();
                                    }

                                    final isSelected = _secondaryOccupationIds
                                        .contains(id);
                                    return CheckboxListTile(
                                      title: Text(name),
                                      value: isSelected,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      onChanged: (bool? checked) {
                                        _toggleSecondary(id);
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
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
