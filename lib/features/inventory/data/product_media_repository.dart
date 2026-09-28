import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/product_image_item.dart';

class ProductMediaRepository {
  final SupabaseClient? client;

  ProductMediaRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static final ProductMediaRepository instance = ProductMediaRepository();

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg', 'webp'];

  /// In-memory fallback for testing / offline preview
  static final Map<String, List<ProductImageItem>> _fallbackMediaByProduct = {};

  List<ProductImageItem> getMediaForProduct(String productId) {
    return _fallbackMediaByProduct[productId] ?? [];
  }

  /// Picks one or more image files using the native file picker
  Future<List<ProductImageItem>> pickImages({bool allowMultiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final items = <ProductImageItem>[];
    for (final file in result.files) {
      if (file.size > maxFileSizeBytes) {
        throw ArgumentError(
          'Image "${file.name}" exceeds the 10MB limit (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB).',
        );
      }

      final ext = file.extension?.toLowerCase() ?? '';
      if (!allowedExtensions.contains(ext)) {
        throw ArgumentError(
          'File "${file.name}" is not a supported format. Please upload PNG, JPG, or WEBP.',
        );
      }

      items.add(
        ProductImageItem(
          id: 'img_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
          name: file.name,
          size: file.size,
          bytes: file.bytes,
          path: file.path,
          createdAt: DateTime.now(),
        ),
      );
    }

    return items;
  }

  /// Uploads an image to Supabase Storage bucket 'product-media'
  Future<ProductImageItem> uploadImage({
    required ProductImageItem item,
    required String businessId,
    required String productId,
    bool isPrimary = false,
  }) async {
    final sb = _resolvedClient;
    final cleanFileName = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '$businessId/$productId/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

    if (sb != null && sb.auth.currentUser != null && item.bytes != null) {
      try {
        final mimeType = _getMimeType(item.name);
        await sb.storage
            .from('product-media')
            .uploadBinary(
              storagePath,
              item.bytes!,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );

        final publicUrl = sb.storage
            .from('product-media')
            .getPublicUrl(storagePath);

        if (isPrimary) {
          try {
            await sb
                .from('product_media')
                .update({'is_primary': false})
                .eq('product_id', productId);
          } catch (_) {}
        }

        // Record in product_media table
        await sb.from('product_media').insert({
          'business_id': businessId,
          'product_id': productId,
          'storage_path': storagePath,
          'media_type': 'image',
          'is_primary': isPrimary,
          'alt_text': item.name,
        });

        return item.copyWith(
          storagePath: storagePath,
          remoteUrl: publicUrl,
          isPrimary: isPrimary,
        );
      } catch (e) {
        debugPrint('Supabase storage upload error: $e');
        // If storage bucket is not configured yet, fallback gracefully
      }
    }

    // Local fallback
    if (isPrimary) {
      final existing = _fallbackMediaByProduct[productId];
      if (existing != null) {
        for (int i = 0; i < existing.length; i++) {
          existing[i] = existing[i].copyWith(isPrimary: false);
        }
      }
    }

    final uploaded = item.copyWith(
      storagePath: storagePath,
      isPrimary: isPrimary,
    );
    final list = _fallbackMediaByProduct.putIfAbsent(productId, () => []);
    list.add(uploaded);
    return uploaded;
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @visibleForTesting
  static void clearLocalState() {
    _fallbackMediaByProduct.clear();
  }
}
