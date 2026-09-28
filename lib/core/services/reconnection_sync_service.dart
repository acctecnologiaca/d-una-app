import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../features/purchases/presentation/providers/purchases_providers.dart';
import '../../features/reports/presentation/reports_list/providers/reports_provider.dart';
import '../../features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import '../../features/clients/presentation/providers/clients_provider.dart';
import '../../features/delivery_notes/presentation/delivery_notes_list/providers/delivery_notes_providers.dart';
import '../../features/portfolio/presentation/providers/products_provider.dart';

/// Servicio centralizado para sincronizar datos tras una reconexión a internet
/// o reanudación desde segundo plano.
class ReconnectionSyncService {
  const ReconnectionSyncService._();

  static bool _isSyncing = false;
  static DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(seconds: 2);

  /// Refresca la sesión de Supabase y fuerza la re-carga de todos los providers clave.
  static Future<void> syncAfterReconnection(WidgetRef ref) async {
    await _executeSync((provider) => ref.invalidate(provider));
  }

  /// Versión que acepta un Ref genérico (para lifecycle o providers).
  static Future<void> syncAfterReconnectionWithRef(Ref ref) async {
    await _executeSync((provider) => ref.invalidate(provider));
  }

  static Future<void> _executeSync(void Function(ProviderOrFamily) invalidate) async {
    // Evitar sincronizaciones simultáneas o duplicadas dentro del cooldown
    if (_isSyncing) return;
    if (_lastSyncTime != null &&
        DateTime.now().difference(_lastSyncTime!) < _syncCooldown) {
      debugPrint('ReconnectionSync: Omitiendo sincronización duplicada (cooldown activo).');
      return;
    }

    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    debugPrint('ReconnectionSync: Refrescando sesión y providers...');

    try {
      await Supabase.instance.client.auth.refreshSession();
      debugPrint('ReconnectionSync: Sesión refrescada exitosamente.');
    } catch (e) {
      debugPrint('ReconnectionSync: Aviso al refrescar sesión: $e');
    } finally {
      _isSyncing = false;
    }

    // Invalidar perfil y parámetros del sistema
    invalidate(userProfileProvider);
    invalidate(shippingMethodsProvider);
    invalidate(verificationDocumentsProvider);

    // Invalidar listados principales
    invalidate(paginatedQuotesListProvider);
    invalidate(paginatedReportsListProvider);
    invalidate(paginatedPurchasesListProvider);
    invalidate(paginatedSupplierOrdersProvider);
    invalidate(paginatedDeliveryNotesProvider);
    invalidate(paginatedProductsProvider);
    invalidate(paginatedClientsProvider);

    debugPrint('ReconnectionSync: Todos los providers fueron invalidados.');
  }
}

