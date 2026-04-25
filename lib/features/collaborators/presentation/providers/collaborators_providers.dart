import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/collaborator.dart';
import '../../data/repositories/collaborators_repository.dart';

final collaboratorsRepositoryProvider = Provider<CollaboratorsRepository>((
  ref,
) {
  return CollaboratorsRepository(Supabase.instance.client);
});

final collaboratorsProvider = FutureProvider<List<Collaborator>>((ref) async {
  return ref.watch(collaboratorsRepositoryProvider).getCollaborators();
});

final externalCollaboratorsProvider = Provider<AsyncValue<List<Collaborator>>>((
  ref,
) {
  return ref
      .watch(collaboratorsProvider)
      .whenData((list) => list.where((c) => !c.isUserRecord).toList());
});
