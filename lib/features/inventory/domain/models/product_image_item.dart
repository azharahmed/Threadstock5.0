import 'dart:typed_data';

/// Represents a product image item in the ThreadStock catalog.
class ProductImageItem {
  final String id;
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;
  final String? storagePath;
  final String? remoteUrl;
  final bool isPrimary;
  final DateTime createdAt;

  const ProductImageItem({
    required this.id,
    required this.name,
    required this.size,
    this.bytes,
    this.path,
    this.storagePath,
    this.remoteUrl,
    this.isPrimary = false,
    required this.createdAt,
  });

  ProductImageItem copyWith({
    String? id,
    String? name,
    int? size,
    Uint8List? bytes,
    String? path,
    String? storagePath,
    String? remoteUrl,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return ProductImageItem(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      bytes: bytes ?? this.bytes,
      path: path ?? this.path,
      storagePath: storagePath ?? this.storagePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'storage_path': storagePath,
      'remote_url': remoteUrl,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductImageItem.fromStorageJson(Map<String, dynamic> json) {
    return ProductImageItem(
      id: json['id'] as String? ?? '',
      name: json['file_name'] as String? ?? json['name'] as String? ?? 'Image',
      size:
          (json['file_size'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          0,
      storagePath: json['storage_path'] as String?,
      remoteUrl: json['url'] as String? ?? json['remote_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ProductImageItem.fromJson(Map<String, dynamic> json) =>
      ProductImageItem.fromStorageJson(json);
}
