import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/credits_repository.dart';
import '../models/credit_status.dart';
import '../models/credit_transaction_model.dart';

part 'credits_providers.g.dart';

@riverpod
CreditsRepository creditsRepository(CreditsRepositoryRef ref) {
  return CreditsRepository(Supabase.instance.client);
}

@riverpod
class UserCreditsStatus extends _$UserCreditsStatus {
  @override
  Future<CreditStatus> build() async {
    return ref.watch(creditsRepositoryProvider).getCreditStatus();
  }

  Future<void> refreshStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(creditsRepositoryProvider).getCreditStatus(),
    );
  }
}

@riverpod
Future<List<CreditTransactionModel>> creditTransactionsHistory(
  CreditTransactionsHistoryRef ref,
) async {
  return ref.watch(creditsRepositoryProvider).getCreditTransactions();
}
