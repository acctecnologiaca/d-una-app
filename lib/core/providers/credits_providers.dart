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
  RealtimeChannel? _realtimeChannel;

  @override
  Future<CreditStatus> build() async {
    _initRealtimeSubscription();
    return ref.watch(creditsRepositoryProvider).getCreditStatus();
  }

  void _initRealtimeSubscription() {
    if (_realtimeChannel != null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel(
          'public:credit_transactions_changes_${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'credit_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            refreshStatus();
            ref.invalidate(creditTransactionsHistoryProvider);
          },
        )
        .subscribe();

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    });
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
