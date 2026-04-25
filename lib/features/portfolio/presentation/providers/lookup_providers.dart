import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/models/service_rate_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/brand_model.dart';
import '../../data/models/uom_model.dart';
import '../../domain/models/unaffiliated_supplier_model.dart';
import '../../../quotes/data/models/commercial_condition.dart';
import '../../../settings/data/models/observation.dart';
import '../../../settings/data/models/shipping_company.dart';
import '../../data/models/delivery_time_model.dart';

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getCategories();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final brands = await ref.watch(lookupRepositoryProvider).getBrands();
  // Ensure "SIN MARCA" is always the first option
  final sortedBrands = List<Brand>.from(brands);
  final sinMarcaIndex = sortedBrands.indexWhere(
    (b) => b.name.toUpperCase() == 'SIN MARCA',
  );

  if (sinMarcaIndex > -1) {
    final sinMarca = sortedBrands.removeAt(sinMarcaIndex);
    sortedBrands.insert(0, sinMarca);
  }

  return sortedBrands;
});

final serviceRatesProvider = FutureProvider<List<ServiceRate>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getServiceRates();
});

final uomsProvider = FutureProvider<List<Uom>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getUoms();
});

final unaffiliatedSuppliersProvider =
    FutureProvider<List<UnaffiliatedSupplier>>((ref) async {
      return ref.watch(lookupRepositoryProvider).getUnaffiliatedSuppliers();
    });

final allSuppliersProvider = FutureProvider<List<UnaffiliatedSupplier>>((
  ref,
) async {
  return ref.watch(lookupRepositoryProvider).getAllSuppliers();
});

final commercialConditionsProvider = FutureProvider<List<CommercialCondition>>((
  ref,
) async {
  return ref.watch(lookupRepositoryProvider).getCommercialConditions();
});

final observationsProvider = FutureProvider<List<Observation>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getObservations();
});

final shippingCompaniesProvider = FutureProvider<List<ShippingCompany>>((
  ref,
) async {
  return ref.watch(lookupRepositoryProvider).getShippingCompanies();
});

final deliveryTimesProvider = FutureProvider<List<DeliveryTime>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getDeliveryTimes();
});

final deliveryTimesForDeliveryProvider = FutureProvider<List<DeliveryTime>>((
  ref,
) async {
  final allTimes = await ref.watch(deliveryTimesProvider.future);
  return allTimes
      .where((dt) => dt.type == 'delivery' || dt.type == 'both')
      .toList();
});

final deliveryTimesForExecutionProvider = FutureProvider<List<DeliveryTime>>((
  ref,
) async {
  final allTimes = await ref.watch(deliveryTimesProvider.future);
  return allTimes
      .where((dt) => dt.type == 'execution' || dt.type == 'both')
      .toList();
});
