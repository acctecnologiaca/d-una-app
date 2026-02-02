import 'package:supabase_flutter/supabase_flutter.dart';

class OccupationsRepository {
  final SupabaseClient _supabase;

  OccupationsRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getOccupations() async {
    try {
      final data = await _supabase
          .from('occupations')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error fetching occupations: $e');
    }
  }
}
