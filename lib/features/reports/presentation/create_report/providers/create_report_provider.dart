import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../../../../collaborators/domain/models/collaborator.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../clients/data/models/client_model.dart';
import '../../../../quotes/data/models/commercial_condition.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../../core/utils/country_iso_codes.dart';

class ServiceReportCreateState {
  final ServiceReport? report;
  final List<ServiceReportItemProduct> products;
  final List<ServiceReportItemService> services;
  final List<ServiceReportCondition> conditions;
  final String? clientId;
  final String? clientName;
  final String? contactId;
  final String? contactName;
  final String? categoryId;
  final String? categoryName;
  final String? advisorId;
  final String? advisorName;
  final InterventionType interventionType;
  final String requestDescription;
  final String workDescription;
  final String recommendations;
  final DateTime serviceDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int? durationMinutes;
  final String? notes;
  final String? reportTag;
  final String? currentReportNumber;
  final String? clientType;
  final bool isLoading;
  final String? error;

  // Financial Context
  final double globalMargin;
  final double globalTaxRate;
  final String pricingMethod;
  final bool isReadOnly;

  ServiceReportCreateState({
    this.report,
    this.products = const [],
    this.services = const [],
    this.conditions = const [],
    this.clientId,
    this.clientName,
    this.contactId,
    this.contactName,
    this.categoryId,
    this.categoryName,
    this.advisorId,
    this.advisorName,
    this.interventionType = InterventionType.corrective,
    this.requestDescription = '',
    this.workDescription = '',
    this.recommendations = '',
    DateTime? serviceDate,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.notes,
    this.reportTag,
    this.currentReportNumber,
    this.clientType,
    this.isLoading = false,
    this.error,
    this.globalMargin = 0.0,
    this.globalTaxRate = 0.0,
    this.pricingMethod = 'margin',
    this.isReadOnly = false,
  }) : serviceDate = serviceDate ?? DateTime.now();

  ServiceReportCreateState copyWith({
    ServiceReport? report,
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    String? clientId,
    String? clientName,
    String? contactId,
    String? contactName,
    String? categoryId,
    String? categoryName,
    String? advisorId,
    String? advisorName,
    InterventionType? interventionType,
    String? requestDescription,
    String? workDescription,
    String? recommendations,
    DateTime? serviceDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    String? notes,
    String? reportTag,
    String? currentReportNumber,
    String? clientType,
    bool? isLoading,
    String? error,
    double? globalMargin,
    double? globalTaxRate,
    String? pricingMethod,
    bool? isReadOnly,
  }) {
    return ServiceReportCreateState(
      report: report ?? this.report,
      products: products ?? this.products,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      advisorId: advisorId ?? this.advisorId,
      advisorName: advisorName ?? this.advisorName,
      interventionType: interventionType ?? this.interventionType,
      requestDescription: requestDescription ?? this.requestDescription,
      workDescription: workDescription ?? this.workDescription,
      recommendations: recommendations ?? this.recommendations,
      serviceDate: serviceDate ?? this.serviceDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      reportTag: reportTag ?? this.reportTag,
      currentReportNumber: currentReportNumber ?? this.currentReportNumber,
      clientType: clientType ?? this.clientType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      globalMargin: globalMargin ?? this.globalMargin,
      globalTaxRate: globalTaxRate ?? this.globalTaxRate,
      pricingMethod: pricingMethod ?? this.pricingMethod,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  // --- Getters for validation & calculations ---
  bool get isReadyToSaveDraft {
    final hasItems = products.isNotEmpty || services.isNotEmpty;
    return clientId != null && hasItems;
  }

  bool get isReadyToFinalize {
    final hasItems = products.isNotEmpty || services.isNotEmpty;
    final hasConditions = conditions.isNotEmpty;
    final baseFields =
        clientId != null && categoryId != null && advisorId != null;

    bool contactValid = true;
    if (clientType == 'company') {
      contactValid = contactId != null;
    }

    final hasWorkInfo = workDescription.trim().isNotEmpty;

    return hasItems &&
        hasConditions &&
        baseFields &&
        contactValid &&
        hasWorkInfo;
  }

  double get productsSubtotal =>
      products.fold(0.0, (sum, p) => sum + (p.unitPrice * p.quantity));

  double get productsCost =>
      products.fold(0.0, (sum, p) => sum + (p.costPrice * p.quantity));

  double get servicesSubtotal =>
      services.fold(0.0, (sum, s) => sum + (s.unitPrice * s.quantity));

  double get servicesCost =>
      services.fold(0.0, (sum, s) => sum + (s.costPrice * s.quantity));

  double get totalSales => productsSubtotal + servicesSubtotal;
  double get totalCosts => productsCost + servicesCost;
  double get estimatedProfit => totalSales - totalCosts;

  int get nextGroupIndex {
    if (products.isEmpty) return 1;
    final maxIndex = products.fold<int>(
      0,
      (max, p) => p.groupIndex > max ? p.groupIndex : max,
    );
    return maxIndex + 1;
  }

  int get nextServiceIndex {
    if (services.isEmpty) return 1;
    final maxIndex = services.fold<int>(
      0,
      (max, s) => s.orderIndex > max ? s.orderIndex : max,
    );
    return maxIndex + 1;
  }

  double get taxAmount {
    final taxRateDecimal = globalTaxRate > 1
        ? globalTaxRate / 100
        : globalTaxRate;
    return totalSales * taxRateDecimal;
  }

  double get finalTotal => totalSales + taxAmount;

  bool get hasChanges {
    if (isReadOnly) return false;

    if (report == null || report!.id.isEmpty) {
      return products.isNotEmpty ||
          services.isNotEmpty ||
          clientId != null ||
          workDescription.isNotEmpty ||
          requestDescription.isNotEmpty;
    }

    if (clientId != report!.clientId) return true;
    if (contactId != report!.contactId) return true;
    if (advisorId != report!.advisorId) return true;
    if (categoryId != report!.categoryId) return true;
    if (interventionType.dbValue != report!.interventionType) return true;
    if (requestDescription != (report!.requestDescription ?? '')) return true;
    if (workDescription != (report!.workDescription ?? '')) return true;
    if (recommendations != (report!.recommendations ?? '')) return true;
    if (notes != (report!.notes ?? '')) return true;
    if (reportTag != (report!.reportTag ?? '')) return true;

    // Check items length
    if (products.length != (report!.products?.length ?? 0)) return true;
    if (services.length != (report!.services?.length ?? 0)) return true;
    if (conditions.length != (report!.conditions?.length ?? 0)) return true;

    return false;
  }
}

class CreateServiceReportNotifier
    extends StateNotifier<ServiceReportCreateState> {
  final Ref ref;

  CreateServiceReportNotifier(this.ref) : super(ServiceReportCreateState()) {
    initReport();
  }

  Future<void> initReport() async {
    await loadFinancialParameters();
    await fetchNextReportNumber();
    await loadDefaultAdvisor();
    await loadDefaultConditions();
  }

  Future<void> loadFinancialParameters() async {
    final repo = ref.read(serviceReportsRepositoryProvider);
    try {
      final financialParams = await repo.getFinancialParameters();
      state = state.copyWith(
        globalMargin: financialParams.profitMargin,
        globalTaxRate: financialParams.taxRate,
        pricingMethod: financialParams.pricingMethod,
      );
    } catch (e) {
      debugPrint("Error al cargar parámetros financieros: $e");
    }
  }

  Future<void> loadDefaultAdvisor() async {
    try {
      final collaborators = await ref.read(collaboratorsProvider.future);
      Collaborator? defaultCollab;
      for (final c in collaborators) {
        if (c.isUserRecord) {
          defaultCollab = c;
          break;
        }
      }
      defaultCollab ??= collaborators.isNotEmpty ? collaborators.first : null;
      if (defaultCollab != null && state.advisorId == null) {
        state = state.copyWith(
          advisorId: defaultCollab.id,
          advisorName: defaultCollab.fullName,
        );
      }
    } catch (e) {
      debugPrint("Error al cargar colaborador predeterminado: $e");
    }
  }

  Future<void> loadDefaultConditions() async {
    try {
      final conditions = await ref.read(commercialConditionsProvider.future);
      final defaultConditions = conditions
          .where((c) => c.isDefaultReport)
          .toList();

      if (defaultConditions.isNotEmpty && state.conditions.isEmpty) {
        addConditions(defaultConditions);
      }
    } catch (e) {
      debugPrint("Error al cargar condiciones por defecto: $e");
    }
  }

  String _getUserCode() {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return 'XX0000';

    final countryCode = CountryIsoCodes.getCode(profile.mainCountry);
    final userNum = profile.userNumber ?? 0;
    final hexPart = userNum.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$countryCode$hexPart';
  }

  String _generateNextReportNumber(String? lastNumber) {
    final userCode = _getUserCode();
    final currentYear = DateTime.now().year % 100; // e.g. 26 for 2026
    final yearPrefix = currentYear.toString().padLeft(2, '0');

    int nextSeq = 1;

    if (lastNumber != null) {
      // Format: RS-XXXXXX-YYSEQ
      final parts = lastNumber.split('-');
      if (parts.length >= 3) {
        final lastPart = parts.last; // e.g. "26001"
        if (lastPart.length == 5) {
          final yearInLast = lastPart.substring(0, 2); // e.g. "26"
          final seqInLast = lastPart.substring(2); // e.g. "001"
          if (yearInLast == yearPrefix) {
            final parsed = int.tryParse(seqInLast);
            if (parsed != null) {
              nextSeq = parsed + 1;
            }
          }
        }
      }
    }

    final seqFormatted = nextSeq.toString().padLeft(3, '0');
    return 'RS-$userCode-$yearPrefix$seqFormatted';
  }

  Future<void> fetchNextReportNumber() async {
    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final lastNumber = await repo.getLastReportNumber();
      final nextNumber = _generateNextReportNumber(lastNumber);
      state = state.copyWith(currentReportNumber: nextNumber);
    } catch (e) {
      state = state.copyWith(error: "Error al generar número: $e");
    }
  }

  void reset() {
    state = ServiceReportCreateState();
    initReport();
  }

  Future<void> loadReport(String reportId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final report = await repo.getReportWithDetails(reportId);

      TimeOfDay? start;
      if (report.startTime != null && report.startTime!.contains(':')) {
        final parts = report.startTime!.split(':');
        start = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      TimeOfDay? end;
      if (report.endTime != null && report.endTime!.contains(':')) {
        final parts = report.endTime!.split(':');
        end = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      state = state.copyWith(
        report: report,
        currentReportNumber: report.reportNumber,
        clientId: report.clientId,
        clientName: report.clientName,
        clientType: report.clientType,
        contactId: report.contactId,
        contactName: report.contactName,
        categoryId: report.categoryId,
        categoryName: report.categoryName,
        advisorId: report.advisorId,
        advisorName: report.advisorName,
        interventionType: InterventionType.fromDbValue(report.interventionType),
        requestDescription: report.requestDescription ?? '',
        workDescription: report.workDescription ?? '',
        recommendations: report.recommendations ?? '',
        serviceDate: report.serviceDate,
        startTime: start,
        endTime: end,
        durationMinutes: report.durationMinutes,
        notes: report.notes,
        reportTag: report.reportTag,
        products: report.products ?? [],
        services: report.services ?? [],
        conditions: report.conditions ?? [],
        isLoading: false,
        isReadOnly: report.status == ServiceReportStatus.finalized.dbValue,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Field updates ---
  void setInterventionType(InterventionType type) {
    state = state.copyWith(interventionType: type);
  }

  void setCategory(String? id, String? name) {
    state = state.copyWith(categoryId: id, categoryName: name);
  }

  void setRequestDescription(String text) {
    state = state.copyWith(requestDescription: text);
  }

  void setWorkDescription(String text) {
    state = state.copyWith(workDescription: text);
  }

  void setRecommendations(String text) {
    state = state.copyWith(recommendations: text);
  }

  void setServiceDate(DateTime date) {
    state = state.copyWith(serviceDate: date);
  }

  void setTimes({TimeOfDay? start, TimeOfDay? end, int? durationMinutes}) {
    state = state.copyWith(
      startTime: start ?? state.startTime,
      endTime: end ?? state.endTime,
      durationMinutes: durationMinutes ?? state.durationMinutes,
    );
  }

  void setAdvisor(String? id, String? name) {
    state = state.copyWith(advisorId: id, advisorName: name);
  }

  void setClient(Client client) {
    String? contactId;
    String? contactName;

    if (client.type == 'company' && client.contacts.isNotEmpty) {
      final primaryContact = client.contacts.firstWhere(
        (c) => c.isPrimary,
        orElse: () => client.contacts.first,
      );
      contactId = primaryContact.id;
      contactName = primaryContact.name;
    }

    state = state.copyWith(
      clientId: client.id,
      clientName: client.name,
      clientType: client.type,
      contactId: contactId,
      contactName: contactName,
    );
  }

  void clearClient() {
    state = ServiceReportCreateState(
      report: state.report,
      products: state.products,
      services: state.services,
      conditions: state.conditions,
      clientId: null,
      clientName: null,
      clientType: null,
      contactId: null,
      contactName: null,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      advisorId: state.advisorId,
      advisorName: state.advisorName,
      interventionType: state.interventionType,
      requestDescription: state.requestDescription,
      workDescription: state.workDescription,
      recommendations: state.recommendations,
      serviceDate: state.serviceDate,
      startTime: state.startTime,
      endTime: state.endTime,
      durationMinutes: state.durationMinutes,
      notes: state.notes,
      reportTag: state.reportTag,
      currentReportNumber: state.currentReportNumber,
      isLoading: state.isLoading,
      error: state.error,
      globalMargin: state.globalMargin,
      globalTaxRate: state.globalTaxRate,
      pricingMethod: state.pricingMethod,
      isReadOnly: state.isReadOnly,
    );
  }

  void setContact(String? id, String? name) {
    state = state.copyWith(contactId: id, contactName: name);
  }

  void clearContact() {
    state = ServiceReportCreateState(
      report: state.report,
      products: state.products,
      services: state.services,
      conditions: state.conditions,
      clientId: state.clientId,
      clientName: state.clientName,
      clientType: state.clientType,
      contactId: null,
      contactName: null,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      advisorId: state.advisorId,
      advisorName: state.advisorName,
      interventionType: state.interventionType,
      requestDescription: state.requestDescription,
      workDescription: state.workDescription,
      recommendations: state.recommendations,
      serviceDate: state.serviceDate,
      startTime: state.startTime,
      endTime: state.endTime,
      durationMinutes: state.durationMinutes,
      notes: state.notes,
      reportTag: state.reportTag,
      currentReportNumber: state.currentReportNumber,
      isLoading: state.isLoading,
      error: state.error,
      globalMargin: state.globalMargin,
      globalTaxRate: state.globalTaxRate,
      pricingMethod: state.pricingMethod,
      isReadOnly: state.isReadOnly,
    );
  }

  void setDetails({String? notes, String? reportTag}) {
    state = state.copyWith(
      notes: notes ?? state.notes,
      reportTag: reportTag ?? state.reportTag,
    );
  }

  // --- Products & Services Actions ---
  void addProduct(ServiceReportItemProduct product) {
    final updated = List<ServiceReportItemProduct>.from(state.products)
      ..add(product);
    state = state.copyWith(products: updated);
  }

  void updateProduct(int index, ServiceReportItemProduct product) {
    if (index >= 0 && index < state.products.length) {
      final updated = List<ServiceReportItemProduct>.from(state.products);
      updated[index] = product;
      state = state.copyWith(products: updated);
    }
  }

  void removeProduct(int index) {
    if (index >= 0 && index < state.products.length) {
      final updated = List<ServiceReportItemProduct>.from(state.products)
        ..removeAt(index);
      state = state.copyWith(products: updated);
    }
  }

  void addService(ServiceReportItemService service) {
    final updated = List<ServiceReportItemService>.from(state.services)
      ..add(service);
    state = state.copyWith(services: updated);
  }

  void updateService(int index, ServiceReportItemService service) {
    if (index >= 0 && index < state.services.length) {
      final updated = List<ServiceReportItemService>.from(state.services);
      updated[index] = service;
      state = state.copyWith(services: updated);
    }
  }

  void removeService(int index) {
    if (index >= 0 && index < state.services.length) {
      final updated = List<ServiceReportItemService>.from(state.services)
        ..removeAt(index);
      state = state.copyWith(services: updated);
    }
  }

  // --- Conditions Actions ---
  void addCondition(ServiceReportCondition condition) {
    final updated = List<ServiceReportCondition>.from(state.conditions)
      ..add(condition);
    state = state.copyWith(conditions: updated);
  }

  void addConditions(List<CommercialCondition> newConditions) {
    final updated = List<ServiceReportCondition>.from(state.conditions);
    for (final c in newConditions) {
      updated.add(
        ServiceReportCondition(
          id: '',
          reportId: state.report?.id ?? '',
          conditionId: c.id,
          description: c.description,
          orderIndex: updated.length,
        ),
      );
    }
    state = state.copyWith(conditions: updated);
  }

  void updateCondition(int index, String description) {
    if (index >= 0 && index < state.conditions.length) {
      final updated = List<ServiceReportCondition>.from(state.conditions);
      updated[index] = updated[index].copyWith(description: description);
      state = state.copyWith(conditions: updated);
    }
  }

  void removeCondition(int index) {
    if (index >= 0 && index < state.conditions.length) {
      final updated = List<ServiceReportCondition>.from(state.conditions)
        ..removeAt(index);
      state = state.copyWith(conditions: updated);
    }
  }

  void reorderConditions(int oldIndex, int newIndex) {
    var actualNewIndex = newIndex;
    if (actualNewIndex > oldIndex) actualNewIndex -= 1;
    final items = List<ServiceReportCondition>.from(state.conditions);
    final item = items.removeAt(oldIndex);
    items.insert(actualNewIndex, item);

    final reindexed = items.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    state = state.copyWith(conditions: reindexed);
  }

  // --- Save / Finalize ---
  Future<bool> saveAsDraft() async {
    return _saveReport(status: ServiceReportStatus.draft.dbValue);
  }

  Future<bool> createReport({String? status}) async {
    return _saveReport(status: status ?? ServiceReportStatus.finalized.dbValue);
  }

  Future<bool> _saveReport({required String status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final userId = ref.read(userProfileProvider).valueOrNull?.id ?? '';

      final startStr = state.startTime != null
          ? '${state.startTime!.hour.toString().padLeft(2, '0')}:${state.startTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final endStr = state.endTime != null
          ? '${state.endTime!.hour.toString().padLeft(2, '0')}:${state.endTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final reportObj = ServiceReport(
        id: state.report?.id ?? '',
        userId: userId,
        reportNumber: state.currentReportNumber,
        clientId: state.clientId!,
        contactId: state.contactId,
        advisorId: state.advisorId,
        categoryId: state.categoryId,
        status: status,
        interventionType: state.interventionType.dbValue,
        requestDescription: state.requestDescription,
        workDescription: state.workDescription,
        recommendations: state.recommendations,
        serviceDate: state.serviceDate,
        startTime: startStr,
        endTime: endStr,
        durationMinutes: state.durationMinutes,
        subtotal: state.totalSales,
        taxAmount: state.taxAmount,
        total: state.finalTotal,
        notes: state.notes,
        reportTag: state.reportTag,
        createdAt: state.report?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ServiceReport saved;
      if (state.report != null && state.report!.id.isNotEmpty) {
        saved = await repo.updateReport(
          reportObj,
          products: state.products,
          services: state.services,
          conditions: state.conditions,
        );
      } else {
        saved = await repo.createReport(
          reportObj,
          products: state.products,
          services: state.services,
          conditions: state.conditions,
        );
      }

      state = state.copyWith(
        report: saved,
        currentReportNumber: saved.reportNumber,
        isLoading: false,
      );

      ref.invalidate(paginatedReportsListProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final createReportProvider =
    StateNotifierProvider<
      CreateServiceReportNotifier,
      ServiceReportCreateState
    >((ref) {
      return CreateServiceReportNotifier(ref);
    });
