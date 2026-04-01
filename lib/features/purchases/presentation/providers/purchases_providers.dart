import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/purchases_repository.dart';
import '../../domain/models/purchase_model.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(Supabase.instance.client);
});

final purchasesProvider = FutureProvider.family<List<Purchase>, String?>((ref, productId) async {
  final repository = ref.read(purchasesRepositoryProvider);
  return await repository.getPurchases(productId: productId);
});
