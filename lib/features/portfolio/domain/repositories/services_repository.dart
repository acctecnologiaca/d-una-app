import '../../data/models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceModel>> getServices();
  Future<List<ServiceModel>> getServicesPaginated({
    required int offset,
    required int limit,
    String? searchQuery,
    String? categoryId,
    String? rateId,
    String orderBy = 'created_at',
    bool ascending = false,
  });
  Future<List<ServiceModel>> searchServices(String query);
  Future<void> createService(ServiceModel service);
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService(String id);
}
