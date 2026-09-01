import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/generic_list_screen.dart';
import '../../../../shared/widgets/sort_selector.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../domain/models/collaborator.dart';
import '../providers/collaborators_providers.dart';
import '../widgets/collaborator_list_tile.dart';

class CollaboratorsScreen extends ConsumerStatefulWidget {
  const CollaboratorsScreen({super.key});

  @override
  ConsumerState<CollaboratorsScreen> createState() =>
      _CollaboratorsScreenState();
}

class _CollaboratorsScreenState extends ConsumerState<CollaboratorsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentFilter = ref.watch(collaboratorFilterProvider);
    final collaboratorsAsync = ref.watch(filteredCollaboratorsProvider);

    return GenericListScreen<Collaborator>(
      title: 'Colaboradores',
      headerWidget: Column(
        children: [
          Image.asset(
            'assets/images/collaborators.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Incluye a las personas que trabajan o colaboran contigo y necesitas que hagan parte de una cotización o reporte.',
              textAlign: TextAlign.left,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CollaboratorFilter>(
                segments: const [
                  ButtonSegment(
                    value: CollaboratorFilter.active,
                    label: Text('Activos'),
                    icon: Icon(Icons.people_outline),
                  ),
                  ButtonSegment(
                    value: CollaboratorFilter.inactive,
                    label: Text('Inactivos'),
                    icon: Icon(Icons.person_off_outlined),
                  ),
                ],
                selected: {currentFilter},
                onSelectionChanged: (newSelection) {
                  ref.read(collaboratorFilterProvider.notifier).state =
                      newSelection.first;
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      itemsAsync: collaboratorsAsync,
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.fullName.compareTo(a.fullName);
        }
        return a.fullName.compareTo(b.fullName);
      },
      onSearch: (c, query) {
        final q = query.toLowerCase();
        final matchName = c.fullName.toLowerCase().contains(q);
        final matchRole = (c.charge ?? '').toLowerCase().contains(q);
        return matchName || matchRole;
      },
      onAddPressed: () => context.push('/collaborators/add'),
      emptyListMessage: currentFilter == CollaboratorFilter.active
          ? 'No tienes colaboradores activos registrados.'
          : 'No tienes colaboradores inactivos.',
      itemBuilder: (context, collaborator) {
        return CollaboratorListTile(
          name: collaborator.fullName,
          role: collaborator.charge ?? 'Sin cargo',
          initial: collaborator.fullName.isNotEmpty
              ? collaborator.fullName[0].toUpperCase()
              : '?',
          isActive: collaborator.isActive,
          onWhatsAppTap: () => ContactUtils.launchWhatsApp(collaborator.phone),
          onPhoneTap: () => ContactUtils.makePhoneCall(collaborator.phone),
          onTap: () {
            context.push('/collaborators/add', extra: collaborator);
          },
        );
      },
    );
  }
}
