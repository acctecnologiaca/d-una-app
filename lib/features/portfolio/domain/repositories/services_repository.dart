import '../../data/models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceModel>> getServices();
  Future<List<ServiceModel>> searchServices(String query);
  Future<void> createService(ServiceModel service);
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService(String id);
}
