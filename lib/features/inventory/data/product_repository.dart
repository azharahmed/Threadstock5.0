import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/authorization_service.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/product.dart';
import '../domain/models/product_image_item.dart';
import '../domain/models/product_variant.dart';
import '../domain/inventory_change_notifier.dart';
import 'product_media_repository.dart';

class ProductRepository {
  final SupabaseClient? _client;
  final ProductMediaRepository _mediaRepository;

  ProductRepository({
    SupabaseClient? client,
    ProductMediaRepository? mediaRepository,
  }) : _client = client,
       _mediaRepository =
           mediaRepository ?? ProductMediaRepository(client: client);

  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory local fallback stores for testing / offline preview
  static final Map<String, Product> _localFallbackProducts = {};
  static final Map<String, List<ProductVariant>> _localFallbackVariants = {};

  Future<String?> resolveCurrentBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    final sb = client;
    if (sb == null) return 'default_business';
    final user = sb.auth.currentUser;
    if (user == null) return 'default_business';

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

      return business?['id'] as String? ?? 'default_business';
    } catch (e) {
      debugPrint('Error resolving business_id: $e');
      return 'default_business';
    }
  }

  /// Saves or updates a draft product. Requires at least Product Name.
  Future<Product> saveDraft({
    String? productId,
    String? businessId,
    required String name,
    String? description,
    String? brandId,
    String? categoryId,
    String? supplierId,
    String? taxCategory,
    List<String> tags = const [],
    int costPriceCents = 0,
    int retailPriceCents = 0,
    String? sku,
    String? barcode,
    bool trackStockLevels = false,
    String? locationId,
    int? lowStockThreshold,
    List<ProductImageItem> images = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a product name to save draft.');
    }
    if (costPriceCents < 0) {
      throw ArgumentError('Unit cost cannot be negative.');
    }
    if (retailPriceCents < 0) {
      throw ArgumentError('Selling price cannot be negative.');
    }
    if (barcode != null && barcode.trim().isNotEmpty) {
      final cleanBarcode = barcode.trim();
      if (cleanBarcode.length > 50 ||
          RegExp(r'[^a-zA-Z0-9-]').hasMatch(cleanBarcode)) {
        throw ArgumentError('Barcode contains invalid characters.');
      }
    }

    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = client;

    if (sb != null && sb.auth.currentUser != null) {
      try {
        final payload = {
          'business_id': resolvedBusinessId,
          'id': ?productId,
          'name': trimmedName,
          'description': description,
          'brand_id': brandId,
          'category_id': categoryId,
          'supplier_id': supplierId,
          'tax_category': taxCategory,
          'status': 'draft',
          'track_stock_levels': trackStockLevels,
          'location_id': locationId,
          'low_stock_threshold': lowStockThreshold,
          'sku': sku?.trim(),
          'barcode': barcode?.trim(),
          'cost_price_cents': costPriceCents,
          'retail_price_cents': retailPriceCents,
        };

        // Try atomic RPC
        try {
          final rpcRes = await sb.rpc(
            'save_or_publish_product',
            params: {'payload': payload},
          );
          if (rpcRes != null && rpcRes is Map && rpcRes['product'] != null) {
            final savedProduct = Product.fromJson(
              Map<String, dynamic>.from(rpcRes['product'] as Map),
            );

            // Upload images
            for (int i = 0; i < images.length; i++) {
              final img = images[i];
              if (img.storagePath == null && img.bytes != null) {
                await _mediaRepository.uploadImage(
                  item: img,
                  businessId: resolvedBusinessId,
                  productId: savedProduct.id,
                  isPrimary:
                      img.isPrimary ||
                      (i == 0 && !images.any((x) => x.isPrimary)),
                );
              }
            }

            return savedProduct;
          }
        } catch (rpcErr) {
          debugPrint(
            'save_or_publish_product RPC not available, falling back to direct table queries: $rpcErr',
          );
        }

        // Direct table upsert fallback
        Map<String, dynamic> productRow;
        if (productId != null) {
          productRow = await sb
              .from('products')
              .update({
                'name': trimmedName,
                'description': description,
                'brand_id': brandId,
                'category_id': categoryId,
                'supplier_id': supplierId,
                'tax_category': taxCategory,
                'tags': tags,
                'status': 'draft',
                'track_stock_levels': trackStockLevels,
                'low_stock_threshold': lowStockThreshold,
              })
              .eq('id', productId)
              .eq('business_id', resolvedBusinessId)
              .select()
              .single();
        } else {
          productRow = await sb
              .from('products')
              .insert({
                'business_id': resolvedBusinessId,
                'name': trimmedName,
                'description': description,
                'brand_id': brandId,
                'category_id': categoryId,
                'supplier_id': supplierId,
                'tax_category': taxCategory,
                'tags': tags,
                'status': 'draft',
                'track_stock_levels': trackStockLevels,
                'low_stock_threshold': lowStockThreshold,
              })
              .select()
              .single();
        }

        final savedProduct = Product.fromJson(productRow);

        // Upload images if any
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          if (img.storagePath == null && img.bytes != null) {
            await _mediaRepository.uploadImage(
              item: img,
              businessId: resolvedBusinessId,
              productId: savedProduct.id,
              isPrimary:
                  img.isPrimary || (i == 0 && !images.any((x) => x.isPrimary)),
            );
          }
        }

        return savedProduct;
      } catch (e) {
        debugPrint('Supabase saveDraft error: $e');
        rethrow;
      }
    }

    // In-memory fallback
    final targetId =
        productId ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final existing = _localFallbackProducts[targetId];

    final updated = Product(
      id: targetId,
      businessId: resolvedBusinessId,
      name: trimmedName,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      supplierId: supplierId,
      taxCategory: taxCategory,
      tags: tags,
      status: 'draft',
      trackStockLevels: trackStockLevels,
      lowStockThreshold: lowStockThreshold,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: null,
    );

    _localFallbackProducts[targetId] = updated;

    if (sku != null && sku.trim().isNotEmpty) {
      final variants = _localFallbackVariants.putIfAbsent(targetId, () => []);
      final variant = ProductVariant(
        id: variants.isNotEmpty
            ? variants.first.id
            : 'var_${DateTime.now().millisecondsSinceEpoch}',
        productId: targetId,
        sku: sku.trim(),
        barcode: barcode?.trim(),
        costPriceCents: costPriceCents,
        retailPriceCents: retailPriceCents,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (variants.isEmpty) {
        variants.add(variant);
      } else {
        variants[0] = variant;
      }
    }

    return updated;
  }

  /// Strictly validates and publishes a product to active catalog.
  Future<Product> publishProduct({
    String? productId,
    String? businessId,
    required String name,
    String? description,
    required String? brandId,
    required String? categoryId,
    required String? supplierId,
    required String? taxCategory,
    List<String> tags = const [],
    required int costPriceCents,
    required int retailPriceCents,
    required String sku,
    String? barcode,
    bool trackStockLevels = false,
    String? locationId,
    String? locationName,
    int openingStock = 0,
    int? lowStockThreshold,
    List<ProductImageItem> images = const [],
  }) async {
    // 1. Strict Contract Validation
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a product name.');
    }
    if (brandId == null || brandId.trim().isEmpty) {
      throw ArgumentError('Select a brand.');
    }
    if (categoryId == null || categoryId.trim().isEmpty) {
      throw ArgumentError('Select a category.');
    }
    if (supplierId == null || supplierId.trim().isEmpty) {
      throw ArgumentError('Select a supplier.');
    }
    if (taxCategory == null || taxCategory.trim().isEmpty) {
      throw ArgumentError('Select a tax category.');
    }
    if (costPriceCents < 0) {
      throw ArgumentError('Unit cost cannot be negative.');
    }
    if (retailPriceCents <= 0) {
      throw ArgumentError('Enter a selling price greater than 0.');
    }
    final trimmedSku = sku.trim();
    if (trimmedSku.isEmpty) {
      throw ArgumentError('Enter a System SKU or click Auto-generate.');
    }
    if (trackStockLevels && openingStock < 0) {
      throw ArgumentError('Opening stock cannot be negative.');
    }

    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = client;

    if (sb != null && sb.auth.currentUser != null) {
      try {
        final payload = {
          'business_id': resolvedBusinessId,
          'id': ?productId,
          'name': trimmedName,
          'description': description,
          'brand_id': brandId,
          'category_id': categoryId,
          'supplier_id': supplierId,
          'tax_category': taxCategory,
          'tags': tags,
          'status': 'active',
          'track_stock_levels': trackStockLevels,
          'low_stock_threshold': lowStockThreshold,
          'sku': trimmedSku,
          'barcode': barcode?.trim(),
          'cost_price_cents': costPriceCents,
          'retail_price_cents': retailPriceCents,
          'location_id': locationId,
          'opening_stock': trackStockLevels ? openingStock : 0,
        };

        // Try atomic RPC
        try {
          final rpcRes = await sb.rpc(
            'save_or_publish_product',
            params: {'payload': payload},
          );
          if (rpcRes != null && rpcRes is Map && rpcRes['product'] != null) {
            final publishedProduct = Product.fromJson(
              Map<String, dynamic>.from(rpcRes['product'] as Map),
            );

            // Upload images
            for (int i = 0; i < images.length; i++) {
              final img = images[i];
              if (img.storagePath == null && img.bytes != null) {
                await _mediaRepository.uploadImage(
                  item: img,
                  businessId: resolvedBusinessId,
                  productId: publishedProduct.id,
                  isPrimary:
                      img.isPrimary ||
                      (i == 0 && !images.any((x) => x.isPrimary)),
                );
              }
            }

            return publishedProduct;
          }
        } catch (rpcErr) {
          debugPrint('save_or_publish_product RPC fallback: $rpcErr');
        }

        // Direct table upsert fallback
        Map<String, dynamic> productRow;
        final nowIso = DateTime.now().toIso8601String();
        if (productId != null) {
          productRow = await sb
              .from('products')
              .update({
                'name': trimmedName,
                'description': description,
                'brand_id': brandId,
                'category_id': categoryId,
                'supplier_id': supplierId,
                'tax_category': taxCategory,
                'tags': tags,
                'status': 'active',
                'track_stock_levels': trackStockLevels,
                'low_stock_threshold': lowStockThreshold,
                'published_at': nowIso,
              })
              .eq('id', productId)
              .eq('business_id', resolvedBusinessId)
              .select()
              .single();
        } else {
          productRow = await sb
              .from('products')
              .insert({
                'business_id': resolvedBusinessId,
                'name': trimmedName,
                'description': description,
                'brand_id': brandId,
                'category_id': categoryId,
                'supplier_id': supplierId,
                'tax_category': taxCategory,
                'tags': tags,
                'status': 'active',
                'track_stock_levels': trackStockLevels,
                'low_stock_threshold': lowStockThreshold,
                'published_at': nowIso,
              })
              .select()
              .single();
        }

        final publishedProduct = Product.fromJson(productRow);

        // Upload images
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          if (img.storagePath == null && img.bytes != null) {
            await _mediaRepository.uploadImage(
              item: img,
              businessId: resolvedBusinessId,
              productId: publishedProduct.id,
              isPrimary:
                  img.isPrimary || (i == 0 && !images.any((x) => x.isPrimary)),
            );
          }
        }

        // Upsert variant
        final existingVariants = await sb
            .from('product_variants')
            .select()
            .eq('product_id', publishedProduct.id);

        String variantId;
        if (existingVariants.isNotEmpty) {
          final first = existingVariants.first;
          variantId = first['id'] as String;
          await sb
              .from('product_variants')
              .update({
                'sku': trimmedSku,
                'barcode': barcode?.trim(),
                'cost_price_cents': costPriceCents,
                'retail_price_cents': retailPriceCents,
                'status': 'active',
              })
              .eq('id', variantId);
        } else {
          final insertedVariant = await sb
              .from('product_variants')
              .insert({
                'product_id': publishedProduct.id,
                'sku': trimmedSku,
                'barcode': barcode?.trim(),
                'cost_price_cents': costPriceCents,
                'retail_price_cents': retailPriceCents,
                'status': 'active',
              })
              .select()
              .single();
          variantId = insertedVariant['id'] as String;
        }

        InventoryChangeNotifier.instance.notifyInventoryChanged();
        return publishedProduct;
      } catch (e) {
        debugPrint('Supabase publishProduct error: $e');
        rethrow;
      }
    }

    // In-memory fallback
    final targetId =
        productId ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final existing = _localFallbackProducts[targetId];

    final published = Product(
      id: targetId,
      businessId: resolvedBusinessId,
      name: trimmedName,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      supplierId: supplierId,
      taxCategory: taxCategory,
      tags: tags,
      status: 'active',
      trackStockLevels: trackStockLevels,
      lowStockThreshold: lowStockThreshold,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: DateTime.now(),
    );

    _localFallbackProducts[targetId] = published;
    final variants = _localFallbackVariants.putIfAbsent(targetId, () => []);
    final variant = ProductVariant(
      id: variants.isNotEmpty
          ? variants.first.id
          : 'var_${DateTime.now().microsecondsSinceEpoch}_$targetId',
      productId: targetId,
      sku: trimmedSku,
      barcode: barcode?.trim(),
      costPriceCents: costPriceCents,
      retailPriceCents: retailPriceCents,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (variants.isEmpty) {
      variants.add(variant);
    } else {
      variants[0] = variant;
    }

    if (locationId != null && trackStockLevels && openingStock > 0) {
      _testFallbackInventory['${targetId}_$locationId'] = openingStock;
      _testFallbackInventory['${variant.id}_$locationId'] = openingStock;
    }
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return published;
  }

  Future<List<Product>> getProducts({String? businessId}) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final rows = await sb
            .from('products')
            .select()
            .eq('business_id', resolvedBusinessId)
            .order('created_at', ascending: false);
        return (rows as List)
            .map((r) => Product.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Supabase getProducts error: $e');
      }
    }
    return _localFallbackProducts.values
        .where((p) => p.businessId == resolvedBusinessId)
        .toList();
  }

  Future<Map<String, dynamic>?> getProductDetails(String productId) async {
    final prod = await getProduct(productId);
    if (prod == null) return null;

    final sb = client;
    List<ProductVariant> variants = [];
    int totalStock = 0;
    List<ProductImageItem> media = [];

    if (sb != null && sb.auth.currentUser != null) {
      try {
        final vRows = await sb
            .from('product_variants')
            .select()
            .eq('product_id', productId);
        variants = (vRows as List)
            .map((r) => ProductVariant.fromJson(r as Map<String, dynamic>))
            .toList();

        final variantIds = variants.map((v) => v.id).toList();
        List<Map<String, dynamic>> locationBalances = [];
        final Map<String, int> variantBalances = {for (final v in variants) v.id: 0};
        if (variantIds.isNotEmpty) {
          try {
            final bRows = await sb
                .from('inventory_balances')
                .select('variant_id, location_id, available_qty, committed_qty, damaged_qty, last_counted_at, locations(name)')
                .inFilter('variant_id', variantIds);
            for (final b in bRows as List) {
              final vid = b['variant_id'] as String?;
              final qty = (b['available_qty'] as num?)?.toInt() ?? 0;
              final committed = (b['committed_qty'] as num?)?.toInt() ?? 0;
              final damaged = (b['damaged_qty'] as num?)?.toInt() ?? 0;
              final lastCounted = b['last_counted_at'] as String?;
              totalStock += qty;
              if (vid != null) {
                variantBalances[vid] = (variantBalances[vid] ?? 0) + qty;
              }
              final locData = b['locations'];
              final locName = (locData is Map) ? locData['name'] as String? : null;
              locationBalances.add({
                'variantId': vid,
                'locationId': b['location_id'] as String?,
                'locationName': locName ?? 'Stock Location',
                'availableQty': qty,
                'committedQty': committed,
                'damagedQty': damaged,
                'lastCountedAt': lastCounted,
              });
            }
          } catch (_) {
            final bRows = await sb
                .from('inventory_balances')
                .select('variant_id, available_qty, committed_qty, damaged_qty, last_counted_at')
                .inFilter('variant_id', variantIds);
            for (final b in bRows as List) {
              final vid = b['variant_id'] as String?;
              final qty = (b['available_qty'] as num?)?.toInt() ?? 0;
              totalStock += qty;
              if (vid != null) {
                variantBalances[vid] = (variantBalances[vid] ?? 0) + qty;
              }
            }
          }
        }

        final mRows = await sb
            .from('product_media')
            .select()
            .eq('product_id', productId)
            .order('is_primary', ascending: false);
        media = (mRows as List).map((r) {
          final item = ProductImageItem.fromStorageJson(r as Map<String, dynamic>);
          final sp = r['storage_path'] as String?;
          if (sp != null && sp.isNotEmpty && (item.remoteUrl == null || item.remoteUrl!.isEmpty)) {
            try {
              final publicUrl = sb.storage.from('product-media').getPublicUrl(sp);
              return item.copyWith(remoteUrl: publicUrl);
            } catch (_) {}
          }
          return item;
        }).toList();

        if (media.isEmpty) {
          media = ProductMediaRepository.instance.getMediaForProduct(productId);
        }

        String? categoryName;
        String? brandName;
        String? supplierName;

        if (prod.categoryId != null) {
          try {
            final cRow = await sb
                .from('categories')
                .select('name')
                .eq('id', prod.categoryId!)
                .maybeSingle();
            categoryName = cRow?['name'] as String?;
          } catch (_) {}
        }
        if (prod.brandId != null) {
          try {
            final bRow = await sb
                .from('brands')
                .select('name')
                .eq('id', prod.brandId!)
                .maybeSingle();
            brandName = bRow?['name'] as String?;
          } catch (_) {}
        }
        if (prod.supplierId != null) {
          try {
            final sRow = await sb
                .from('suppliers')
                .select('name')
                .eq('id', prod.supplierId!)
                .maybeSingle();
            supplierName = sRow?['name'] as String?;
          } catch (_) {}
        }

        return {
          'product': prod,
          'variants': variants,
          'totalStock': totalStock,
          'variantBalances': variantBalances,
          'locationBalances': locationBalances,
          'media': media,
          'categoryName': categoryName,
          'brandName': brandName,
          'supplierName': supplierName,
        };
      } catch (e) {
        debugPrint('Supabase getProductDetails error: $e');
      }
    } else {
      variants = _localFallbackVariants[productId] ?? [];
      final Map<String, int> variantBalances = {for (final v in variants) v.id: 0};
      int sumStock = 0;
      for (final v in variants) {
        int vStock = 0;
        for (final entry in _testFallbackInventory.entries) {
          if (entry.key.startsWith('${v.id}_')) {
            vStock += entry.value;
          }
        }
        variantBalances[v.id] = vStock;
        sumStock += vStock;
      }
      if (sumStock == 0) {
        for (final entry in _testFallbackInventory.entries) {
          if (entry.key.startsWith('${productId}_')) {
            sumStock += entry.value;
          }
        }
      }
      totalStock = sumStock;
      media = ProductMediaRepository.instance.getMediaForProduct(productId);
      return {
        'product': prod,
        'variants': variants,
        'totalStock': totalStock,
        'variantBalances': variantBalances,
        'locationBalances': const <Map<String, dynamic>>[],
        'media': media,
        'categoryName': null,
        'brandName': null,
        'supplierName': null,
      };
    }

    return {
      'product': prod,
      'variants': variants,
      'totalStock': totalStock,
      'variantBalances': const <String, int>{},
      'locationBalances': const <Map<String, dynamic>>[],
      'media': media,
      'categoryName': null,
      'brandName': null,
      'supplierName': null,
    };
  }

  Future<Product?> getProduct(String id) async {
    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final row = await sb
            .from('products')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (row != null) {
          return Product.fromJson(row);
        }
      } catch (e) {
        debugPrint('Supabase getProduct error: $e');
      }
    }
    return _localFallbackProducts[id];
  }

  Future<Product> updateProduct(Product product) async {
    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final row = await sb
            .from('products')
            .update({
              'track_stock_levels': product.trackStockLevels,
              'low_stock_threshold': product.lowStockThreshold,
              'name': product.name,
              'description': product.description,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', product.id)
            .select()
            .single();
        final updated = Product.fromJson(row);
        _localFallbackProducts[product.id] = updated;
        InventoryChangeNotifier.instance.notifyInventoryChanged();
        return updated;
      } catch (e) {
        debugPrint('Supabase updateProduct error: $e');
      }
    }
    _localFallbackProducts[product.id] = product;
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return product;
  }

  Future<List<ProductVariant>> getProductVariants(String productId) async {
    final sb = client;
    if (sb != null) {
      try {
        final rows = await sb
            .from('product_variants')
            .select()
            .eq('product_id', productId)
            .order('created_at', ascending: true);
        return (rows as List<dynamic>)
            .map((r) => ProductVariant.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ProductRepository] getProductVariants error: $e');
      }
    }
    return _localFallbackVariants[productId] ?? [];
  }

  Future<ProductVariant?> findVariantBySkuOrBarcode(String query) async {
    final sb = client;
    if (sb != null) {
      try {
        final row = await sb
            .from('product_variants')
            .select()
            .or('sku.eq.$query,barcode.eq.$query')
            .limit(1)
            .maybeSingle();
        if (row != null) {
          return ProductVariant.fromJson(row);
        }
      } catch (e) {
        debugPrint('[ProductRepository] findVariantBySkuOrBarcode error: $e');
      }
    }
    return null;
  }

  static final Map<String, int> _testFallbackInventory = {};

  static Map<String, int> get localFallbackInventory =>
      Map.unmodifiable(_testFallbackInventory);

  @visibleForTesting
  static void setFallbackInventory(String key, int qty) {
    _testFallbackInventory[key] = qty;
  }

  @visibleForTesting
  static void addFallbackProduct(Product product) {
    _localFallbackProducts[product.id] = product;
  }

  @visibleForTesting
  static void addFallbackVariant(String productId, ProductVariant variant) {
    final list = _localFallbackVariants.putIfAbsent(productId, () => []);
    list.add(variant);
  }

  @visibleForTesting
  static void clearLocalState() {
    _localFallbackProducts.clear();
    _localFallbackVariants.clear();
    _testFallbackInventory.clear();
  }

  static Map<String, Product> get localFallbackProducts =>
      Map.unmodifiable(_localFallbackProducts);

  static Map<String, List<ProductVariant>> get localFallbackVariants =>
      Map.unmodifiable(_localFallbackVariants);

  Future<ProductVariant> createVariant({
    required String productId,
    String? businessId,
    required String sku,
    String? barcode,
    String? color,
    String? size,
    String? material,
    required int costPriceCents,
    required int retailPriceCents,
    String status = 'active',
    String? locationId,
    int initialStock = 0,
  }) async {
    final trimmedSku = sku.trim();
    if (trimmedSku.isEmpty) {
      throw ArgumentError('SKU cannot be empty.');
    }
    if (costPriceCents < 0) {
      throw ArgumentError('Cost price cannot be negative.');
    }
    if (retailPriceCents < 0) {
      throw ArgumentError('Selling price cannot be negative.');
    }

    final product = await getProduct(productId);
    if (product == null) {
      throw StateError('Parent product not found: $productId');
    }

    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? product.businessId;

    if (product.businessId != resolvedBusinessId) {
      throw StateError(
        'Cross-business violation: Cannot add variant to a product belonging to another business.',
      );
    }

    if (!AuthorizationService.instance.can('inventory.manage')) {
      throw StateError('Permission denied: inventory.manage required to create product variants.');
    }

    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      final existingWithSku = await sb
          .from('product_variants')
          .select('id')
          .eq('product_id', productId)
          .eq('sku', trimmedSku)
          .maybeSingle();

      if (existingWithSku != null) {
        throw ArgumentError('SKU "$trimmedSku" already exists for this product.');
      }

      final insertData = {
        'product_id': productId,
        'sku': trimmedSku,
        'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
        'color': color?.trim().isEmpty == true ? null : color?.trim(),
        'size': size?.trim().isEmpty == true ? null : size?.trim(),
        'material': material?.trim().isEmpty == true ? null : material?.trim(),
        'cost_price_cents': costPriceCents,
        'retail_price_cents': retailPriceCents,
        'status': status,
      };

      final row = await sb
          .from('product_variants')
          .insert(insertData)
          .select()
          .single();

      final created = ProductVariant.fromJson(row);

      if (initialStock > 0 && locationId != null && locationId.isNotEmpty) {
        try {
          await sb.rpc('adjust_stock', params: {
            'payload': {
              'business_id': resolvedBusinessId,
              'location_id': locationId,
              'variant_id': created.id,
              'quantity_delta': initialStock,
              'reason': 'Opening Stock',
              'notes': 'Initial variant stock',
            }
          });
        } catch (e) {
          debugPrint('[ProductRepository] Opening stock RPC error: $e');
        }
      }

      return created;
    }

    // In-memory fallback
    final variants = _localFallbackVariants.putIfAbsent(productId, () => []);
    if (variants.any((v) => v.sku.toLowerCase() == trimmedSku.toLowerCase())) {
      throw ArgumentError('SKU "$trimmedSku" already exists for this product.');
    }

    final variant = ProductVariant(
      id: 'var_${DateTime.now().microsecondsSinceEpoch}',
      productId: productId,
      sku: trimmedSku,
      barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      color: color?.trim().isEmpty == true ? null : color?.trim(),
      size: size?.trim().isEmpty == true ? null : size?.trim(),
      material: material?.trim().isEmpty == true ? null : material?.trim(),
      costPriceCents: costPriceCents,
      retailPriceCents: retailPriceCents,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    variants.add(variant);

    if (initialStock > 0 && locationId != null && locationId.isNotEmpty) {
      _testFallbackInventory['${variant.id}_$locationId'] = initialStock;
      _testFallbackInventory['${productId}_$locationId'] =
          (_testFallbackInventory['${productId}_$locationId'] ?? 0) + initialStock;
    }

    return variant;
  }

  Future<Product?> archiveProduct(String productId, {String? businessId}) async {
    if (!AuthorizationService.instance.can('inventory.manage')) {
      throw StateError('Permission denied: inventory.manage required to archive products.');
    }
    final prod = await getProduct(productId);
    if (prod == null) return null;
    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final row = await sb
            .from('products')
            .update({
              'status': 'archived',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', productId)
            .select()
            .single();
        final archived = Product.fromJson(row);
        _localFallbackProducts[productId] = archived;
        return archived;
      } catch (e) {
        debugPrint('Supabase archiveProduct error: $e');
      }
    }
    final archived = prod.copyWith(status: 'archived');
    _localFallbackProducts[productId] = archived;
    return archived;
  }

  Future<Product?> toggleTracking(
    String productId, {
    required bool trackStockLevels,
    String? businessId,
  }) async {
    if (!AuthorizationService.instance.can('inventory.manage')) {
      throw StateError('Permission denied: inventory.manage required to manage product tracking.');
    }
    final prod = await getProduct(productId);
    if (prod == null) return null;
    final sb = client;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final row = await sb
            .from('products')
            .update({
              'track_stock_levels': trackStockLevels,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', productId)
            .select()
            .single();
        final updated = Product.fromJson(row);
        _localFallbackProducts[productId] = updated;
        return updated;
      } catch (e) {
        debugPrint('Supabase toggleTracking error: $e');
      }
    }
    final updated = prod.copyWith(trackStockLevels: trackStockLevels);
    _localFallbackProducts[productId] = updated;
    return updated;
  }

  static List<ProductVariant> getFallbackVariants(String productId) {
    return List.unmodifiable(_localFallbackVariants[productId] ?? []);
  }
}
