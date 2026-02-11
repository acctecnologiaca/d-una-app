import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/occupations_repository.dart';

part 'occupations_provider.g.dart';

@riverpod
OccupationsRepository occupationsRepository(Ref ref) {
  return OccupationsRepository(Supabase.instance.client);
}

@riverpod
Future<List<Map<String, dynamic>>> occupations(Ref ref) async {
  return ref.watch(occupationsRepositoryProvider).getOccupations();
}

// Helper to get name by ID
@riverpod
String? occupationName(Ref ref, String? id) {
  if (id == null) return null;
  final listAsync = ref.watch(occupationsProvider);
  return listAsync.when(
    data: (list) =>
        list.firstWhere(
              (element) => element['id'] == id,
              orElse: () => {'name': 'Desconocido'},
            )['name']
            as String?,
    error: (_, _) => null,
    loading: () => 'Cargando...',
  );
}
