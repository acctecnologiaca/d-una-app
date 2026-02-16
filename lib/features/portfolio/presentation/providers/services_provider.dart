import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/supabase_services_repository.dart';
import '../../domain/repositories/services_repository.dart';

part 'services_provider.g.dart';

@riverpod
ServicesRepository servicesRepository(Ref ref) {
  return SupabaseServicesRepository(Supabase.instance.client);
}

@riverpod
class Services extends _$Services {
  @override
  FutureOr<List<ServiceModel>> build() {
    return _fetchServices();
  }

  Future<List<ServiceModel>> _fetchServices() async {
    final repository = ref.read(servicesRepositoryProvider);
    return repository.getServices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchServices());
  }

  // Search logic can be client-side if dataset is small, or server-side.
  // For MVP, filtering the current state is often enough if lists are short.
  // But let's expose a method to search server side if needed, or just filter locally.
  // Given the image shows "Buscar servicio", filtering local list is instant.

  Future<void> addService({
    required String name,
    required String? description,
    required double price,
    required String serviceRateId,
    required String? categoryId,
    required bool hasWarranty,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final service = ServiceModel(
      id: '', // ID handled by DB/Repo
      name: name,
      description: description,
      price: price,
      serviceRateId: serviceRateId,
      categoryId: categoryId,
      hasWarranty: hasWarranty,
      userId: '', // handled by repo
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createService(service);
      return _fetchServices();
    });
  }

  Future<void> updateService(ServiceModel service) async {
    final repository = ref.read(servicesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateService(service);
      return _fetchServices();
    });
  }

  Future<void> deleteService(String id) async {
    final repository = ref.read(servicesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteService(id);
      return _fetchServices();
    });
  }
}
