import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/suppliers_repository.dart';
import '../../domain/models/supplier_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'suppliers_provider.g.dart';

@riverpod
SuppliersRepository suppliersRepository(Ref ref) {
  return SuppliersRepository(Supabase.instance.client);
}

@riverpod
Future<List<Supplier>> suppliers(Ref ref) async {
  final userProfile = await ref.watch(userProfileProvider.future);

  if (userProfile == null) {
    return [];
  }

  // Collect all available occupation IDs (Primary + Secondary)
  final occupationIds = <String>[];
  if (userProfile.occupationId != null) {
    occupationIds.add(userProfile.occupationId!);
  }
  occupationIds.addAll(userProfile.secondaryOccupationIds);

  return ref
      .watch(suppliersRepositoryProvider)
      .getSuppliers(occupationIds: occupationIds);
}
