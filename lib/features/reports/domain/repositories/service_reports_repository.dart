import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../../portfolio/data/models/category_model.dart';
import '../../../quotes/data/models/commercial_condition.dart';
import '../../../quotes/data/models/financial_parameter.dart';

abstract class ServiceReportsRepository {
  // Auxiliary Data
  Future<List<CommercialCondition>> getCommercialConditions();
  Future<FinancialParameter> getFinancialParameters();
  Future<List<Category>> getCategories();

  // Report CRUD
  Future<List<ServiceReport>> getReports({
    String? status,
    String? clientId,
    bool includeArchived = false,
  });

  Future<List<ServiceReport>> getReportsPaginated({
    required int offset,
    int limit = 25,
    String orderBy = 'service_date',
    bool ascending = false,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    DateTimeRange? dateRange,
    bool includeArchived = false,
    String? productId,
    String? clientId,
  });

  Future<ServiceReport> getReportById(String id);
  Future<ServiceReport> getReportWithDetails(String id);
  Future<String?> getLastReportNumber();

  Future<ServiceReport> createReport(
    ServiceReport report, {
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    List<String>? technicianIds,
  });

  Future<ServiceReport> updateReport(
    ServiceReport report, {
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    List<String>? technicianIds,
  });

  Future<void> updateReportStatus(String id, String status);
  Future<void> updateReportDate(String id, DateTime newDate);
  Future<void> archiveReport(String id, bool isArchived);
  Future<void> deleteReport(String id);

  // Batch Operations
  Future<List<String>> batchUpdateStatus(List<String> ids, String status);
  Future<void> batchArchive(List<String> ids, bool isArchived);

  // PDF Storage & WebViewer Actions
  Future<String> uploadReportPdf({
    required String reportId,
    required List<int> pdfBytes,
    required String fileName,
  });
  Future<String> generateActionToken(String reportId);
}
