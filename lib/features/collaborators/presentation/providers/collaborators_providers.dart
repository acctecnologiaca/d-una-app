import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/collaborator.dart';
import '../../data/repositories/collaborators_repository.dart';

final collaboratorsRepositoryProvider = Provider<CollaboratorsRepository>((
  ref,
) {
  return CollaboratorsRepository(Supabase.instance.client);
});

enum CollaboratorFilter { active, inactive }

final collaboratorFilterProvider = StateProvider<CollaboratorFilter>((ref) {
  return CollaboratorFilter.active;
});

final allCollaboratorsProvider = FutureProvider<List<Collaborator>>((ref) async {
  return ref.watch(collaboratorsRepositoryProvider).getCollaborators();
});

final activeCollaboratorsProvider = FutureProvider<List<Collaborator>>((ref) async {
  return ref.watch(collaboratorsRepositoryProvider).getCollaborators(activeOnly: true);
});

/// Default for document selectors: only active collaborators
final collaboratorsProvider = activeCollaboratorsProvider;

/// Filtered external collaborators based on current status filter (active/inactive)
final filteredCollaboratorsProvider = Provider<AsyncValue<List<Collaborator>>>((ref) {
  final filter = ref.watch(collaboratorFilterProvider);
  final allAsync = ref.watch(allCollaboratorsProvider);

  return allAsync.whenData((list) {
    return list.where((c) {
      if (c.isUserRecord) return false;
      if (filter == CollaboratorFilter.active) {
        return c.isActive;
      } else {
        return !c.isActive;
      }
    }).toList();
  });
});

final externalCollaboratorsProvider = Provider<AsyncValue<List<Collaborator>>>((ref) {
  return ref.watch(filteredCollaboratorsProvider);
});

final collaboratorHasDocumentsProvider =
    FutureProvider.family<bool, String>((ref, id) async {
  return ref.watch(collaboratorsRepositoryProvider).hasLinkedDocuments(id);
});
