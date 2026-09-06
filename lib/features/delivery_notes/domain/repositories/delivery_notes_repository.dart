import '../models/delivery_note_model.dart';
import '../models/delivery_note_status.dart';

abstract class DeliveryNotesRepository {
  Future<List<DeliveryNoteModel>> getDeliveryNotes({bool? isArchived});

  Future<List<DeliveryNoteModel>> getDeliveryNotesPaginated({
    required int offset,
    int limit = 25,
    String? searchQuery,
    String? statusFilter,
    bool includeArchived = false,
    String orderBy = 'date',
    bool ascending = false,
  });

  Future<DeliveryNoteModel?> getDeliveryNoteById(String id);

  Future<DeliveryNoteModel?> getDeliveryNoteWithDetails(String id);

  Future<DeliveryNoteModel> createDeliveryNote(DeliveryNoteModel note);

  Future<DeliveryNoteModel> updateDeliveryNote(DeliveryNoteModel note);

  Future<void> deleteDeliveryNote(String id);

  Future<void> setArchived(String id, bool isArchived);

  Future<void> archiveDeliveryNote(String id, bool isArchived);

  Future<void> updateStatus(String id, DeliveryNoteStatus status);

  Future<void> updateDeliveryNoteStatus(String id, DeliveryNoteStatus status);

  Future<void> registerPhysicalSignature(
    String id, {
    required String receivedByName,
    required String receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    required String signatureData,
  });

  Future<void> confirmReception(
    String id, {
    required String receivedByName,
    required String receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    String? signatureData,
    DeliveryNoteStatus? status,
  });

  Future<void> batchUpdateStatus(List<String> ids, DeliveryNoteStatus status);

  Future<void> batchArchive(List<String> ids, bool isArchived);

  Future<void> batchDelete(List<String> ids);

  Future<String> generateActionToken(String id);

  Stream<List<DeliveryNoteModel>> watchDeliveryNotes();

  Future<List<DeliveryNoteModel>> getDeliveryNotesByQuoteId(String quoteId);

  Future<List<DeliveryNoteModel>> getDeliveryNotesBySupplierOrderId(String supplierOrderId);

  Future<String?> getLastDeliveryNoteNumber();
}
