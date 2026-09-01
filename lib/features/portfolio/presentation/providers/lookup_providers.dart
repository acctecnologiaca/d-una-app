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

import '../../../profile/presentation/providers/profile_provider.dart';

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final userProfile = ref.watch(userProfileProvider).valueOrNull;

  final occupationIds = <String>[];
  if (userProfile?.occupationId != null && userProfile!.occupationId!.isNotEmpty) {
    occupationIds.add(userProfile.occupationId!);
  }
  if (userProfile?.secondaryOccupationIds != null) {
    occupationIds.addAll(userProfile!.secondaryOccupationIds);
  }

  // Fetch relevant categories via RPC
  final categories = await ref
      .watch(lookupRepositoryProvider)
      .getRelevantCategories(occupationIds: occupationIds);

  // Return verified categories matching the user's sectors/global OR custom categories owned by current user
  return categories.where((category) {
    return category.isVerified || (currentUserId != null && category.userId == currentUserId);
  }).toList();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final brands = await ref.watch(lookupRepositoryProvider).getBrands();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Filter: verified brands OR brands owned by the current user
  final filteredBrands = brands.where((brand) {
    return brand.isVerified || (currentUserId != null && brand.userId == currentUserId);
  }).toList();

  // Ensure "SIN MARCA" is always the first option
  final sortedBrands = List<Brand>.from(filteredBrands);
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
  final rates = await ref.watch(lookupRepositoryProvider).getServiceRates();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Filter: verified service rates OR service rates owned by the current user
  return rates.where((rate) {
    return rate.isVerified || (currentUserId != null && rate.userId == currentUserId);
  }).toList();
});

final uomsProvider = FutureProvider<List<Uom>>((ref) async {
  final uoms = await ref.watch(lookupRepositoryProvider).getUoms();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Filter: verified UOMs OR UOMs owned by the current user
  return uoms.where((uom) {
    return uom.isVerified || (currentUserId != null && uom.userId == currentUserId);
  }).toList();
});

final unaffiliatedSuppliersProvider =
    FutureProvider<List<UnaffiliatedSupplier>>((ref) async {
      final suppliers = await ref.watch(lookupRepositoryProvider).getUnaffiliatedSuppliers();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      // Filter: verified suppliers OR suppliers owned by the current user
      return suppliers.where((supplier) {
        return supplier.isVerified || (currentUserId != null && supplier.userId == currentUserId);
      }).toList();
    });

final allSuppliersProvider = FutureProvider<List<UnaffiliatedSupplier>>((
  ref,
) async {
  return ref.watch(lookupRepositoryProvider).getAllSuppliers();
});

final affiliatedSuppliersProvider = FutureProvider<List<UnaffiliatedSupplier>>((
  ref,
) async {
  return ref.watch(lookupRepositoryProvider).getAffiliatedSuppliers();
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
  final companies = await ref.watch(lookupRepositoryProvider).getShippingCompanies();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Filter: verified shipping companies OR shipping companies owned by the current user
  return companies.where((company) {
    return company.isVerified || (currentUserId != null && company.userId == currentUserId);
  }).toList();
});

final deliveryTimesProvider = FutureProvider<List<DeliveryTime>>((ref) async {
  final times = await ref.watch(lookupRepositoryProvider).getDeliveryTimes();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Filter: MUST be active AND (verified OR owned by current user)
  return times.where((dt) {
    if (!dt.isActive) return false;
    return dt.isVerified || (currentUserId != null && dt.userId == currentUserId);
  }).toList();
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

final paymentMethodsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getPaymentMethods();
});
