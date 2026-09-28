/// In-memory draft for a single inventory file import session.
///
/// Selection of a start method is not inventory. This draft is created only
/// after the user picks a real CSV/XLSX file.
class InventoryImportDraft {
  const InventoryImportDraft({
    required this.fileName,
    required this.fileExtension,
    required this.headers,
    required this.rows,
    required this.pickedAt,
    this.fileSizeBytes,
  });

  final String fileName;
  final String fileExtension;
  final List<String> headers;
  final List<List<String>> rows;
  final DateTime pickedAt;
  final int? fileSizeBytes;

  int get totalRows => rows.length;

  String get displayName => fileName;
}

/// Canonical ThreadStock import target fields.
enum InventoryImportTargetField {
  skip,
  productName,
  sku,
  barcode,
  color,
  size,
  fabric,
  category,
  cost,
  retailPrice,
  quantity,
  location,
  variant,
  supplier,
  notes,
}

extension InventoryImportTargetFieldLabel on InventoryImportTargetField {
  String get label {
    switch (this) {
      case InventoryImportTargetField.skip:
        return 'Skip';
      case InventoryImportTargetField.productName:
        return 'Product Name';
      case InventoryImportTargetField.sku:
        return 'SKU';
      case InventoryImportTargetField.barcode:
        return 'Barcode';
      case InventoryImportTargetField.color:
        return 'Color';
      case InventoryImportTargetField.size:
        return 'Size';
      case InventoryImportTargetField.fabric:
        return 'Fabric';
      case InventoryImportTargetField.category:
        return 'Category';
      case InventoryImportTargetField.cost:
        return 'Cost';
      case InventoryImportTargetField.retailPrice:
        return 'Retail Price';
      case InventoryImportTargetField.quantity:
        return 'Quantity';
      case InventoryImportTargetField.location:
        return 'Location';
      case InventoryImportTargetField.variant:
        return 'Variant';
      case InventoryImportTargetField.supplier:
        return 'Supplier';
      case InventoryImportTargetField.notes:
        return 'Notes';
    }
  }
}

/// Deterministic header → field suggestion. Does not invent values.
class InventoryImportColumnMapper {
  const InventoryImportColumnMapper._();

  static InventoryImportTargetField suggest(String header) {
    final normalized = header.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );
    if (normalized.isEmpty) {
      return InventoryImportTargetField.skip;
    }

    bool hasAny(List<String> tokens) => tokens.any(normalized.contains);

    if (hasAny(['sku', 'variant sku', 'item code', 'style code'])) {
      return InventoryImportTargetField.sku;
    }
    if (hasAny(['barcode', 'upc', 'ean', 'gtin'])) {
      return InventoryImportTargetField.barcode;
    }
    if (hasAny(['product name', 'title', 'item name', 'style name', 'name'])) {
      return InventoryImportTargetField.productName;
    }
    if (hasAny(['color', 'colour'])) {
      return InventoryImportTargetField.color;
    }
    if (hasAny(['size', 'fit'])) {
      return InventoryImportTargetField.size;
    }
    if (hasAny(['fabric', 'material', 'composition'])) {
      return InventoryImportTargetField.fabric;
    }
    if (hasAny(['category', 'department', 'collection'])) {
      return InventoryImportTargetField.category;
    }
    if (hasAny(['cost', 'unit cost', 'wholesale', 'cogs'])) {
      return InventoryImportTargetField.cost;
    }
    if (hasAny(['retail', 'selling price', 'price', 'mrp'])) {
      return InventoryImportTargetField.retailPrice;
    }
    if (hasAny([
      'quantity',
      'qty',
      'stock',
      'on hand',
      'opening stock',
      'available',
    ])) {
      return InventoryImportTargetField.quantity;
    }
    if (hasAny(['location', 'warehouse', 'store', 'bin'])) {
      return InventoryImportTargetField.location;
    }
    if (hasAny(['variant', 'option'])) {
      return InventoryImportTargetField.variant;
    }
    if (hasAny(['supplier', 'vendor'])) {
      return InventoryImportTargetField.supplier;
    }
    if (hasAny(['note', 'notes', 'remark'])) {
      return InventoryImportTargetField.notes;
    }
    return InventoryImportTargetField.skip;
  }
}
