import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';

class RegisterOccupationScreen extends ConsumerStatefulWidget {
  const RegisterOccupationScreen({super.key});

  @override
  ConsumerState<RegisterOccupationScreen> createState() =>
      _RegisterOccupationScreenState();
}

class _RegisterOccupationScreenState
    extends ConsumerState<RegisterOccupationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _primaryOccupation;
  List<String> _secondaryOccupations = [];
  bool _isSecondaryExpanded = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registerProvider);
    _primaryOccupation = state.primaryOccupation;
    _secondaryOccupations = List.from(state.secondaryOccupations);
  }

  Future<void> _onNext() async {
    if (_formKey.currentState!.validate()) {
      ref
          .read(registerProvider.notifier)
          .updateOccupations(
            primary: _primaryOccupation,
            secondary: _secondaryOccupations,
          );

      try {
        await ref.read(registerProvider.notifier).signUp();
        if (mounted) {
          context.push('/register/verification');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _toggleSecondary(String occupation) {
    setState(() {
      if (_secondaryOccupations.contains(occupation)) {
        _secondaryOccupations.remove(occupation);
      } else {
        if (_secondaryOccupations.length < 2) {
          _secondaryOccupations.add(occupation);
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
    return RegisterLayout(
      title: '¿A qué te dedicas?',
      subtitle:
          'Saber esto, nos permitirá conectarte con los proveedores adecuados.',
      progress: 4, //
      onNext: _onNext,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            // Primary Occupation Dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _primaryOccupation,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Ocupación principal*',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: availableOccupations.map((occ) {
                return DropdownMenuItem(
                  value: occ,
                  child: Text(occ, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _primaryOccupation = val;
                  // Auto-remove from secondary if selected as primary
                  if (val != null && _secondaryOccupations.contains(val)) {
                    _secondaryOccupations.remove(val);
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

            // Secondary Occupations Custom Dropdown/Expander
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isSecondaryExpanded
                      ? Theme.of(context).colorScheme.primary
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
                        () => _isSecondaryExpanded = !_isSecondaryExpanded,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_secondaryOccupations.isEmpty)
                                  Text(
                                    'Otras ocupaciones',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  )
                                else
                                  Text(
                                    _secondaryOccupations.join(', '),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            _isSecondaryExpanded ? Icons.remove : Icons.add,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isSecondaryExpanded)
                    Container(
                      height: 200, // Fixed height scrollable area
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey)),
                        color: Color(0xFFF0F0F0),
                      ),
                      child: ListView.builder(
                        itemCount: availableOccupations.length,
                        itemBuilder: (context, index) {
                          final occ = availableOccupations[index];
                          // Skip primary if selected
                          if (occ == _primaryOccupation) {
                            return const SizedBox.shrink();
                          }

                          final isSelected = _secondaryOccupations.contains(
                            occ,
                          );
                          return CheckboxListTile(
                            title: Text(occ),
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool? checked) {
                              _toggleSecondary(occ);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
