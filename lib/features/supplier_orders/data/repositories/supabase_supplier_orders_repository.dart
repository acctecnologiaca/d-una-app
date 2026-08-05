import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_item.dart';
import '../../domain/models/supplier_order_status.dart';
import '../../domain/models/quote_supplier_oc_status.dart';
import '../../domain/repositories/supplier_orders_repository.dart';
import '../models/supplier_order_dto.dart';
import '../../../../core/utils/country_iso_codes.dart';

class SupabaseSupplierOrdersRepository implements SupplierOrdersRepository {
  final SupabaseClient _supabase;

  SupabaseSupplierOrdersRepository(this._supabase);

  @override
  Future<List<SupplierOrder>> getSupplierOrders() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('supplier_orders')
        .select('''
      *,
      suppliers(name, legal_name),
      supplier_branches(name),
      shipping_methods(label),
      collaborators(full_name),
      supplier_order_items(*, supplier_branch_stock(supplier_branches(name)))
    ''')
        .eq('user_id', currentUserId)
        .eq('is_archived', false)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SupplierOrderDto.fromJson(json))
        .toList();
  }

  @override
  Future<List<SupplierOrder>> getSupplierOrdersPaginated({
    required int offset,
    int limit = 25,
    String? searchQuery,
    String? statusFilter,
    bool includeArchived = false,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    var query = _supabase
        .from('supplier_orders')
        .select('''
      *,
      suppliers(name, legal_name),
      supplier_branches(name),
      shipping_methods(label),
      collaborators(full_name),
      supplier_order_items(*, supplier_branch_stock(supplier_branches(name)))
    ''')
        .eq('user_id', currentUserId);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanSearch = searchQuery.trim();
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(cleanSearch);

      List<String> matchingSupplierIds = [];
      try {
        final supplierResponse = await _supabase
            .from('suppliers')
            .select('id')
            .or('name.ilike.%$cleanSearch%,legal_name.ilike.%$cleanSearch%');
        matchingSupplierIds = (supplierResponse as List)
            .map((e) => e['id'].toString())
            .toList();
      } catch (_) {}

      List<String> matchingQuoteIds = [];
      try {
        final quoteFilter = isUuid
            ? 'quote_number.ilike.%$cleanSearch%,id.eq.$cleanSearch'
            : 'quote_number.ilike.%$cleanSearch%';
        final quoteResponse = await _supabase
            .from('quotes')
            .select('id')
            .or(quoteFilter);
        matchingQuoteIds = (quoteResponse as List)
            .map((e) => e['id'].toString())
            .toList();
      } catch (_) {}

      final List<String> orClauses = [
        'order_number.ilike.%$cleanSearch%',
      ];

      if (isUuid) {
        orClauses.add('quote_id.eq.$cleanSearch');
      }

      if (matchingSupplierIds.isNotEmpty) {
        orClauses.add('supplier_id.in.(${matchingSupplierIds.join(',')})');
      }
      if (matchingQuoteIds.isNotEmpty) {
        orClauses.add('quote_id.in.(${matchingQuoteIds.join(',')})');
      }

      query = query.or(orClauses.join(','));
    }

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => SupplierOrderDto.fromJson(json))
        .toList();
  }

  @override
  Future<void> archiveSupplierOrder(String id, bool isArchived) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');
    await _supabase
        .from('supplier_orders')
        .update({
          'is_archived': isArchived,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', currentUserId);
  }

  @override
  Future<void> updateSupplierOrderStatus(String id, String status) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final payload = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (status == SupplierOrderStatus.sent.dbValue ||
        status == SupplierOrderStatus.resent.dbValue) {
      payload['date'] = DateTime.now().toIso8601String().split('T')[0];
    }

    await _supabase
        .from('supplier_orders')
        .update(payload)
        .eq('id', id)
        .eq('user_id', currentUserId);
  }

  @override
  Future<({SupplierOrder order, List<SupplierOrderItem> items})>
  getSupplierOrderDetails(String id) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // 1. Fetch header
    final headerResponse = await _supabase
        .from('supplier_orders')
        .select('''
      *,
      suppliers(name, legal_name),
      supplier_branches(name),
      shipping_methods(label),
      collaborators(full_name)
    ''')
        .eq('id', id)
        .eq('user_id', currentUserId)
        .single();

    final order = SupplierOrderDto.fromJson(headerResponse);

    // 2. Fetch items
    final itemsResponse = await _supabase
        .from('supplier_order_items')
        .select('''
      *,
      supplier_branch_stock(
        supplier_branches(name)
      )
    ''')
        .eq('supplier_order_id', id);

    var itemsList = (itemsResponse as List).map((json) {
      final branchStock =
          json['supplier_branch_stock'] as Map<String, dynamic>?;
      final branch = branchStock?['supplier_branches'] as Map<String, dynamic>?;
      final branchName = branch?['name'] as String?;

      return SupplierOrderItem(
        id: json['id'],
        supplierOrderId: json['supplier_order_id'],
        productId: json['product_id'],
        name: json['name'],
        brand: json['brand'],
        model: json['model'],
        uom: json['uom'] ?? 'Ud',
        uomIconName: json['uom_icon_name'],
        quantity: (json['quantity'] ?? 0.0).toDouble(),
        unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
        supplierBranchStockId: json['supplier_branch_stock_id'],
        branchName: branchName,
      );
    }).toList();

    // 3. Live check stock & price if status is not finalized/cancelled
    if (order.status != SupplierOrderStatus.finalized &&
        order.status != SupplierOrderStatus.cancelled) {
      final stockIds = itemsList
          .map((e) => e.supplierBranchStockId)
          .whereType<String>()
          .toList();
      if (stockIds.isNotEmpty) {
        try {
          final stockResponse = await _supabase
              .from('supplier_branch_stock')
              .select('''
            id,
            quantity,
            price
          ''')
              .inFilter('id', stockIds);

          final stockMap = <String, ({double price, double quantity})>{};
          for (final row in (stockResponse as List)) {
            final id = row['id'] as String?;
            if (id != null) {
              final price = (row['price'] ?? 0.0).toDouble();
              final quantity = (row['quantity'] ?? 0.0).toDouble();
              stockMap[id] = (price: price, quantity: quantity);
            }
          }

          itemsList = itemsList.map((item) {
            if (item.supplierBranchStockId != null &&
                stockMap.containsKey(item.supplierBranchStockId)) {
              final match = stockMap[item.supplierBranchStockId]!;
              return SupplierOrderItem(
                id: item.id,
                supplierOrderId: item.supplierOrderId,
                productId: item.productId,
                name: item.name,
                brand: item.brand,
                model: item.model,
                uom: item.uom,
                uomIconName: item.uomIconName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                currentSupplierPrice: match.price,
                currentSupplierStock: match.quantity,
                supplierBranchStockId: item.supplierBranchStockId,
                branchName: item.branchName,
              );
            }
            return item;
          }).toList();
        } catch (_) {
          // Silently catch and proceed if live check fails
        }
      }
    }

    return (order: order, items: itemsList);
  }

  @override
  Future<String> createSupplierOrder(
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final headerResponse = await _supabase
        .from('supplier_orders')
        .insert({...SupplierOrderDto.toJson(order), 'user_id': currentUserId})
        .select('id')
        .single();

    final orderId = headerResponse['id'] as String;

    if (items.isNotEmpty) {
      final itemsToInsert = items
          .map(
            (item) => {
              'supplier_order_id': orderId,
              'product_id': item.productId,
              'name': item.name,
              'brand': item.brand,
              'model': item.model,
              'uom': item.uom,
              'uom_icon_name': item.uomIconName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'supplier_branch_stock_id': item.supplierBranchStockId,
            },
          )
          .toList();
      await _supabase.from('supplier_order_items').insert(itemsToInsert);
    }
    return orderId;
  }

  @override
  Future<void> updateSupplierOrder(
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final headerMap = SupplierOrderDto.toJson(order);
    headerMap.remove('id');
    headerMap.remove('user_id');
    headerMap['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _supabase
        .from('supplier_orders')
        .update(headerMap)
        .eq('id', order.id);

    await _supabase
        .from('supplier_order_items')
        .delete()
        .eq('supplier_order_id', order.id);

    if (items.isNotEmpty) {
      final itemsToInsert = items
          .map(
            (item) => {
              'supplier_order_id': order.id,
              'product_id': item.productId,
              'name': item.name,
              'brand': item.brand,
              'model': item.model,
              'uom': item.uom,
              'uom_icon_name': item.uomIconName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'supplier_branch_stock_id': item.supplierBranchStockId,
            },
          )
          .toList();
      await _supabase.from('supplier_order_items').insert(itemsToInsert);
    }
  }

  @override
  Future<void> deleteSupplierOrder(String id) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');
    await _supabase
        .from('supplier_orders')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
  }

  @override
  Future<String?> finalizeSupplierOrder({
    required String orderId,
    required File photoFile,
    required String documentType,
    required String documentNumber,
    required bool createPurchaseRecord,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Fetch order details first to get supplier name and order number
    final orderData = await getSupplierOrderDetails(orderId);
    final order = orderData.order;
    final items = orderData.items;

    // 1. Fetch user profile details for naming
    String folderUser = 'user_$currentUserId';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('first_name, last_name, user_number')
          .eq('id', currentUserId)
          .maybeSingle();

      if (profile != null) {
        final fName = profile['first_name'] as String? ?? '';
        final lName = profile['last_name'] as String? ?? '';
        final uNum = profile['user_number'] as int? ?? 0;

        final rawName = '${fName}_$lName'.trim().replaceAll(' ', '_');
        if (rawName.isNotEmpty) {
          folderUser = '${rawName}_$uNum';
        } else {
          folderUser = 'user_$uNum';
        }
      }
    } catch (_) {
      // Fallback
    }

    final cleanSupplierName = order.supplierName.trim().replaceAll(' ', '_');
    final cleanDocType = documentType == 'invoice' ? 'factura' : 'nota-entrega';
    final cleanDocNumber = documentNumber.trim().replaceAll(' ', '_');
    final extension = photoFile.path.split('.').last.toLowerCase();

    // Construct highly legible structured path: User_Number/Supplier/OC-X_DocType_DocNumber.ext
    final path = _sanitizeStoragePath(
      '$folderUser/$cleanSupplierName/${order.orderNumber}_${cleanDocType}_$cleanDocNumber.$extension',
    );

    await _supabase.storage
        .from('supplier_orders_invoices')
        .upload(
          path,
          photoFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    final publicUrl = _supabase.storage
        .from('supplier_orders_invoices')
        .getPublicUrl(path);

    // 2. Update order header
    await _supabase
        .from('supplier_orders')
        .update({
          'status': SupplierOrderStatus.finalized.dbValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId);

    // 3. Optional purchase record logic
    if (createPurchaseRecord) {
      final List<Map<String, dynamic>> purchaseItemsToInsert = [];

      for (final item in items) {
        String? resolvedProductId = item.productId;

        String? brandId;
        if (item.brand != null && item.brand!.isNotEmpty) {
          final brandResult = await _supabase
              .from('brands')
              .select('id')
              .ilike('name', item.brand!.trim())
              .maybeSingle();

          if (brandResult != null) {
            brandId = brandResult['id'] as String;
          } else {
            final newBrand = await _supabase
                .from('brands')
                .insert({'name': item.brand!.trim(), 'user_id': currentUserId})
                .select('id')
                .single();
            brandId = newBrand['id'] as String;
          }
        }

        String? uomId;
        if (item.uom.isNotEmpty) {
          final uomResult = await _supabase
              .from('uoms')
              .select('id')
              .ilike('symbol', item.uom.trim())
              .maybeSingle();

          if (uomResult != null) {
            uomId = uomResult['id'] as String;
          } else {
            final newUom = await _supabase
                .from('uoms')
                .insert({
                  'name': item.uom.trim(),
                  'symbol': item.uom.trim(),
                  'user_id': currentUserId,
                })
                .select('id')
                .single();
            uomId = newUom['id'] as String;
          }
        }

        bool requiresSerials = false;
        bool hasWarranty = false;

        // Search products comparing model, brand_id and uom_id within user scope or common
        if (item.model != null && item.model!.isNotEmpty) {
          var query = _supabase
              .from('products')
              .select('id, requires_serials, has_warranty');
          query = query.or('user_id.eq.$currentUserId,user_id.is.null');
          query = query.eq('model', item.model!.trim());
          if (brandId != null) {
            query = query.eq('brand_id', brandId);
          } else {
            query = query.isFilter('brand_id', null);
          }
          if (uomId != null) {
            query = query.eq('uom_id', uomId);
          } else {
            query = query.isFilter('uom_id', null);
          }

          final productResults = await query;
          if ((productResults as List).isNotEmpty) {
            final match = productResults.first;
            resolvedProductId = match['id'] as String;
            requiresSerials = match['requires_serials'] == true;
            hasWarranty = match['has_warranty'] == true;
          } else {
            final newProduct = await _supabase
                .from('products')
                .insert({
                  'name': item.name.trim(),
                  'model': item.model!.trim(),
                  'brand_id': brandId,
                  'uom_id': uomId,
                  'user_id': currentUserId,
                })
                .select('id, requires_serials, has_warranty')
                .single();
            resolvedProductId = newProduct['id'] as String;
            requiresSerials = newProduct['requires_serials'] == true;
            hasWarranty = newProduct['has_warranty'] == true;
          }
        } else {
          final nameResult = await _supabase
              .from('products')
              .select('id, requires_serials, has_warranty')
              .or('user_id.eq.$currentUserId,user_id.is.null')
              .eq('name', item.name.trim())
              .maybeSingle();

          if (nameResult != null) {
            resolvedProductId = nameResult['id'] as String;
            requiresSerials = nameResult['requires_serials'] == true;
            hasWarranty = nameResult['has_warranty'] == true;
          } else {
            final newProduct = await _supabase
                .from('products')
                .insert({
                  'name': item.name.trim(),
                  'brand_id': brandId,
                  'uom_id': uomId,
                  'user_id': currentUserId,
                })
                .select('id, requires_serials, has_warranty')
                .single();
            resolvedProductId = newProduct['id'] as String;
            requiresSerials = newProduct['requires_serials'] == true;
            hasWarranty = newProduct['has_warranty'] == true;
          }
        }

        purchaseItemsToInsert.add({
          'product_id': resolvedProductId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'requires_serials': requiresSerials,
          'warranty_time': hasWarranty ? 12 : null,
          'warranty_unit': hasWarranty ? 'months' : null,
        });
      }

      final purchaseHeader = await _supabase
          .from('purchases')
          .insert({
            'user_id': currentUserId,
            'supplier_id': order.supplierId,
            'supplier_order_id': orderId,
            'document_type': documentType,
            'document_number': documentNumber,
            'invoice_photo_url': publicUrl,
            'verification_status': 'pending_review',
            'date': DateTime.now().toIso8601String().split('T')[0],
            'subtotal': order.subtotal,
            'tax': order.tax,
            'total': order.total,
            'has_missing_serials': false,
          })
          .select('id')
          .single();

      final purchaseId = purchaseHeader['id'] as String;

      if (purchaseItemsToInsert.isNotEmpty) {
        final itemsWithPurchaseId = purchaseItemsToInsert
            .map((e) => {...e, 'purchase_id': purchaseId})
            .toList();
        await _supabase.from('purchase_items').insert(itemsWithPurchaseId);
      }

      return purchaseId;
    }

    return null;
  }

  @override
  Future<List<QuoteSupplierOcStatus>> getQuoteSuppliersOcStatus(
      String quoteId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    double taxRate = 0.0;
    try {
      final paramsRes = await _supabase
          .from('financial_parameters')
          .select('tax_rate')
          .eq('user_id', currentUserId)
          .maybeSingle();
      if (paramsRes != null) {
        taxRate = (paramsRes['tax_rate'] as num).toDouble();
      }
    } catch (_) {}

    final quoteItemsResponse = await _supabase
        .from('quote_items_products')
        .select('''
      *,
      supplier_branch_stock(branch_id, product_id, supplier_branches(supplier_id, suppliers(name, legal_name, is_affiliated, is_restricted)))
    ''').eq('quote_id', quoteId);

    final Map<String, ({String name, int count, double subtotal})>
        supplierData = {};

    for (final qi in (quoteItemsResponse as List)) {
      final quantity = (qi['quantity'] ?? 0.0).toDouble();
      final costPrice = (qi['cost_price'] ?? 0.0).toDouble();
      final sbs = qi['supplier_branch_stock'];

      String? supplierId;
      String? supplierName;
      bool isAffiliated = false;
      bool isRestricted = false;

      if (sbs != null) {
        final sb = sbs['supplier_branches'];
        if (sb != null) {
          supplierId = sb['supplier_id'] as String?;
          final supplier = sb['suppliers'];
          if (supplier != null) {
            supplierName = (supplier['name'] as String?) ??
                (supplier['legal_name'] as String?);
            isAffiliated = supplier['is_affiliated'] == true;
            isRestricted = supplier['is_restricted'] == true;
          }
        }
      }

      if (supplierId == null || !isAffiliated || isRestricted) continue;

      final name = supplierName ?? 'Proveedor';
      final current = supplierData[supplierId];
      if (current == null) {
        supplierData[supplierId] = (
          name: name,
          count: 1,
          subtotal: costPrice * quantity,
        );
      } else {
        supplierData[supplierId] = (
          name: current.name,
          count: current.count + 1,
          subtotal: current.subtotal + (costPrice * quantity),
        );
      }
    }

    final existingOrdersRes = await _supabase
        .from('supplier_orders')
        .select('id, order_number, supplier_id, status')
        .eq('quote_id', quoteId)
        .neq('status', 'cancelled');

    final Map<String, ({String id, String orderNumber})> existingOcMap = {};
    for (final o in (existingOrdersRes as List)) {
      final sId = o['supplier_id'] as String?;
      if (sId != null) {
        existingOcMap[sId] = (
          id: o['id'] as String,
          orderNumber: o['order_number'] as String,
        );
      }
    }

    final List<QuoteSupplierOcStatus> result = [];
    for (final entry in supplierData.entries) {
      final sId = entry.key;
      final data = entry.value;
      final total = data.subtotal + (data.subtotal * (taxRate / 100));
      final existingOc = existingOcMap[sId];

      result.add(QuoteSupplierOcStatus(
        supplierId: sId,
        supplierName: data.name,
        itemCount: data.count,
        total: total,
        hasExistingOc: existingOc != null,
        existingOrderNumber: existingOc?.orderNumber,
        existingOrderId: existingOc?.id,
      ));
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> batchGenerateFromQuote(
    String quoteId, {
    List<String>? selectedSupplierIds,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Get user's configured tax rate (VAT/IVA) from financial_parameters
    double taxRate = 0.0;
    try {
      final paramsRes = await _supabase
          .from('financial_parameters')
          .select('tax_rate')
          .eq('user_id', currentUserId)
          .maybeSingle();
      if (paramsRes != null) {
        taxRate = (paramsRes['tax_rate'] as num).toDouble();
      }
    } catch (_) {}

    final quoteItemsResponse = await _supabase
        .from('quote_items_products')
        .select('''
      *,
      supplier_branch_stock(branch_id, product_id, supplier_branches(supplier_id, suppliers(name, legal_name, is_affiliated, is_restricted)))
    ''')
        .eq('quote_id', quoteId);

    final primaryShippingResult = await _supabase
        .from('shipping_methods')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('is_primary', true)
        .maybeSingle();
    final primaryShippingId = primaryShippingResult?['id'] as String?;

    final receiverCollaboratorResult = await _supabase
        .from('collaborators')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('is_user_record', true)
        .maybeSingle();
    final receiverCollaboratorId = receiverCollaboratorResult?['id'] as String?;

    // Build user code: ISO country (2 chars) + hex user number (4 chars, zero-padded)
    final profileRes = await _supabase
        .from('profiles')
        .select('main_country, user_number')
        .eq('id', currentUserId)
        .maybeSingle();

    final countryName = profileRes?['main_country'] as String? ?? '';
    final userNum = (profileRes?['user_number'] as num?)?.toInt() ?? 0;
    final countryCode = CountryIsoCodes.getCode(countryName);
    final hexPart = userNum.toRadixString(16).toUpperCase().padLeft(4, '0');
    final userCode = '$countryCode$hexPart';

    final currentYear = DateTime.now().year % 100;
    final yearPrefix = currentYear.toString().padLeft(2, '0');

    // Get last valid order number for sequencing
    final lastOrderRes = await _supabase
        .from('supplier_orders')
        .select('order_number')
        .eq('user_id', currentUserId)
        .like('order_number', 'OC-%')
        .not('order_number', 'like', 'OC-UNKNOWN%')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final lastNumber = lastOrderRes?['order_number'] as String?;
    int nextSeq = 1;

    if (lastNumber != null) {
      final parts = lastNumber.split('-');
      if (parts.length >= 3) {
        final ocPart = parts.last;
        if (ocPart.length == 5) {
          final yearInLast = ocPart.substring(0, 2);
          final seqInLast = ocPart.substring(2);
          if (yearInLast == yearPrefix) {
            final parsed = int.tryParse(seqInLast);
            if (parsed != null) {
              nextSeq = parsed + 1;
            }
          }
        }
      }
    }

    final Map<String, List<Map<String, dynamic>>> itemsBySupplier = {};
    final List<String> skippedSuppliers = [];

    for (final qi in (quoteItemsResponse as List)) {
      final name = qi['name'] as String;
      final brand = qi['brand'] as String?;
      final model = qi['model'] as String?;
      final uom = qi['uom'] as String? ?? 'Ud';
      final uomIconName = qi['uom_icon_name'] as String?;
      final quantity = (qi['quantity'] ?? 0.0).toDouble();
      final costPrice = (qi['cost_price'] ?? 0.0).toDouble();
      String? productId = qi['product_id'] as String?;

      final sbs = qi['supplier_branch_stock'];
      String? supplierId;
      String? branchId;
      String? supplierName;
      bool isAffiliated = false;
      bool isRestricted = false;

      if (sbs != null) {
        productId ??= sbs['product_id'] as String?;
        branchId = sbs['branch_id'] as String?;
        final sb = sbs['supplier_branches'];
        if (sb != null) {
          supplierId = sb['supplier_id'] as String?;
          final supplier = sb['suppliers'];
          if (supplier != null) {
            supplierName =
                (supplier['name'] as String?) ??
                (supplier['legal_name'] as String?);
            isAffiliated = supplier['is_affiliated'] == true;
            isRestricted = supplier['is_restricted'] == true;
          }
        }
      }

      // Explicitly reject items without an affiliated supplier, or if supplier is restricted/non-affiliated
      if (supplierId == null || !isAffiliated || isRestricted) {
        final labelName = supplierName ?? qi['external_provider_name'] ?? name;
        if (!skippedSuppliers.contains(labelName)) {
          skippedSuppliers.add(labelName);
        }
        continue;
      }

      if (!itemsBySupplier.containsKey(supplierId)) {
        itemsBySupplier[supplierId] = [];
      }

      itemsBySupplier[supplierId]!.add({
        'product_id': productId,
        'name': name,
        'brand': brand,
        'model': model,
        'uom': uom,
        'uom_icon_name': uomIconName,
        'quantity': quantity,
        'unit_price': costPrice,
        'branch_id': branchId,
        'supplier_branch_stock_id': qi['supplier_branch_stock_id'],
      });
    }

    int generatedCount = 0;

    for (final entry in itemsBySupplier.entries) {
      final sId = entry.key;
      if (selectedSupplierIds != null &&
          selectedSupplierIds.isNotEmpty &&
          !selectedSupplierIds.contains(sId)) {
        continue;
      }
      final itemsGroup = entry.value;

      final bId = itemsGroup.first['branch_id'] as String?;

      double subtotal = 0.0;
      for (final item in itemsGroup) {
        subtotal +=
            (item['quantity'] as double) * (item['unit_price'] as double);
      }

      final tax = subtotal * (taxRate / 100);
      final total = subtotal + tax;

      final seqFormatted =
          (nextSeq + generatedCount).toString().padLeft(3, '0');
      final orderNumber = 'OC-$userCode-$yearPrefix$seqFormatted';

      final newOrderResponse = await _supabase
          .from('supplier_orders')
          .insert({
            'user_id': currentUserId,
            'quote_id': quoteId,
            'order_number': orderNumber,
            'supplier_id': sId,
            'supplier_branch_id': bId,
            'shipping_method_id': primaryShippingId,
            'receiver_collaborator_id': receiverCollaboratorId,
            'date': DateTime.now().toIso8601String().split('T')[0],
            'status': SupplierOrderStatus.draft.dbValue,
            'subtotal': subtotal,
            'tax': tax,
            'total': total,
          })
          .select('id')
          .single();

      final newOrderId = newOrderResponse['id'] as String;

      final itemsToInsert = itemsGroup
          .map(
            (item) => {
              'supplier_order_id': newOrderId,
              'product_id': item['product_id'],
              'name': item['name'],
              'brand': item['brand'],
              'model': item['model'],
              'uom': item['uom'],
              'uom_icon_name': item['uom_icon_name'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
              'supplier_branch_stock_id': item['supplier_branch_stock_id'],
            },
          )
          .toList();

      await _supabase.from('supplier_order_items').insert(itemsToInsert);
      generatedCount++;
    }

    if (generatedCount > 0) {
      try {
        final quoteRes = await _supabase
            .from('quotes')
            .select('status')
            .eq('id', quoteId)
            .maybeSingle();
        final currentStatus = quoteRes?['status'] as String?;
        if (currentStatus == 'draft' ||
            currentStatus == 'sent' ||
            currentStatus == 'resent' ||
            currentStatus == 'review') {
          await _supabase
              .from('quotes')
              .update({'status': 'approved'})
              .eq('id', quoteId);
        }
      } catch (_) {}
    }

    return {
      'generatedCount': generatedCount,
      'skippedSuppliers': skippedSuppliers,
    };
  }

  @override
  Future<List<SupplierOrder>> getSupplierOrdersByQuoteId(String quoteId) async {
    final response = await _supabase
        .from('supplier_orders')
        .select('''
      *,
      suppliers(name, legal_name),
      supplier_branches(name),
      shipping_methods(label),
      collaborators!receiver_collaborator_id(full_name),
      supplier_order_items(*, supplier_branch_stock(supplier_branches(name)))
    ''')
        .eq('quote_id', quoteId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => SupplierOrderDto.fromJson(json)).toList();
  }

  @override
  Future<void> cancelDraftOrdersByQuoteId(String quoteId) async {
    await _supabase
        .from('supplier_orders')
        .update({'status': SupplierOrderStatus.cancelled.dbValue})
        .eq('quote_id', quoteId)
        .eq('status', SupplierOrderStatus.draft.dbValue);
  }

  @override
  Future<String?> getLastOrderNumber() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final response = await _supabase
        .from('supplier_orders')
        .select('order_number')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['order_number'] as String?;
  }

  String _sanitizeStoragePath(String input) {
    var result = input
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N');
    return result.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\./]'), '');
  }

  @override
  Future<Map<String, ({double price, double quantity})>> validateSupplierOrderItems({
    required List<String> stockIds,
  }) async {
    if (stockIds.isEmpty) return {};
    final response = await _supabase
        .from('supplier_branch_stock')
        .select('id, price, quantity')
        .inFilter('id', stockIds);

    final map = <String, ({double price, double quantity})>{};
    for (final row in (response as List)) {
      final id = row['id'] as String?;
      if (id != null) {
        map[id] = (
          price: (row['price'] ?? 0.0).toDouble(),
          quantity: (row['quantity'] ?? 0.0).toDouble(),
        );
      }
    }
    return map;
  }

  @override
  Future<String> generateActionToken(String orderId) async {
    final response = await _supabase.rpc(
      'generate_oc_action_token',
      params: {'p_order_id': orderId},
    );
    return response as String;
  }

  @override
  Future<SupplierOrder> mergeSupplierOrders(List<String> orderIds) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');
    if (orderIds.length < 2) {
      throw Exception('Se requieren al menos 2 órdenes para fusionar');
    }

    final ordersResponse = await _supabase
        .from('supplier_orders')
        .select('*, suppliers(name, legal_name), supplier_branches(name)')
        .inFilter('id', orderIds);

    final orders = (ordersResponse as List)
        .map((json) => SupplierOrderDto.fromJson(json))
        .toList();

    if (orders.length != orderIds.length) {
      throw Exception('No se encontraron todas las órdenes seleccionadas');
    }

    final firstSupplierId = orders.first.supplierId;
    final allSameSupplier =
        orders.every((o) => o.supplierId == firstSupplierId);
    if (!allSameSupplier) {
      throw Exception('Todas las órdenes deben pertenecer al mismo proveedor');
    }

    // Primary order is the newest one (most recent createdAt)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final primaryOrder = orders.first;
    final secondaryOrders = orders.sublist(1);

    for (final secondary in secondaryOrders) {
      await _supabase.from('supplier_orders').update({
        'status': SupplierOrderStatus.merged.dbValue,
        'parent_order_id': primaryOrder.id,
        'action_token': null,
        'action_token_expires_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', secondary.id);
    }

    final allOrderIds = [primaryOrder.id, ...secondaryOrders.map((s) => s.id)];
    final allItemsRes = await _supabase
        .from('supplier_order_items')
        .select('*')
        .inFilter('supplier_order_id', allOrderIds);

    final Map<String, Map<String, dynamic>> consolidatedItemsMap = {};
    for (final item in (allItemsRes as List)) {
      final key =
          "${item['product_id'] ?? ''}_${item['supplier_branch_stock_id'] ?? ''}_${item['name']}_${item['brand'] ?? ''}_${item['model'] ?? ''}_${item['unit_price']}";
      if (consolidatedItemsMap.containsKey(key)) {
        final existing = consolidatedItemsMap[key]!;
        final currentQty = (existing['quantity'] as num).toDouble();
        final addQty = (item['quantity'] ?? 0.0 as num).toDouble();
        existing['quantity'] = currentQty + addQty;
      } else {
        consolidatedItemsMap[key] = {
          'supplier_order_id': primaryOrder.id,
          'product_id': item['product_id'],
          'name': item['name'],
          'brand': item['brand'],
          'model': item['model'],
          'uom': item['uom'],
          'uom_icon_name': item['uom_icon_name'],
          'quantity': (item['quantity'] ?? 0.0 as num).toDouble(),
          'unit_price': (item['unit_price'] ?? 0.0 as num).toDouble(),
          'supplier_branch_stock_id': item['supplier_branch_stock_id'],
        };
      }
    }

    await _supabase
        .from('supplier_order_items')
        .delete()
        .eq('supplier_order_id', primaryOrder.id);

    if (consolidatedItemsMap.isNotEmpty) {
      await _supabase
          .from('supplier_order_items')
          .insert(consolidatedItemsMap.values.toList());
    }

    await _recalculatePrimaryOrderTotals(primaryOrder.id);

    final updatedPrimaryRes = await _supabase
        .from('supplier_orders')
        .select('*, suppliers(name, legal_name), supplier_branches(name)')
        .eq('id', primaryOrder.id)
        .single();

    return SupplierOrderDto.fromJson(updatedPrimaryRes);
  }

  @override
  Future<List<SupplierOrder>> getMergedChildOrders(
      String parentOrderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('supplier_orders')
        .select('*, suppliers(name, legal_name), supplier_branches(name)')
        .eq('user_id', currentUserId)
        .eq('status', SupplierOrderStatus.merged.dbValue)
        .eq('parent_order_id', parentOrderId);

    return (response as List)
        .map((json) => SupplierOrderDto.fromJson(json))
        .toList();
  }

  @override
  Future<SupplierOrder?> getParentSupplierOrder(String parentOrderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final response = await _supabase
        .from('supplier_orders')
        .select('*, suppliers(name, legal_name), supplier_branches(name)')
        .eq('user_id', currentUserId)
        .eq('id', parentOrderId)
        .maybeSingle();

    if (response == null) return null;
    return SupplierOrderDto.fromJson(response);
  }

  @override
  Future<void> unmergeSupplierOrder(String childOrderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final childRes = await _supabase
        .from('supplier_orders')
        .select('parent_order_id')
        .eq('id', childOrderId)
        .maybeSingle();

    final parentOrderId = childRes?['parent_order_id'] as String?;

    final childItemsRes = await _supabase
        .from('supplier_order_items')
        .select('*')
        .eq('supplier_order_id', childOrderId);

    await _supabase.from('supplier_orders').update({
      'status': SupplierOrderStatus.draft.dbValue,
      'parent_order_id': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', childOrderId);

    if (parentOrderId != null && (childItemsRes as List).isNotEmpty) {
      final parentItemsRes = await _supabase
          .from('supplier_order_items')
          .select('*')
          .eq('supplier_order_id', parentOrderId);

      for (final childItem in (childItemsRes as List)) {
        final childKey =
            "${childItem['product_id'] ?? ''}_${childItem['supplier_branch_stock_id'] ?? ''}_${childItem['name']}_${childItem['brand'] ?? ''}_${childItem['model'] ?? ''}_${childItem['unit_price']}";
        final childQty = (childItem['quantity'] ?? 0.0 as num).toDouble();

        for (final parentItem in (parentItemsRes as List)) {
          final parentKey =
              "${parentItem['product_id'] ?? ''}_${parentItem['supplier_branch_stock_id'] ?? ''}_${parentItem['name']}_${parentItem['brand'] ?? ''}_${parentItem['model'] ?? ''}_${parentItem['unit_price']}";
          if (childKey == parentKey) {
            final parentQty =
                (parentItem['quantity'] ?? 0.0 as num).toDouble();
            final remainingQty = parentQty - childQty;
            if (remainingQty <= 0) {
              await _supabase
                  .from('supplier_order_items')
                  .delete()
                  .eq('id', parentItem['id']);
            } else {
              await _supabase
                  .from('supplier_order_items')
                  .update({'quantity': remainingQty})
                  .eq('id', parentItem['id']);
            }
            break;
          }
        }
      }

      await _recalculatePrimaryOrderTotals(parentOrderId);
    }
  }

  @override
  Future<void> batchUnmergeSupplierOrders(List<String> childOrderIds) async {
    for (final id in childOrderIds) {
      await unmergeSupplierOrder(id);
    }
  }

  Future<void> _recalculatePrimaryOrderTotals(String parentOrderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final allItemsRes = await _supabase
        .from('supplier_order_items')
        .select('*')
        .eq('supplier_order_id', parentOrderId);

    double newSubtotal = 0.0;
    for (final item in (allItemsRes as List)) {
      final qty = (item['quantity'] ?? 0.0 as num).toDouble();
      final price = (item['unit_price'] ?? 0.0 as num).toDouble();
      newSubtotal += (qty * price);
    }

    double taxRate = 0.0;
    try {
      final paramsRes = await _supabase
          .from('financial_parameters')
          .select('tax_rate')
          .eq('user_id', currentUserId)
          .maybeSingle();
      if (paramsRes != null) {
        taxRate = (paramsRes['tax_rate'] as num).toDouble();
      }
    } catch (_) {}

    final newTaxAmount = newSubtotal * (taxRate / 100);
    final newTotal = newSubtotal + newTaxAmount;

    await _supabase.from('supplier_orders').update({
      'subtotal': newSubtotal,
      'tax': newTaxAmount,
      'total': newTotal,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', parentOrderId);
  }

  @override
  Future<Map<String, dynamic>?> getLinkedPurchase(String supplierOrderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final result = await _supabase
        .from('purchases')
        .select(
          'id, document_type, document_number, total, created_at, invoice_photo_url, verification_status',
        )
        .eq('user_id', currentUserId)
        .eq('supplier_order_id', supplierOrderId)
        .maybeSingle();

    return result;
  }

  @override
  Future<String> createPurchaseFromOrder(String orderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // 1. Guard check if already exists
    final existing = await getLinkedPurchase(orderId);
    if (existing != null) {
      return existing['id'] as String;
    }

    // 2. Fetch order details
    final orderData = await getSupplierOrderDetails(orderId);
    final order = orderData.order;
    final items = orderData.items;

    final List<Map<String, dynamic>> purchaseItemsToInsert = [];

    for (final item in items) {
      String? resolvedProductId = item.productId;

      String? brandId;
      if (item.brand != null && item.brand!.isNotEmpty) {
        final brandResult = await _supabase
            .from('brands')
            .select('id')
            .ilike('name', item.brand!.trim())
            .maybeSingle();

        if (brandResult != null) {
          brandId = brandResult['id'] as String;
        } else {
          final newBrand = await _supabase
              .from('brands')
              .insert({'name': item.brand!.trim(), 'user_id': currentUserId})
              .select('id')
              .single();
          brandId = newBrand['id'] as String;
        }
      }

      String? uomId;
      if (item.uom.isNotEmpty) {
        final uomResult = await _supabase
            .from('uoms')
            .select('id')
            .ilike('symbol', item.uom.trim())
            .maybeSingle();

        if (uomResult != null) {
          uomId = uomResult['id'] as String;
        } else {
          final newUom = await _supabase
              .from('uoms')
              .insert({
                'name': item.uom.trim(),
                'symbol': item.uom.trim(),
                'user_id': currentUserId,
              })
              .select('id')
              .single();
          uomId = newUom['id'] as String;
        }
      }

      bool requiresSerials = false;
      bool hasWarranty = false;

      if (item.model != null && item.model!.isNotEmpty) {
        var query = _supabase
            .from('products')
            .select('id, requires_serials, has_warranty');
        query = query.or('user_id.eq.$currentUserId,user_id.is.null');
        query = query.eq('model', item.model!.trim());
        if (brandId != null) {
          query = query.eq('brand_id', brandId);
        } else {
          query = query.isFilter('brand_id', null);
        }
        if (uomId != null) {
          query = query.eq('uom_id', uomId);
        } else {
          query = query.isFilter('uom_id', null);
        }

        final productResults = await query;
        if ((productResults as List).isNotEmpty) {
          final match = productResults.first;
          resolvedProductId = match['id'] as String;
          requiresSerials = match['requires_serials'] == true;
          hasWarranty = match['has_warranty'] == true;
        } else {
          final newProduct = await _supabase
              .from('products')
              .insert({
                'name': item.name.trim(),
                'model': item.model!.trim(),
                'brand_id': brandId,
                'uom_id': uomId,
                'user_id': currentUserId,
              })
              .select('id, requires_serials, has_warranty')
              .single();
          resolvedProductId = newProduct['id'] as String;
          requiresSerials = newProduct['requires_serials'] == true;
          hasWarranty = newProduct['has_warranty'] == true;
        }
      } else {
        final nameResult = await _supabase
            .from('products')
            .select('id, requires_serials, has_warranty')
            .or('user_id.eq.$currentUserId,user_id.is.null')
            .eq('name', item.name.trim())
            .maybeSingle();

        if (nameResult != null) {
          resolvedProductId = nameResult['id'] as String;
          requiresSerials = nameResult['requires_serials'] == true;
          hasWarranty = nameResult['has_warranty'] == true;
        } else {
          final newProduct = await _supabase
              .from('products')
              .insert({
                'name': item.name.trim(),
                'brand_id': brandId,
                'uom_id': uomId,
                'user_id': currentUserId,
              })
              .select('id, requires_serials, has_warranty')
              .single();
          resolvedProductId = newProduct['id'] as String;
          requiresSerials = newProduct['requires_serials'] == true;
          hasWarranty = newProduct['has_warranty'] == true;
        }
      }

      purchaseItemsToInsert.add({
        'product_id': resolvedProductId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'requires_serials': requiresSerials,
        'warranty_time': hasWarranty ? 12 : null,
        'warranty_unit': hasWarranty ? 'months' : null,
      });
    }

    final purchaseHeader = await _supabase
        .from('purchases')
        .insert({
          'user_id': currentUserId,
          'supplier_id': order.supplierId,
          'supplier_order_id': orderId,
          'document_type': 'invoice',
          'document_number': order.orderNumber,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'subtotal': order.subtotal,
          'tax': order.tax,
          'total': order.total,
          'has_missing_serials': false,
        })
        .select('id')
        .single();

    final purchaseId = purchaseHeader['id'] as String;

    if (purchaseItemsToInsert.isNotEmpty) {
      final itemsWithPurchaseId = purchaseItemsToInsert
          .map((e) => {...e, 'purchase_id': purchaseId})
          .toList();
      await _supabase.from('purchase_items').insert(itemsWithPurchaseId);
    }

    return purchaseId;
  }
}


