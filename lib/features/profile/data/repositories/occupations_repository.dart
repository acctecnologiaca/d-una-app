import 'package:supabase_flutter/supabase_flutter.dart';

class OccupationsRepository {
  final SupabaseClient _supabase;

  OccupationsRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getOccupations() async {
    try {
      final data = await _supabase
          .from('occupations')
          .select('id, name, occupation_sectors!inner(sectors!inner(is_active))')
          .eq('is_active', true)
          .eq('occupation_sectors.sectors.is_active', true)
          .order('name');

      // Deduplicate occupations (in case an occupation belongs to multiple active sectors)
      final seenIds = <String>{};
      final uniqueOccupations = <Map<String, dynamic>>[];

      for (final item in (data as List)) {
        final id = item['id'] as String;
        if (seenIds.add(id)) {
          uniqueOccupations.add({
            'id': id,
            'name': item['name'],
          });
        }
      }

      return uniqueOccupations;
    } catch (e) {
      throw Exception('Error fetching occupations: $e');
    }
  }
}
