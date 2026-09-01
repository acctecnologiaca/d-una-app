import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../features/purchases/presentation/providers/purchases_providers.dart';
import '../../features/reports/presentation/reports_list/providers/reports_provider.dart';
import '../../features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import '../../features/clients/presentation/providers/clients_provider.dart';

/// Servicio centralizado para sincronizar datos tras una reconexión a internet
/// o reanudación desde segundo plano. Elimina la duplicación entre
/// ConnectivityGate y _DUnaAppState.didChangeAppLifecycleState.
class ReconnectionSyncService {
  const ReconnectionSyncService._();

  /// Refresca la sesión de Supabase y fuerza la re-carga de los providers
  /// de datos clave (profile, shipping methods, supplier orders, purchases, reports, quotes, clients).
  static Future<void> syncAfterReconnection(WidgetRef ref) async {
    debugPrint('ReconnectionSync: Refrescando sesión y providers...');
    try {
      await Supabase.instance.client.auth.refreshSession();
      debugPrint('ReconnectionSync: Sesión refrescada exitosamente.');
    } catch (e) {
      debugPrint('ReconnectionSync: Error al refrescar sesión: $e');
    }

    ref.invalidate(userProfileProvider);
    ref.invalidate(shippingMethodsProvider);
    ref.invalidate(verificationDocumentsProvider);
    ref.invalidate(paginatedSupplierOrdersProvider);
    ref.invalidate(paginatedPurchasesListProvider);
    ref.invalidate(paginatedReportsListProvider);
    ref.invalidate(paginatedQuotesListProvider);
    ref.invalidate(paginatedClientsProvider);
  }

  /// Versión que acepta un Ref genérico (para usar desde providers o lifecycle).
  static Future<void> syncAfterReconnectionWithRef(Ref ref) async {
    debugPrint('ReconnectionSync: Refrescando sesión y providers (desde Ref)...');
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (e) {
      debugPrint('ReconnectionSync: Error al refrescar sesión: $e');
    }

    ref.invalidate(userProfileProvider);
    ref.invalidate(shippingMethodsProvider);
    ref.invalidate(verificationDocumentsProvider);
    ref.invalidate(paginatedSupplierOrdersProvider);
    ref.invalidate(paginatedPurchasesListProvider);
    ref.invalidate(paginatedReportsListProvider);
    ref.invalidate(paginatedQuotesListProvider);
    ref.invalidate(paginatedClientsProvider);
  }
}
