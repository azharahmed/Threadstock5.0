// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../../data/brand_repository.dart';
import '../../data/category_repository.dart';
import '../../data/inventory_repository.dart';
import '../../data/location_repository.dart';
import '../../data/product_media_repository.dart';
import '../../data/product_repository.dart';
import '../../data/supplier_repository.dart';
import '../../domain/models/inventory_import_draft.dart';
import '../../domain/models/product_inventory_summary.dart';
import '../providers/brand_provider.dart';
import '../widgets/active_stock_count_view.dart';
import '../widgets/barcode_labels_view.dart';
import '../widgets/create_new_product_view.dart';
import '../widgets/delete_product_dialog.dart';
import '../widgets/inventory_analytics_view.dart';
import '../widgets/inventory_products_view.dart';
import '../widgets/location_details_view.dart';
import '../widgets/locations_view.dart';
import '../widgets/map_validate_view.dart';
import '../widgets/product_details_view.dart';
import '../widgets/review_import_view.dart';
import '../widgets/stock_adjustment_view.dart';
import '../widgets/stock_ageing_report_view.dart';
import '../widgets/stock_count_reconciliation_view.dart';
import '../widgets/damaged_stock_view.dart';
import '../widgets/stock_history_view.dart';
import '../widgets/upload_file_view.dart';
import '../widgets/validate_rows_view.dart';
import '../widgets/variant_matrix_configurator_view.dart';

enum InventoryPageMode {
  analytics,
  stockList,
  ageingReport,
  uploadFile,
  mapValidate,
  validateRows,
  reviewImport,
  stockAdjustment,
  locations,
  locationDetails,
  labels,
  activeStockCount,
  reconciliation,
  stockHistory,
  damagedStock,
  createProduct,
  variantMatrix,
  productDetails,
}

class StockProductItem {
  final String id;
  final String name;
  final String sku;
  final String price;
  final int onHand;
  final String status;
  final StockStatusType statusType;

  const StockProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.onHand,
    required this.status,
    required this.statusType,
  });
}

enum StockStatusType { healthy, lowStock, stockout }

class InventoryPage extends StatefulWidget {
  final InventoryPageMode initialMode;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onBackFromUpload;
  final String? businessId;
  final FutureOr<void> Function()? onCatalogSetupCompleted;
  final BrandRepository? brandRepository;
  final BrandProvider? brandProvider;
  final CategoryRepository? categoryRepository;
  final ProductMediaRepository? mediaRepository;
  final ProductRepository? productRepository;
  final SupplierRepository? supplierRepository;
  final LocationRepository? locationRepository;

  const InventoryPage({
    super.key,
    this.initialMode = InventoryPageMode.ageingReport,
    this.onTitleChanged,
    this.onBackFromUpload,
    this.businessId,
    this.onCatalogSetupCompleted,
    this.brandRepository,
    this.brandProvider,
    this.categoryRepository,
    this.mediaRepository,
    this.productRepository,
    this.supplierRepository,
    this.locationRepository,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late InventoryPageMode _mode;
  List<StockProductItem> _products = [];
  String? _selectedProductId;
  StockAdjustmentType? _selectedAdjustmentType;
  InventoryImportDraft? _importDraft;
  Map<String, InventoryImportTargetField> _columnMappings = {};
  int _inventoryRefreshKey = 0;

  void _notifyTitle() {
    if (_mode == InventoryPageMode.ageingReport) {
      widget.onTitleChanged?.call('Stock Ageing Report');
    } else if (_mode == InventoryPageMode.analytics) {
      widget.onTitleChanged?.call('Inventory Analytics');
    } else if (_mode == InventoryPageMode.uploadFile) {
      widget.onTitleChanged?.call('Import Inventory');
    } else if (_mode == InventoryPageMode.mapValidate) {
      widget.onTitleChanged?.call('Map & Validate Data');
    } else if (_mode == InventoryPageMode.validateRows) {
      widget.onTitleChanged?.call('Validate Rows');
    } else if (_mode == InventoryPageMode.reviewImport) {
      widget.onTitleChanged?.call('Review & Import');
    } else if (_mode == InventoryPageMode.stockAdjustment) {
      widget.onTitleChanged?.call('Stock Adjustment');
    } else if (_mode == InventoryPageMode.locations) {
      widget.onTitleChanged?.call('Locations');
    } else if (_mode == InventoryPageMode.locationDetails) {
      widget.onTitleChanged?.call('Location Details');
    } else if (_mode == InventoryPageMode.labels) {
      widget.onTitleChanged?.call('Labels');
    } else if (_mode == InventoryPageMode.activeStockCount) {
      widget.onTitleChanged?.call('Active Stock Count');
    } else if (_mode == InventoryPageMode.reconciliation) {
      widget.onTitleChanged?.call('Stock Count Reconciliation');
    } else if (_mode == InventoryPageMode.stockHistory) {
      widget.onTitleChanged?.call('Stock History & Audit Log');
    } else if (_mode == InventoryPageMode.damagedStock) {
      widget.onTitleChanged?.call('Damaged Stock & Quarantine');
    } else if (_mode == InventoryPageMode.createProduct) {
      widget.onTitleChanged?.call('Add Product');
    } else if (_mode == InventoryPageMode.variantMatrix) {
      widget.onTitleChanged?.call('Variant Matrix Configurator');
    } else if (_mode == InventoryPageMode.stockList) {
      widget.onTitleChanged?.call('Inventory');
    } else if (_mode == InventoryPageMode.productDetails) {
      widget.onTitleChanged?.call('Product details');
    } else {
      widget.onTitleChanged?.call('Stock Registry');
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTitle();
    });
    _products = [];
    _loadProducts();
  }

  @override
  void didUpdateWidget(covariant InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != oldWidget.initialMode && widget.initialMode != _mode) {
      setState(() {
        _mode = widget.initialMode;
        if (_mode == InventoryPageMode.stockList) {
          _selectedProductId = null;
        }
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final repo = widget.productRepository ?? ProductRepository();
      final prods = await repo.getProducts(businessId: widget.businessId);
      final summaries =
          await InventoryRepository().getProductInventorySummaries(
        businessId: widget.businessId,
        preloadedProducts: prods,
      );
      if (mounted) {
        setState(() {
          _products = prods.map((p) {
            final summary = summaries[p.id];
            final onHand = summary?.availableQty ?? 0;
            String priceStr = '—';
            if (summary != null && summary.variants.isNotEmpty) {
              final cents = summary.variants.first.retailPriceCents;
              priceStr =
                  '₹${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
            }
            return StockProductItem(
              id: p.id,
              name: p.name,
              sku: summary != null &&
                      summary.variants.isNotEmpty &&
                      summary.variants.first.sku.isNotEmpty
                  ? summary.variants.first.sku
                  : (p.id.length >= 8
                      ? p.id.substring(0, 8).toUpperCase()
                      : p.id.toUpperCase()),
              price: priceStr,
              onHand: onHand,
              status: summary?.stockStatusLabel ??
                  (p.isActive ? 'Healthy' : 'Draft'),
              statusType: summary?.stockStatus == StockStatus.healthy ||
                      summary?.stockStatus == StockStatus.inStock
                  ? StockStatusType.healthy
                  : (summary?.stockStatus == StockStatus.lowStock
                      ? StockStatusType.lowStock
                      : StockStatusType.stockout),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading stock registry: $e');
    }
  }

  void _showFeedback(String message, {bool isDestructive = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isDestructive
                  ? Icons.delete_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isDestructive
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFD5A46C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  void _handleDeleteProduct(StockProductItem product) {
    DeleteProductDialog.show(
      context,
      productName: product.name.contains('(')
          ? product.name.split('(').first.trim()
          : product.name,
      locationCount: 3,
      recordCount: product.onHand == 142 ? 247 : product.onHand * 2 + 15,
      initialChecked: false,
      initialConfirmText: 'DELETE',
      onConfirmDelete: () {
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });
        _showFeedback(
          'Product "${product.name}" and inventory records permanently deleted.',
          isDestructive: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == InventoryPageMode.ageingReport) {
      return StockAgeingReportView(
        onTriggerMarkdownPlan: () {},
        onExportBreakdown: () {},
      );
    }

    if (_mode == InventoryPageMode.analytics) {
      return InventoryAnalyticsView(
        onSwitchToStockList: () {
          setState(() {
            _mode = InventoryPageMode.stockList;
            _notifyTitle();
          });
        },
      );
    }

    if (_mode == InventoryPageMode.uploadFile) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: UploadFileView(
          hasUnsavedWork: _importDraft != null,
          backTooltip: widget.onBackFromUpload != null
              ? 'Back to inventory setup'
              : 'Back to inventory',
          onBack:
              widget.onBackFromUpload ??
              () {
                if (Navigator.canPop(context)) {
                  Navigator.maybePop(context);
                  return;
                }
                setState(() {
                  _importDraft = null;
                  _columnMappings = {};
                  _mode = InventoryPageMode.stockList;
                  _notifyTitle();
                });
              },
          onFileReady: (draft) {
            setState(() {
              _importDraft = draft;
              _columnMappings = {
                for (final header in draft.headers)
                  header: InventoryImportColumnMapper.suggest(header),
              };
              _mode = InventoryPageMode.mapValidate;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.mapValidate) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: MapValidateView(
          draft: _importDraft,
          columnMappings: _columnMappings,
          onMappingsChanged: (mappings) {
            setState(() => _columnMappings = mappings);
          },
          onContinue: () {
            if (_importDraft == null) {
              return;
            }
            setState(() {
              _mode = InventoryPageMode.validateRows;
              _notifyTitle();
            });
          },
          onCancel: () {
            setState(() {
              _mode = InventoryPageMode.uploadFile;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.validateRows) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: ValidateRowsView(
          draft: _importDraft,
          columnMappings: _columnMappings,
          onContinue: () {
            setState(() {
              _mode = InventoryPageMode.reviewImport;
              _notifyTitle();
            });
          },
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.mapValidate;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.activeStockCount) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: ActiveStockCountView(
          onGoToReconciliation: () {
            setState(() {
              _mode = InventoryPageMode.reconciliation;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.reconciliation) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: StockCountReconciliationView(
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.activeStockCount;
              _notifyTitle();
            });
          },
          onReconciliationCompleted: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.stockHistory) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: StockHistoryView(
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.damagedStock) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: DamagedStockView(
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.createProduct) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: CreateNewProductView(
          businessId: widget.businessId,
          initialProductId: _selectedProductId,
          brandRepository: widget.brandRepository,
          brandProvider: widget.brandProvider,
          categoryRepository: widget.categoryRepository,
          mediaRepository: widget.mediaRepository,
          productRepository: widget.productRepository,
          supplierRepository: widget.supplierRepository,
          locationRepository: widget.locationRepository,
          onPublishSuccess: (_) {},
          onPublishProduct: () async {
            if (widget.onCatalogSetupCompleted != null) {
              await widget.onCatalogSetupCompleted!();
            }
            if (!context.mounted) return;
            setState(() {
              _mode = InventoryPageMode.stockList;
              _inventoryRefreshKey++;
              _notifyTitle();
            });
            _loadProducts();
            if (widget.onBackFromUpload != null) {
              widget.onBackFromUpload!();
            } else if (Navigator.canPop(context)) {
              Navigator.maybePop(context);
            }
          },
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _inventoryRefreshKey++;
              _notifyTitle();
            });
            _loadProducts();
            if (widget.onBackFromUpload != null) {
              widget.onBackFromUpload!();
            } else if (Navigator.canPop(context)) {
              Navigator.maybePop(context);
            }
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.variantMatrix) {
      return const DesktopContentConstraint(
        maxWidth: 1360,
        child: VariantMatrixConfiguratorView(),
      );
    }

    if (_mode == InventoryPageMode.productDetails) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: ProductDetailsView(
          productId: _selectedProductId,
          businessId: widget.businessId,
          productRepository: widget.productRepository,
          locationRepository: widget.locationRepository,
          onBackToInventory: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _notifyTitle();
            });
          },
          onEditProduct: () {
            setState(() {
              _mode = InventoryPageMode.createProduct;
              _notifyTitle();
            });
          },
          onAdjustStock: (type) {
            setState(() {
              _selectedAdjustmentType = type;
              _mode = InventoryPageMode.stockAdjustment;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.stockList) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: InventoryProductsView(
          key: ValueKey('inv_products_$_inventoryRefreshKey'),
          businessId: widget.businessId,
          productRepository: widget.productRepository,
          categoryRepository: widget.categoryRepository,
          supplierRepository: widget.supplierRepository,
          locationRepository: widget.locationRepository,
          onAddProduct: () {
            setState(() {
              _selectedProductId = null;
              _mode = InventoryPageMode.createProduct;
              _notifyTitle();
            });
          },
          onImport: () {
            setState(() {
              _mode = InventoryPageMode.uploadFile;
              _notifyTitle();
            });
          },
          onStockCount: () {
            setState(() {
              _mode = InventoryPageMode.activeStockCount;
              _notifyTitle();
            });
          },
          onStockHistory: () {
            setState(() {
              _mode = InventoryPageMode.stockHistory;
              _notifyTitle();
            });
          },
          onDamagedStock: () {
            setState(() {
              _mode = InventoryPageMode.damagedStock;
              _notifyTitle();
            });
          },
          onAdjustStock: () {
            setState(() {
              _mode = InventoryPageMode.stockAdjustment;
              _notifyTitle();
            });
          },
          onViewProductDetails: (productId) {
            setState(() {
              _selectedProductId = productId;
              _mode = InventoryPageMode.productDetails;
              _notifyTitle();
            });
          },
          onEditProduct: (productId) {
            setState(() {
              _selectedProductId = productId;
              _mode = InventoryPageMode.createProduct;
              _notifyTitle();
            });
          },
          onAdjustProductStock: (productId) {
            setState(() {
              _selectedProductId = productId;
              _mode = InventoryPageMode.stockAdjustment;
              _notifyTitle();
            });
          },
          onProductStockHistory: (productId) {
            setState(() {
              _selectedProductId = productId;
              _mode = InventoryPageMode.stockHistory;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.labels) {
      return const DesktopContentConstraint(
        maxWidth: 1360,
        child: BarcodeLabelsView(),
      );
    }

    if (_mode == InventoryPageMode.locationDetails) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: LocationDetailsView(
          onBackToLocations: () {
            setState(() {
              _mode = InventoryPageMode.locations;
              _notifyTitle();
            });
          },
          onStockAdjustment: () {
            setState(() {
              _mode = InventoryPageMode.stockAdjustment;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.locations) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: LocationsView(
          onViewDetails: (loc) {
            setState(() {
              _mode = InventoryPageMode.locationDetails;
              _notifyTitle();
            });
          },
          onManageStock: (loc) {
            setState(() {
              _mode = InventoryPageMode.locationDetails;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.stockAdjustment) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: StockAdjustmentView(
          initialProductId: _selectedProductId,
          initialAdjustmentType: _selectedAdjustmentType,
          onViewHistory: () {
            setState(() {
              _mode = InventoryPageMode.stockHistory;
              _notifyTitle();
            });
          },
          onAdjustStockCompleted: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _inventoryRefreshKey++;
              _notifyTitle();
            });
          },
        ),
      );
    }

    if (_mode == InventoryPageMode.reviewImport) {
      return DesktopContentConstraint(
        maxWidth: 1320,
        child: ReviewImportView(
          draft: _importDraft,
          columnMappings: _columnMappings,
          onConfirm: () {
            widget.onCatalogSetupCompleted?.call();
            if (widget.onBackFromUpload != null) {
              widget.onBackFromUpload!();
            } else {
              setState(() {
                _mode = InventoryPageMode.stockList;
                _notifyTitle();
              });
            }
          },
          onBack: () {
            setState(() {
              _mode = InventoryPageMode.validateRows;
              _notifyTitle();
            });
          },
        ),
      );
    }

    return DesktopContentConstraint(
      maxWidth: 1320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header: Stock Registry + Add Product CTA
            _buildHeader(),

            const SizedBox(height: 24),

            // Stock Registry Table Card
            _buildStockRegistryCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Registry',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track products across active supply lines.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _mode = InventoryPageMode.analytics;
              _notifyTitle();
            });
          },
          icon: const Icon(
            Icons.analytics_outlined,
            size: 16,
            color: Color(0xFF8C5E33),
          ),
          label: Text(
            'Analytics View',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C5E33),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDECDB9)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            _showFeedback('Add Product modal dialog opening...');
          },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: Text(
            'Add Product',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1B18),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STOCK REGISTRY TABLE CARD
  // ---------------------------------------------------------------------------
  Widget _buildStockRegistryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Column Header
                Container(
                  color: const Color(0xFFFAF8F5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: _buildColumnHeader('Product'),
                      ),
                      SizedBox(width: 170, child: _buildColumnHeader('SKU')),
                      SizedBox(width: 120, child: _buildColumnHeader('Price')),
                      SizedBox(
                        width: 120,
                        child: _buildColumnHeader('On Hand'),
                      ),
                      SizedBox(width: 110, child: _buildColumnHeader('Status')),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEFE8DD)),

                // Rows
                if (_products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Text(
                      'No products in stock registry.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _products.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0xFFEFE8DD)),
                    _buildProductRow(_products[i]),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8C8377),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProductRow(StockProductItem product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Product Name
          SizedBox(
            width: 280,
            child: Text(
              product.name,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // SKU
          SizedBox(
            width: 170,
            child: Text(
              product.sku,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6357),
              ),
            ),
          ),

          // Price
          SizedBox(
            width: 120,
            child: Text(
              product.price,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),

          // On Hand
          SizedBox(
            width: 120,
            child: Text(
              '${product.onHand} units',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),

          // Status Badge
          SizedBox(
            width: 110,
            child: _buildStatusBadge(product.status, product.statusType),
          ),

          // Action Menu / Delete Button
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFF9E958A),
                    ),
                    hoverColor: const Color(0xFFFEF2F2),
                    splashRadius: 16,
                    tooltip: 'Delete Product',
                    onPressed: () => _handleDeleteProduct(product),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, StockStatusType type) {
    Color bg;
    Color text;

    switch (type) {
      case StockStatusType.healthy:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case StockStatusType.lowStock:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case StockStatusType.stockout:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
