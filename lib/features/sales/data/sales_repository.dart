import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/customer.dart';
import '../domain/models/invoice_data.dart';
import '../domain/models/sale.dart';
import '../domain/models/sale_item.dart';
import '../domain/models/sale_payment.dart';
import '../domain/services/customer_input_classifier.dart';
import '../../inventory/domain/inventory_change_notifier.dart';
import '../../settings/data/business_profile_repository.dart';

class CompleteSaleResult {
  final bool success;
  final Sale? sale;
  final String? errorMessage;

  const CompleteSaleResult({
    required this.success,
    this.sale,
    this.errorMessage,
  });
}

class HeldStockWarning {
  final String productName;
  final String? sku;
  final int requested;
  final int available;

  const HeldStockWarning({
    required this.productName,
    this.sku,
    required this.requested,
    required this.available,
  });
}

class ResumeHeldSaleResult {
  final bool success;
  final Sale? sale;
  final List<HeldStockWarning> stockWarnings;
  final Map<String, int> availableQtyByVariant;
  final String? errorMessage;

  const ResumeHeldSaleResult({
    required this.success,
    this.sale,
    this.stockWarnings = const [],
    this.availableQtyByVariant = const {},
    this.errorMessage,
  });
}

class HeldSalesCount extends ChangeNotifier {
  HeldSalesCount._();

  static final HeldSalesCount instance = HeldSalesCount._();

  int count = 0;

  void setCount(int value) {
    if (count == value) return;
    count = value;
    notifyListeners();
  }
}

class CustomerChangeNotifier extends ChangeNotifier {
  CustomerChangeNotifier._();

  static final CustomerChangeNotifier instance = CustomerChangeNotifier._();

  void notifyCustomerChanged() {
    notifyListeners();
  }
}

class SalesRepository {
  SalesRepository({this.client});

  final SupabaseClient? client;

  static final SalesRepository instance = SalesRepository();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Local in-memory store for fallback/testing
  static final List<Sale> _localSales = [];
  static final List<Sale> _localHeldSales = [];
  static final List<Customer> _localCustomers = [];
  static final Map<String, Map<String, dynamic>> _localCommerceProfiles = {};

  @visibleForTesting
  static void clearLocalSalesForTesting() {
    _localSales.clear();
    _localHeldSales.clear();
    _localCustomers.clear();
    _localCommerceProfiles.clear();
    HeldSalesCount.instance.setCount(0);
  }

  @visibleForTesting
  static void setLocalCommerceProfileForTesting(
    String businessId, {
    required bool isGstRegistered,
    String? gstin,
  }) {
    _localCommerceProfiles[businessId] = {
      'gst_registered': isGstRegistered,
      'gstin': gstin,
    };
  }

  @visibleForTesting
  static void clearLocalCommerceProfilesForTesting() {
    _localCommerceProfiles.clear();
  }

  @visibleForTesting
  static void clearLocalCustomersForTesting() {
    _localCustomers.clear();
  }

  @visibleForTesting
  static void addLocalCustomerForTesting(Customer customer) {
    _localCustomers.add(customer);
  }

  @visibleForTesting
  static void addLocalSaleForTesting(Sale sale) {
    _localSales.add(sale);
  }

  @visibleForTesting
  static List<Customer> get localCustomersForTesting => List.unmodifiable(_localCustomers);

  @visibleForTesting
  static List<Sale> get localSalesForTesting => List.unmodifiable(_localSales);

  /// Returns cached/local fallback sales for offline and dashboard aggregation.
  static List<Sale> getLocalSalesForBusiness(String? businessId) {
    if (businessId == null || businessId.isEmpty) return const [];
    return _localSales.where((s) => s.businessId == businessId).toList();
  }

  Future<String?> resolveCurrentBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    final sb = _resolvedClient;
    if (sb == null) return null;
    final user = sb.auth.currentUser;
    if (user == null) return null;

    try {
      final membership = await sb
          .from('memberships')
          .select('business_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      final businessId = membership?['business_id'] as String?;
      if (businessId != null && businessId.isNotEmpty) {
        return businessId;
      }

      final business = await sb
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .limit(1)
          .maybeSingle();

      return business?['id'] as String?;
    } catch (e) {
      debugPrint('[SalesRepository] Error resolving business_id: $e');
      return null;
    }
  }

  /// Executes the atomic Complete Sale transaction via Supabase RPC.
  Future<CompleteSaleResult> completeSale({
    required String businessId,
    String? locationId,
    String? customerId,
    String? customerName,
    String? saleId,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String currencyCode,
    String? discountType,
    double? discountRate,
    String? note,
    String? idempotencyKey,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
  }) async {
    final subtotalMinor = (subtotal * 100).round();
    final discountMinor = (discount * 100).round();
    final taxMinor = (tax * 100).round();
    final totalMinor = (total * 100).round();

    final payload = {
      'business_id': businessId,
      if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
      if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
      if (saleId != null && saleId.isNotEmpty) 'sale_id': saleId,
      'subtotal_minor': subtotalMinor,
      'discount_minor': discountMinor,
      'tax_minor': taxMinor,
      'total_minor': totalMinor,
      'currency_code': currencyCode,
      'discount_type': ?discountType,
      'discount_rate': ?discountRate,
      if (note != null && note.isNotEmpty) 'note': note,
      'idempotency_key': ?idempotencyKey,
      'items': items,
      'payments': payments,
    };

    final sb = _resolvedClient;

    if (sb != null && sb.auth.currentUser != null) {
      try {
        final response = await sb.rpc('complete_sale', params: {'payload': payload});
        final data = response as Map<String, dynamic>;

        if (data['success'] == true) {
          final saleId = data['sale_id'] as String;
          final saleNumber = data['sale_number'] as String;

          final sale = Sale(
            id: saleId,
            businessId: businessId,
            locationId: locationId ?? '',
            saleNumber: saleNumber,
            customerId: customerId,
            status: 'completed',
            subtotalMinor: (data['subtotal_minor'] as num?)?.toInt() ?? subtotalMinor,
            discountMinor: (data['discount_minor'] as num?)?.toInt() ?? discountMinor,
            taxMinor: (data['tax_minor'] as num?)?.toInt() ?? taxMinor,
            totalMinor: (data['total_minor'] as num?)?.toInt() ?? totalMinor,
            currencyCode: data['currency_code'] as String? ?? currencyCode,
            discountType: discountType,
            discountRate: discountRate,
            note: note,
            idempotencyKey: idempotencyKey,
            completedAt: DateTime.now(),
            createdAt: DateTime.now(),
            items: items.map((i) => SaleItem.fromJson(i)).toList(),
            payments: payments.map((p) => SalePayment.fromJson(p)).toList(),
            customerName: customerName,
          );

          _localSales.insert(0, sale);
          unawaited(
            countHeldSales(businessId: businessId).catchError((Object _) => 0),
          );
          InventoryChangeNotifier.instance.notifyInventoryChanged();
          return CompleteSaleResult(success: true, sale: sale);
        } else {
          return CompleteSaleResult(
            success: false,
            errorMessage: data['message'] as String? ?? 'Sale transaction failed',
          );
        }
      } on PostgrestException catch (pe) {
        debugPrint('[SalesRepository] PostgrestException completing sale: ${pe.message}');
        return CompleteSaleResult(
          success: false,
          errorMessage: pe.message,
        );
      } catch (e) {
        debugPrint('[SalesRepository] Exception completing sale: $e');
        return CompleteSaleResult(
          success: false,
          errorMessage: e.toString(),
        );
      }
    }

    // Local / offline fallback (for tests or development without backend)
    Sale? existingHeld;
    if (saleId != null && saleId.isNotEmpty) {
      final index = _localHeldSales.indexWhere(
        (sale) => sale.id == saleId && sale.businessId == businessId,
      );
      if (index < 0) {
        return const CompleteSaleResult(
          success: false,
          errorMessage: 'Held sale not found',
        );
      }
      existingHeld = _localHeldSales.removeAt(index);
    }

    final mockSaleId = existingHeld?.id ?? 'sale_${DateTime.now().millisecondsSinceEpoch}';
    final mockSaleNumber = existingHeld?.saleNumber ?? _nextLocalSaleNumber(businessId);

    final sale = Sale(
      id: mockSaleId,
      businessId: businessId,
      locationId: locationId ?? 'default_loc',
      saleNumber: mockSaleNumber,
      customerId: customerId,
      status: 'completed',
      subtotalMinor: subtotalMinor,
      discountMinor: discountMinor,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      currencyCode: currencyCode,
      discountType: discountType,
      discountRate: discountRate,
      note: note,
      idempotencyKey: idempotencyKey,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      items: items.map((i) => SaleItem.fromJson(i)).toList(),
      payments: payments.map((p) => SalePayment.fromJson(p)).toList(),
      customerName: customerName,
    );

    _localSales.insert(0, sale);
    _publishHeldCount(businessId);
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return CompleteSaleResult(success: true, sale: sale);
  }

  /// Saves the current cart as sales.status = held. Does not change inventory.
  /// Passing [saleId] updates that held sale instead of creating another one.
  Future<CompleteSaleResult> holdSale({
    required String businessId,
    String? locationId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? saleId,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String currencyCode,
    String? discountType,
    double? discountRate,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      return const CompleteSaleResult(
        success: false,
        errorMessage: 'Cart is empty. Add at least one item to hold a sale.',
      );
    }

    final subtotalMinor = (subtotal * 100).round();
    final discountMinor = (discount * 100).round();
    final taxMinor = (tax * 100).round();
    final totalMinor = (total * 100).round();
    final payload = {
      'business_id': businessId,
      if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
      'customer_id': (customerId != null && customerId.isNotEmpty) ? customerId : null,
      if (saleId != null && saleId.isNotEmpty) 'sale_id': saleId,
      'subtotal_minor': subtotalMinor,
      'discount_minor': discountMinor,
      'tax_minor': taxMinor,
      'total_minor': totalMinor,
      'currency_code': currencyCode,
      'discount_type': discountType ?? 'none',
      'discount_rate': discountRate ?? 0,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      'items': items,
    };

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final response = await sb.rpc('hold_sale', params: {'payload': payload});
        final data = Map<String, dynamic>.from(response as Map);
        if (data['success'] == true) {
          final sale = _saleFromHoldResponse(
            data: data,
            businessId: businessId,
            customerName: customerName,
            customerPhone: customerPhone,
            items: items,
          );
          unawaited(
            countHeldSales(businessId: businessId).catchError((Object _) => 0),
          );
          return CompleteSaleResult(success: true, sale: sale);
        }
        return CompleteSaleResult(
          success: false,
          errorMessage: data['message'] as String? ?? 'Could not hold this sale',
        );
      } on PostgrestException catch (pe) {
        debugPrint('[SalesRepository] PostgrestException holding sale: ${pe.message}');
        return CompleteSaleResult(success: false, errorMessage: pe.message);
      } catch (e) {
        debugPrint('[SalesRepository] Exception holding sale: $e');
        return CompleteSaleResult(success: false, errorMessage: e.toString());
      }
    }

    final existingIndex = (saleId == null || saleId.isEmpty)
        ? -1
        : _localHeldSales.indexWhere(
            (sale) => sale.id == saleId && sale.businessId == businessId,
          );
    if (saleId != null && saleId.isNotEmpty && existingIndex < 0) {
      return const CompleteSaleResult(
        success: false,
        errorMessage: 'Held sale not found',
      );
    }

    final existing = existingIndex >= 0 ? _localHeldSales[existingIndex] : null;
    final sale = Sale(
      id: existing?.id ?? 'held_${DateTime.now().microsecondsSinceEpoch}',
      businessId: businessId,
      locationId: locationId ?? existing?.locationId ?? 'default_loc',
      saleNumber: existing?.saleNumber ?? _nextLocalSaleNumber(businessId),
      customerId: (customerId != null && customerId.isNotEmpty) ? customerId : null,
      status: 'held',
      subtotalMinor: subtotalMinor,
      discountMinor: discountMinor,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      currencyCode: currencyCode,
      discountType: discountType,
      discountRate: discountRate,
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      heldAt: DateTime.now(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      items: items.map((item) => SaleItem.fromJson(item)).toList(),
      customerName: customerName,
      customerPhone: customerPhone,
      locationName: existing?.locationName,
      heldByName: existing?.heldByName ?? 'Owner',
    );
    _upsertLocalHeld(sale);
    _publishHeldCount(businessId);
    return CompleteSaleResult(success: true, sale: sale);
  }

  Future<List<Sale>> listHeldSales({String? businessId}) async {
    final resolvedBusinessId = businessId ?? await resolveCurrentBusinessId();
    if (resolvedBusinessId == null) {
      HeldSalesCount.instance.setCount(0);
      return const [];
    }

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final response = await sb.rpc(
          'list_held_sales',
          params: {'p_business_id': resolvedBusinessId},
        );
        final rows = response is List
            ? response
            : (response is String ? <dynamic>[] : <dynamic>[]);
        final sales = rows
            .map((row) => Sale.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
        HeldSalesCount.instance.setCount(sales.length);
        return sales;
      } catch (e) {
        debugPrint('[SalesRepository] Error listing held sales: $e');
        rethrow;
      }
    }

    final sales = _localHeldSales
        .where((sale) => sale.businessId == resolvedBusinessId && sale.status == 'held')
        .toList()
      ..sort((a, b) {
        final aTime = a.heldAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.heldAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    HeldSalesCount.instance.setCount(sales.length);
    return sales;
  }

  Future<int> countHeldSales({String? businessId}) async {
    final sales = await listHeldSales(businessId: businessId);
    return sales.length;
  }

  Future<ResumeHeldSaleResult> resumeHeldSale({
    required String businessId,
    required String saleId,
    Map<String, int>? availableQtyByVariant,
  }) async {
    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final response = await sb.rpc(
          'resume_held_sale',
          params: {
            'payload': {
              'business_id': businessId,
              'sale_id': saleId,
            },
          },
        );
        final data = Map<String, dynamic>.from(response as Map);
        final saleJson = Map<String, dynamic>.from(data['sale'] as Map);
        final sale = Sale.fromJson(saleJson);
        final availableQtyByVariant = <String, int>{};
        for (final rawItem in (saleJson['items'] as List?) ?? const []) {
          final map = Map<String, dynamic>.from(rawItem as Map);
          final variantId = map['variant_id'] as String?;
          final available = (map['available_qty'] as num?)?.toInt();
          if (variantId != null && available != null) {
            availableQtyByVariant[variantId] = available;
          }
        }
        final warnings = ((data['stock_warnings'] as List?) ?? const [])
            .map((row) {
              final map = Map<String, dynamic>.from(row as Map);
              return HeldStockWarning(
                productName: map['product_name'] as String? ?? 'Product',
                sku: map['sku'] as String?,
                requested: (map['requested'] as num?)?.toInt() ?? 0,
                available: (map['available'] as num?)?.toInt() ?? 0,
              );
            })
            .toList();
        return ResumeHeldSaleResult(
          success: true,
          sale: sale,
          stockWarnings: warnings,
          availableQtyByVariant: availableQtyByVariant,
        );
      } on PostgrestException catch (pe) {
        return ResumeHeldSaleResult(success: false, errorMessage: pe.message);
      } catch (e) {
        return ResumeHeldSaleResult(success: false, errorMessage: e.toString());
      }
    }

    final index = _localHeldSales.indexWhere(
      (sale) => sale.id == saleId && sale.businessId == businessId && sale.status == 'held',
    );
    if (index < 0) {
      return const ResumeHeldSaleResult(
        success: false,
        errorMessage: 'Held sale not found',
      );
    }
    final sale = _localHeldSales[index];
    final warnings = <HeldStockWarning>[];
    if (availableQtyByVariant != null) {
      for (final item in sale.items) {
        final key = item.variantId ?? item.productId;
        if (key == null || !availableQtyByVariant.containsKey(key)) continue;
        final available = availableQtyByVariant[key]!;
        if (item.quantity > available) {
          warnings.add(
            HeldStockWarning(
              productName: item.productNameSnapshot,
              sku: item.skuSnapshot,
              requested: item.quantity,
              available: available,
            ),
          );
        }
      }
    }
    return ResumeHeldSaleResult(
      success: true,
      sale: sale,
      stockWarnings: warnings,
      availableQtyByVariant: availableQtyByVariant ?? const {},
    );
  }

  /// Soft-cancels a held sale. Inventory is unchanged because hold never reserved it.
  Future<CompleteSaleResult> discardHeldSale({
    required String businessId,
    required String saleId,
  }) async {
    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final response = await sb.rpc(
          'discard_held_sale',
          params: {
            'payload': {
              'business_id': businessId,
              'sale_id': saleId,
            },
          },
        );
        final data = Map<String, dynamic>.from(response as Map);
        if (data['success'] == true) {
          unawaited(
            countHeldSales(businessId: businessId).catchError((Object _) => 0),
          );
          return const CompleteSaleResult(success: true);
        }
        return CompleteSaleResult(
          success: false,
          errorMessage: data['message'] as String? ?? 'Could not discard this held sale',
        );
      } on PostgrestException catch (pe) {
        return CompleteSaleResult(success: false, errorMessage: pe.message);
      } catch (e) {
        return CompleteSaleResult(success: false, errorMessage: e.toString());
      }
    }

    final index = _localHeldSales.indexWhere(
      (sale) => sale.id == saleId && sale.businessId == businessId && sale.status == 'held',
    );
    if (index < 0) {
      return const CompleteSaleResult(
        success: false,
        errorMessage: 'Held sale not found',
      );
    }
    _localHeldSales.removeAt(index);
    _publishHeldCount(businessId);
    return const CompleteSaleResult(success: true);
  }

  static List<HeldStockWarning> warningsForStock({
    required List<({String productName, int requested, int available})> lines,
  }) {
    return [
      for (final line in lines)
        if (line.requested > line.available)
          HeldStockWarning(
            productName: line.productName,
            requested: line.requested,
            available: line.available,
          ),
    ];
  }

  Sale _saleFromHoldResponse({
    required Map<String, dynamic> data,
    required String businessId,
    required String? customerName,
    required String? customerPhone,
    required List<Map<String, dynamic>> items,
  }) {
    return Sale(
      id: data['sale_id'] as String? ?? '',
      businessId: data['business_id'] as String? ?? businessId,
      locationId: data['location_id'] as String? ?? '',
      saleNumber: data['sale_number'] as String? ?? '',
      customerId: data['customer_id'] as String?,
      status: 'held',
      subtotalMinor: (data['subtotal_minor'] as num?)?.toInt() ?? 0,
      discountMinor: (data['discount_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (data['tax_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (data['total_minor'] as num?)?.toInt() ?? 0,
      currencyCode: data['currency_code'] as String? ?? 'INR',
      discountType: data['discount_type'] as String?,
      discountRate: data['discount_rate'] == null
          ? null
          : double.tryParse(data['discount_rate'].toString()),
      note: data['note'] as String?,
      heldBy: data['held_by'] as String?,
      heldAt: data['held_at'] != null
          ? DateTime.tryParse(data['held_at'].toString())
          : DateTime.now(),
      createdAt: DateTime.now(),
      items: items.map((item) => SaleItem.fromJson(item)).toList(),
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  void _upsertLocalHeld(Sale sale) {
    final index = _localHeldSales.indexWhere((existing) => existing.id == sale.id);
    if (index >= 0) {
      _localHeldSales[index] = sale;
    } else {
      _localHeldSales.insert(0, sale);
    }
  }

  void _publishHeldCount(String businessId) {
    final count = _localHeldSales
        .where((sale) => sale.businessId == businessId && sale.status == 'held')
        .length;
    HeldSalesCount.instance.setCount(count);
  }

  String _nextLocalSaleNumber(String businessId) {
    final year = DateTime.now().year;
    final used = [..._localSales, ..._localHeldSales]
        .where((sale) => sale.businessId == businessId && sale.saleNumber.startsWith('TS-$year-'))
        .length;
    return 'TS-$year-${(used + 1).toString().padLeft(6, '0')}';
  }

  /// Fetches recent sales for the specified business
  Future<List<Sale>> getSales({String? businessId}) async {
    final resolvedBusinessId = businessId ?? await resolveCurrentBusinessId();
    if (resolvedBusinessId == null) return _localSales;

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final rows = await sb
            .from('sales')
            .select('*, sale_items(*), sale_payments(*)')
            .eq('business_id', resolvedBusinessId)
            .order('created_at', ascending: false);

        return (rows as List)
            .map((r) => Sale.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[SalesRepository] Error fetching sales: $e');
      }
    }
    return _localSales
        .where((s) => s.businessId == resolvedBusinessId)
        .toList();
  }

  /// Fetches a single completed sale with all items, payments, customer and location snapshots.
  /// Scoped to [businessId] for strict cross-business security. Returns null if not found or unauthorized.
  Future<Sale?> getSaleWithDetails({
    required String businessId,
    required String saleId,
  }) async {
    if (businessId.isEmpty || saleId.isEmpty) return null;

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final row = await sb
            .from('sales')
            .select('*, sale_items(*), sale_payments(*), customers(*), locations(*)')
            .eq('id', saleId)
            .eq('business_id', businessId)
            .maybeSingle();

        if (row != null) {
          return Sale.fromJson(Map<String, dynamic>.from(row as Map));
        }
      } catch (e) {
        debugPrint('[SalesRepository] Error fetching sale with details: $e');
      }
    }

    try {
      return _localSales.firstWhere(
        (s) => s.id == saleId && s.businessId == businessId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Loads full authoritative invoice data for a completed persisted sale.
  /// Enforces cross-business isolation: returns null if the sale belongs to another business.
  /// Tax values are taken strictly from snapshots (never recalculated).
  Future<InvoiceData?> loadInvoiceData({
    required String businessId,
    required String saleId,
    Sale? preloadedSale,
  }) async {
    if (businessId.isEmpty) return null;

    Sale? sale = preloadedSale;
    if (sale != null) {
      if (sale.businessId != businessId) {
        // Strict cross-business check
        debugPrint('[SalesRepository] Denied cross-business invoice access for sale $saleId');
        return null;
      }
    } else {
      sale = await getSaleWithDetails(businessId: businessId, saleId: saleId);
    }

    if (sale == null) return null;

    // 1. Business profile & commerce profile (for GSTIN)
    final bizRepo = BusinessProfileRepository(client: _resolvedClient);
    final profile = await bizRepo.loadProfile(businessId: businessId);

    bool isGstRegistered = false;
    String? gstin;
    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final commerceRow = await sb
            .from('business_commerce_profiles')
            .select('gst_registered, gstin')
            .eq('business_id', businessId)
            .maybeSingle();
        if (commerceRow != null) {
          isGstRegistered = commerceRow['gst_registered'] == true;
          gstin = commerceRow['gstin'] as String?;
        }
      } catch (e) {
        debugPrint('[SalesRepository] Error loading commerce profile: $e');
      }
    } else {
      final localCommerce = _localCommerceProfiles[businessId];
      if (localCommerce != null) {
        isGstRegistered = localCommerce['gst_registered'] == true;
        gstin = localCommerce['gstin'] as String?;
      }
    }

    final bizInfo = InvoiceBusinessInfo(
      id: businessId,
      displayName: (profile['display_name'] as String?)?.isNotEmpty == true
          ? profile['display_name'] as String
          : (CurrentBusinessService.instance.currentBusiness?.legalName ?? 'ThreadStock'),
      legalName: (profile['legal_entity_name'] as String?) ?? '',
      logoUrl: profile['logo_url'] as String?,
      streetAddress: profile['street_address'] as String?,
      city: profile['city'] as String?,
      postalCode: profile['postal_code'] as String?,
      phone: profile['phone'] as String?,
      email: profile['email'] as String?,
      website: profile['website'] as String?,
      isGstRegistered: isGstRegistered,
      gstin: (isGstRegistered && gstin != null && gstin.trim().isNotEmpty) ? gstin.trim() : null,
    );

    // 2. Location
    String locName = sale.locationName ?? '';
    String? locStreet;
    String? locCity;
    String? locPostal;

    if (locName.isEmpty && sale.locationId.isNotEmpty) {
      if (sb != null && sb.auth.currentUser != null) {
        try {
          final locRow = await sb
              .from('locations')
              .select('name, street_address, city, postal_code')
              .eq('id', sale.locationId)
              .maybeSingle();
          if (locRow != null) {
            locName = locRow['name'] as String? ?? '';
            locStreet = locRow['street_address'] as String?;
            locCity = locRow['city'] as String?;
            locPostal = locRow['postal_code'] as String?;
          }
        } catch (_) {}
      }
    }
    if (locName.isEmpty) {
      locName = 'Store Location';
    }

    final locInfo = InvoiceLocationInfo(
      id: sale.locationId,
      name: locName,
      streetAddress: locStreet,
      city: locCity,
      postalCode: locPostal,
    );

    // 3. Customer
    InvoiceCustomerInfo custInfo;
    if (sale.customerId == null || sale.customerId!.isEmpty) {
      custInfo = InvoiceCustomerInfo.walkIn();
    } else {
      String custName = sale.customerName ?? '';
      String? custPhone = sale.customerPhone;
      String? custEmail;

      if (custName.isEmpty) {
        final cust = await getCustomers(businessId: businessId);
        final found = cust.cast<Customer?>().firstWhere(
              (c) => c?.id == sale!.customerId,
              orElse: () => null,
            );
        if (found != null) {
          custName = found.name;
          custPhone ??= found.phone;
          custEmail = found.email;
        }
      }

      custInfo = InvoiceCustomerInfo(
        id: sale.customerId,
        name: custName.isNotEmpty ? custName : 'Customer',
        phone: custPhone,
        email: custEmail,
        isWalkIn: false,
      );
    }

    return InvoiceData(
      sale: sale,
      items: sale.items,
      payments: sale.payments,
      business: bizInfo,
      location: locInfo,
      customer: custInfo,
      cashierName: sale.createdBy ?? 'Cashier',
    );
  }

  /// Fetches customers for the specified business
  Future<List<Customer>> getCustomers({String? businessId}) async {
    final resolvedBusinessId = businessId ?? await resolveCurrentBusinessId();
    if (resolvedBusinessId == null) return const [];

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final rows = await sb
            .from('customers')
            .select()
            .eq('business_id', resolvedBusinessId)
            .order('updated_at', ascending: false);

        return (rows as List)
            .map((r) => Customer.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[SalesRepository] Error fetching customers: $e');
      }
    }
    final list = _localCustomers
        .where((c) => c.businessId == resolvedBusinessId)
        .toList()
      ..sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return list;
  }

  /// Fetches recent customers for the specified business, ordered by updated_at descending.
  /// Scoped strictly to currentBusiness.id.
  Future<List<Customer>> getRecentCustomers({
    required String businessId,
    int limit = 10,
  }) async {
    if (businessId.isEmpty) return const [];

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final rows = await sb
            .from('customers')
            .select()
            .eq('business_id', businessId)
            .order('updated_at', ascending: false)
            .limit(limit);

        return (rows as List)
            .map((r) => Customer.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[SalesRepository] Error fetching recent customers: $e');
      }
    }

    final list = _localCustomers
        .where((c) => c.businessId == businessId)
        .toList()
      ..sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return list.take(limit).toList();
  }

  /// Searches customers for a business across name, email, and phone (real-time, from 1st char/digit).
  /// Strictly business-scoped: never exposes customers from another business.
  /// Normalizes phone queries and stored values for robust matching.
  Future<List<Customer>> searchCustomers({
    required String businessId,
    required String query,
    String defaultIsd = '+91',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || businessId.isEmpty) return const [];

    final cleanDigits = CustomerInputClassifier.cleanDigits(trimmed);
    final normalizedE164 = CustomerInputClassifier.normalizeToE164(trimmed, defaultIsd: defaultIsd);

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final byName = await sb
            .from('customers')
            .select()
            .eq('business_id', businessId)
            .ilike('name', '%$trimmed%')
            .order('updated_at', ascending: false)
            .limit(20);

        final byEmail = await sb
            .from('customers')
            .select()
            .eq('business_id', businessId)
            .ilike('email', '%$trimmed%')
            .order('updated_at', ascending: false)
            .limit(20);

        final phoneQueries = <String>{trimmed};
        if (cleanDigits.isNotEmpty) phoneQueries.add(cleanDigits);
        if (normalizedE164.isNotEmpty) phoneQueries.add(normalizedE164);

        final byPhoneRows = <dynamic>[];
        for (final pQuery in phoneQueries) {
          final res = await sb
              .from('customers')
              .select()
              .eq('business_id', businessId)
              .ilike('phone', '%$pQuery%')
              .order('updated_at', ascending: false)
              .limit(20);
          byPhoneRows.addAll(res as List);
        }

        final seen = <String>{};
        final results = <Customer>[];
        for (final row in [
          ...(byName as List),
          ...(byEmail as List),
          ...byPhoneRows,
        ]) {
          final c = Customer.fromJson(row as Map<String, dynamic>);
          if (c.businessId == businessId && seen.add(c.id)) {
            results.add(c);
          }
        }
        return results;
      } catch (e) {
        debugPrint('[SalesRepository] Error searching customers: $e');
      }
    }

    // Local / fallback store (for offline or widget tests)
    final qLower = trimmed.toLowerCase();
    final results = <Customer>[];
    for (final c in _localCustomers) {
      if (c.businessId != businessId) continue; // Cross-business isolation

      final nameMatch = c.name.toLowerCase().contains(qLower);
      final emailMatch = c.email != null && c.email!.toLowerCase().contains(qLower);

      bool phoneMatch = false;
      if (c.phone != null && c.phone!.isNotEmpty) {
        final cDigits = CustomerInputClassifier.cleanDigits(c.phone!);
        final cE164 = CustomerInputClassifier.normalizeToE164(c.phone!, defaultIsd: defaultIsd);

        phoneMatch = c.phone!.contains(trimmed) ||
            (cleanDigits.isNotEmpty && cDigits.contains(cleanDigits)) ||
            (normalizedE164.isNotEmpty && cE164 == normalizedE164) ||
            (normalizedE164.isNotEmpty && c.phone!.contains(normalizedE164));
      }

      if (nameMatch || emailMatch || phoneMatch) {
        results.add(c);
      }
    }

    results.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return results;
  }

  /// Checks whether an existing customer in this business matches the given normalized phone or email.
  /// Strictly business-scoped. Returns the existing Customer if duplicate found, or null.
  Future<Customer?> findDuplicateCustomer({
    required String businessId,
    String? phoneE164,
    String? email,
  }) async {
    if (businessId.isEmpty) return null;
    final cleanPhone = phoneE164?.trim();
    final cleanEmail = email?.trim().toLowerCase();

    if ((cleanPhone == null || cleanPhone.isEmpty) &&
        (cleanEmail == null || cleanEmail.isEmpty)) {
      return null;
    }

    final cleanDigits = cleanPhone != null ? CustomerInputClassifier.cleanDigits(cleanPhone) : '';

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        if (cleanPhone != null && cleanPhone.isNotEmpty) {
          final rows = await sb
              .from('customers')
              .select()
              .eq('business_id', businessId)
              .or('phone.eq.$cleanPhone,phone.ilike.%$cleanDigits%')
              .limit(1);
          if (rows.isNotEmpty) {
            return Customer.fromJson(rows.first);
          }
        }

        if (cleanEmail != null && cleanEmail.isNotEmpty) {
          final rows = await sb
              .from('customers')
              .select()
              .eq('business_id', businessId)
              .ilike('email', cleanEmail)
              .limit(1);
          if (rows.isNotEmpty) {
            return Customer.fromJson(rows.first);
          }
        }
      } catch (e) {
        debugPrint('[SalesRepository] Error checking duplicate customer: $e');
      }
    }

    // Local / fallback store check (with strict cross-business isolation)
    for (final c in _localCustomers) {
      if (c.businessId != businessId) continue; // Cross-business isolation

      if (cleanPhone != null && cleanPhone.isNotEmpty && c.phone != null) {
        final cDigits = CustomerInputClassifier.cleanDigits(c.phone!);
        if (c.phone == cleanPhone ||
            (cleanDigits.isNotEmpty &&
                cDigits.isNotEmpty &&
                (cDigits == cleanDigits ||
                    cDigits.endsWith(cleanDigits) ||
                    cleanDigits.endsWith(cDigits)))) {
          return c;
        }
      }

      if (cleanEmail != null && cleanEmail.isNotEmpty && c.email != null) {
        if (c.email!.trim().toLowerCase() == cleanEmail) {
          return c;
        }
      }
    }

    return null;
  }

  /// Checks whether a phone number (E.164) already exists for this business.
  Future<bool> phoneExistsForBusiness({
    required String businessId,
    required String phoneE164,
  }) async {
    final dup = await findDuplicateCustomer(
      businessId: businessId,
      phoneE164: phoneE164,
    );
    return dup != null;
  }

  /// Checks whether an email already exists for this business.
  Future<bool> emailExistsForBusiness({
    required String businessId,
    required String email,
  }) async {
    final dup = await findDuplicateCustomer(
      businessId: businessId,
      email: email,
    );
    return dup != null;
  }

  /// Creates a new customer for the business. Returns the created Customer or null on failure.
  /// Scoped to public.customers in Supabase with local fallback.
  Future<Customer?> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
  }) async {
    if (businessId.isEmpty || name.trim().isEmpty) return null;

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final payload = <String, dynamic>{
          'business_id': businessId,
          'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
        };
        final rows = await sb.from('customers').insert(payload).select()
            as List<dynamic>;
        if (rows.isNotEmpty) {
          final created = Customer.fromJson(rows.first as Map<String, dynamic>);
          _localCustomers.removeWhere((c) => c.id == created.id);
          _localCustomers.insert(0, created);
          CustomerChangeNotifier.instance.notifyCustomerChanged();
          return created;
        }
      } catch (e) {
        debugPrint('[SalesRepository] Error creating customer: $e');
        return null;
      }
    }

    // In-memory customer creation for offline or testing
    final created = Customer(
      id: 'cust-local-${DateTime.now().millisecondsSinceEpoch}-${_localCustomers.length + 1}',
      businessId: businessId,
      name: name.trim(),
      phone: phone?.trim(),
      email: email?.trim().toLowerCase(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _localCustomers.removeWhere((c) => c.id == created.id);
    _localCustomers.insert(0, created);
    CustomerChangeNotifier.instance.notifyCustomerChanged();
    return created;
  }
}
