// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
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

enum StockStatusType {
  healthy,
  lowStock,
  stockout,
}

class InventoryPage extends StatefulWidget {
  final InventoryPageMode initialMode;
  final ValueChanged<String>? onTitleChanged;

  const InventoryPage({
    super.key,
    this.initialMode = InventoryPageMode.ageingReport,
    this.onTitleChanged,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late InventoryPageMode _mode;
  late List<StockProductItem> _products;

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
      widget.onTitleChanged?.call('SoHo Flagship Store');
    } else if (_mode == InventoryPageMode.labels) {
      widget.onTitleChanged?.call('Labels');
    } else if (_mode == InventoryPageMode.activeStockCount) {
      widget.onTitleChanged?.call('Active Stock Count');
    } else if (_mode == InventoryPageMode.reconciliation) {
      widget.onTitleChanged?.call('Stock Count Reconciliation');
    } else if (_mode == InventoryPageMode.createProduct) {
      widget.onTitleChanged?.call('Create New Product');
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
    _products = [
      const StockProductItem(
        id: '1',
        name: 'Oxford Linen Shirt (Black/M)',
        sku: 'TS-OX-LN-BLK-M',
        price: '₹2,450',
        onHand: 18,
        status: 'Low Stock',
        statusType: StockStatusType.lowStock,
      ),
      const StockProductItem(
        id: '2',
        name: 'Nike Air Max 90 (White/10)',
        sku: 'NK-AM90-WHT-10',
        price: '₹11,999',
        onHand: 142,
        status: 'Healthy',
        statusType: StockStatusType.healthy,
      ),
      const StockProductItem(
        id: '3',
        name: 'Merino Wool Blazer (Navy/L)',
        sku: 'MW-BLZ-NVY-L',
        price: '₹8,900',
        onHand: 4,
        status: 'Low Stock',
        statusType: StockStatusType.lowStock,
      ),
      const StockProductItem(
        id: '4',
        name: 'Silk Evening Dress (Red/S)',
        sku: 'SLK-DRS-RED-S',
        price: '₹14,500',
        onHand: 0,
        status: 'Stockout',
        statusType: StockStatusType.stockout,
      ),
      const StockProductItem(
        id: '5',
        name: 'Casual Denim Jacket (Blue/M)',
        sku: 'DNM-JKT-BLU-S',
        price: '₹4,200',
        onHand: 83,
        status: 'Healthy',
        statusType: StockStatusType.healthy,
      ),
    ];
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
          onFilePicked: () {
            setState(() {
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
          onContinue: () {
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
      return const DesktopContentConstraint(
        maxWidth: 1360,
        child: ActiveStockCountView(),
      );
    }

    if (_mode == InventoryPageMode.reconciliation) {
      return const DesktopContentConstraint(
        maxWidth: 1360,
        child: StockCountReconciliationView(),
      );
    }

    if (_mode == InventoryPageMode.createProduct) {
      return const DesktopContentConstraint(
        maxWidth: 1360,
        child: CreateNewProductView(),
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
        ),
      );
    }

    if (_mode == InventoryPageMode.stockList) {
      return DesktopContentConstraint(
        maxWidth: 1360,
        child: InventoryProductsView(
          onAddProduct: () {
            setState(() {
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
          onAdjustStock: () {
            setState(() {
              _mode = InventoryPageMode.stockAdjustment;
              _notifyTitle();
            });
          },
          onViewProductDetails: (sku) {
            setState(() {
              _mode = InventoryPageMode.productDetails;
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
          initialLocation: 'Central Store',
          onViewHistory: () {
            setState(() {
              _mode = InventoryPageMode.ageingReport;
              _notifyTitle();
            });
          },
          onAdjustStockCompleted: () {
            setState(() {
              _mode = InventoryPageMode.ageingReport;
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
          onConfirm: () {
            setState(() {
              _mode = InventoryPageMode.stockList;
              _notifyTitle();
            });
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
          icon: const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF8C5E33)),
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
                      SizedBox(
                        width: 170,
                        child: _buildColumnHeader('SKU'),
                      ),
                      SizedBox(
                        width: 120,
                        child: _buildColumnHeader('Price'),
                      ),
                      SizedBox(
                        width: 120,
                        child: _buildColumnHeader('On Hand'),
                      ),
                      SizedBox(
                        width: 110,
                        child: _buildColumnHeader('Status'),
                      ),
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
