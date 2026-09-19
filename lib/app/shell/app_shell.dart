// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/ai_studio/presentation/pages/ai_studio_page.dart';
import '../../features/automations/presentation/pages/automations_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/overview/presentation/pages/overview_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/purchasing/presentation/pages/purchasing_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/transfers/presentation/pages/transfers_page.dart';
import '../../features/catalog/presentation/pages/catalog_manager_page.dart';
import '../../core/responsive/responsive_values.dart';
import '../widgets/activity_drawer.dart';
import '../widgets/atelier_dropdown.dart';
import '../widgets/command_palette_dialog.dart';
import '../widgets/keyboard_shortcuts_dialog.dart';
import '../widgets/switch_business_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String _overviewTitle = 'Overview';
  String _aiStudioTitle = 'Demand Forecast';
  String _aiStudioSubSection = 'demand_forecast';
  String _selectedLocation = 'central_warehouse';
  String _settingsSection = 'team_directory';
  String _settingsTitle = 'Team & Access';
  String _settingsSubtitle = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCommandPalette();
    });
  }
  bool _isActivityDrawerOpen = false;
  String _inventoryTitle = 'Product details';
  String _salesTitle = 'Return / Exchange';
  String _salesSubSection = 'returnExchange';
  String _purchasingTitle = 'Return to Supplier';
  String _purchasingSubSection = 'returnToSupplier';
  String _transfersTitle = 'New Stock Transfer';
  String _suppliersTitle = 'Partner Directory';
  String _insightsTitle = 'Restock Recommendation';
  String _insightsSubSection = 'restock_recommendation';
  String _automationsTitle = 'Create Automation';
  String _automationsSubSection = 'create_automation';

  String _getSearchHint() {
    if (_selectedIndex == 9) {
      if (_settingsSection == 'add_location') return 'Search settings...';
      if (_settingsSection == 'locations') return 'Search settings, locations or help...';
      if (_settingsSection == 'taxes_currency') return 'Search settings or configuration...';
      if (_settingsSection == 'documents_templates') return 'Search settings, documents or help...';
      if (_settingsSection == 'team_directory') return 'Search ThreadStock or ask AI...';
      if (_settingsSection == 'roles_permissions') return 'Search roles, people or permissions...';
      if (_settingsSection == 'security_sso' || _settingsSection == 'security' || _settingsTitle.contains('Security')) {
        return 'Search settings, users or help...';
      }
      if (_settingsSection == 'sales_channels' || _settingsTitle.contains('Sales Channels')) {
        return 'Search settings or ask AI...';
      }
      if (_settingsSection == 'notification_settings' ||
          _settingsSection == 'notifications_schema' ||
          _settingsTitle.contains('Notification') ||
          _settingsSection == 'barcode_printing' ||
          _settingsSection == 'barcode' ||
          _settingsTitle.contains('Barcode') ||
          _settingsSection == 'inventory_rules' ||
          _settingsSection == 'rules' ||
          _settingsTitle.contains('Inventory Rules') ||
          _settingsSection == 'purchasing_defaults' ||
          _settingsSection == 'purchasing' ||
          _settingsTitle.contains('Purchasing Defaults') ||
          _settingsSection == 'transfer_settings' ||
          _settingsSection == 'transfer_defaults' ||
          _settingsTitle.contains('Transfer Settings') ||
          _settingsSection == 'import_export' ||
          _settingsSection == 'import_export_studio' ||
          _settingsSection == 'import_export_center' ||
          _settingsTitle.contains('Import / Export') ||
          _settingsSection == 'api_webhooks' ||
          _settingsSection == 'webhooks' ||
          _settingsTitle.contains('API & Webhooks') ||
          _settingsSection == 'audit_log' ||
          _settingsSection == 'system_audit_log' ||
          _settingsSection == 'activity_logs' ||
          _settingsTitle.contains('Audit Log')) {
        return 'Search settings or ask AI...';
      }
      if (_settingsSection == 'shopify_connector' || _settingsTitle.contains('Shopify Connector')) {
        return 'Search or ask AI...';
      }
      if (_settingsSection == 'integrations' ||
          _settingsTitle.contains('Integrations') ||
          _settingsSection == 'system_integration_sync' ||
          _settingsTitle.contains('Sync')) {
        return 'Search ThreadStock or ask AI...';
      }
      return 'Search settings, features or help...';
    }

    if (_selectedIndex == 1) {
      if (_inventoryTitle == 'Product details' ||
          _inventoryTitle == 'Inventory' ||
          _inventoryTitle == 'Variant Matrix Configurator' ||
          _inventoryTitle == 'Create New Product' ||
          _inventoryTitle == 'Stock Count Reconciliation' ||
          _inventoryTitle == 'Active Stock Count') {
        return 'Search product, SKU or barcode...';
      }
      if (_inventoryTitle == 'Locations') return 'Search location, SKU or scan barcode...';
      if (_inventoryTitle == 'Stock Ageing Report') return 'Search analytics, products, or insights...';
      return 'Search ThreadStock or ask AI...';
    }

    if (_selectedIndex == 7 &&
        (_aiStudioSubSection == 'ai_actions' ||
            _aiStudioTitle == 'AI Actions' ||
            _aiStudioTitle == 'AI Studio')) {
      return 'Search or ask ThreadStock AI...';
    }

    if (_selectedIndex == 4 && _transfersTitle == 'New Stock Transfer') {
      return 'Search product, SKU or location...';
    }

    if (_selectedIndex == 2 &&
        (_salesSubSection == 'returnExchange' || _salesTitle == 'Return / Exchange')) {
      return 'Search product, SKU or customer...';
    }

    if ((_selectedIndex == 3 &&
            (_purchasingTitle == 'Return to Supplier' || _purchasingTitle == 'POs / Returns')) ||
        (_selectedIndex == 4 &&
            (_transfersTitle == 'TR-1042' || _transfersTitle == 'Active' || _transfersTitle == 'Transfer Order'))) {
      return 'Search inventory, POs, actions...';
    }

    if (_selectedIndex == 6 && _insightsSubSection == 'suppliers') {
      return 'Search analytics, suppliers, or insights...';
    }

    if (_selectedIndex == 6 &&
        (_insightsSubSection == 'profitability' ||
            _insightsSubSection == 'locations' ||
            _insightsSubSection == 'forecast_accuracy' ||
            _insightsSubSection == 'dead_stock')) {
      return 'Search analytics, products, or insights...';
    }

    return 'Search ThreadStock or ask AI...';
  }

  final List<Widget> _pages = const [
    OverviewPage(),
    InventoryPage(),
    SalesPage(),
    PurchasingPage(),
    TransfersPage(),
    SuppliersPage(),
    InsightsPage(),
    AiStudioPage(),
    AutomationsPage(),
    SettingsPage(),
    ProfilePage(),
  ];

  Widget _buildActivePage() {
    if (_selectedIndex == 0) {
      return OverviewPage(
        initialMode: OverviewPageMode.operationalOverview,
        onTitleChanged: (title) {
          if (_overviewTitle != title) {
            setState(() {
              _overviewTitle = title;
            });
          }
        },
        onNavigateToIndex: (index) {
          setState(() => _selectedIndex = index);
        },
      );
    }
    if (_selectedIndex == 1) {
      final invMode = (_inventoryTitle == 'Product details')
          ? InventoryPageMode.productDetails
          : ((_inventoryTitle == 'Inventory' ||
                  _inventoryTitle == 'Stock Registry')
              ? InventoryPageMode.stockList
              : ((_inventoryTitle == 'Variant Matrix Configurator')
                  ? InventoryPageMode.variantMatrix
                  : ((_inventoryTitle == 'Create New Product')
                      ? InventoryPageMode.createProduct
                      : ((_inventoryTitle == 'Stock Count Reconciliation')
                          ? InventoryPageMode.reconciliation
                          : ((_inventoryTitle == 'Active Stock Count')
                              ? InventoryPageMode.activeStockCount
                              : ((_inventoryTitle == 'Labels')
                                  ? InventoryPageMode.labels
                                  : ((_inventoryTitle == 'SoHo Flagship Store')
                                      ? InventoryPageMode.locationDetails
                                      : ((_inventoryTitle == 'Locations')
                                          ? InventoryPageMode.locations
                                          : ((_inventoryTitle == 'New Adjustment' ||
                                                  _inventoryTitle == 'Stock Adjustment' ||
                                                  _inventoryTitle == 'Adjustments')
                                              ? InventoryPageMode.stockAdjustment
                                              : (_inventoryTitle == 'Import Inventory'
                                                  ? InventoryPageMode.uploadFile
                                                  : (_inventoryTitle == 'Map & Validate Data'
                                                      ? InventoryPageMode.mapValidate
                                                      : (_inventoryTitle == 'Validate Rows'
                                                          ? InventoryPageMode.validateRows
                                                          : (_inventoryTitle == 'Review & Import'
                                                              ? InventoryPageMode.reviewImport
                                                              : (_inventoryTitle == 'Inventory Analytics'
                                                                  ? InventoryPageMode.analytics
                                                                  : InventoryPageMode.ageingReport))))))))))))));
      return InventoryPage(
        initialMode: invMode,
        onTitleChanged: (title) {
          if (_inventoryTitle != title) {
            setState(() {
              _inventoryTitle = title;
            });
          }
        },
      );
    }
    if (_selectedIndex == 2) {
      final salesMode = _salesSubSection == 'heldSales'
          ? SalesPageMode.heldSales
          : (_salesSubSection == 'invoice'
              ? SalesPageMode.invoice
              : (_salesSubSection == 'newSale'
                  ? SalesPageMode.newSale
                  : (_salesSubSection == 'customers'
                      ? SalesPageMode.customers
                      : (_salesSubSection == 'returnExchange'
                          ? SalesPageMode.returnExchange
                          : (_salesSubSection == 'overview'
                              ? SalesPageMode.overview
                              : SalesPageMode.analytics)))));
      return SalesPage(
        initialMode: salesMode,
        initialSaleId: '#TS-10482',
        onTitleChanged: (title) {
          if (_salesTitle != title) {
            setState(() {
              _salesTitle = title;
            });
          }
        },
      );
    }
    if (_selectedIndex == 3) {
      final mode = _purchasingSubSection == 'returnToSupplier'
          ? PurchasingViewMode.returnToSupplier
          : (_purchasingSubSection == 'accessRestricted'
              ? PurchasingViewMode.accessRestricted
              : (_purchasingSubSection == 'createPo'
                  ? PurchasingViewMode.createPo
                  : (_purchasingSubSection == 'poDetail10482'
                      ? PurchasingViewMode.poDetail10482
                      : PurchasingViewMode.overview)));
      return PurchasingPage(
        initialMode: mode,
        initialPoNumber: 'PO-2024-8902',
        onNavigateToDashboard: () {
          setState(() => _selectedIndex = 0);
        },
        onTitleChanged: (title) {
          if (_purchasingTitle != title) {
            setState(() {
              _purchasingTitle = title;
              // Keep subsection in sync when page internally navigates
              if (title == 'Return to Supplier') {
                _purchasingSubSection = 'returnToSupplier';
              } else if (title == 'Purchasing Settings') {
                _purchasingSubSection = 'accessRestricted';
              } else if (title == 'Create Purchase Order') {
                _purchasingSubSection = 'createPo';
              } else if (title == 'PO #10482') {
                _purchasingSubSection = 'poDetail10482';
              } else {
                _purchasingSubSection = 'overview';
              }
            });
          }
        },
      );
    }
    if (_selectedIndex == 4) {
      final mode = (_transfersTitle == 'New Stock Transfer')
          ? TransfersViewMode.newTransfer
          : ((_transfersTitle == 'Receiving' ||
                  _transfersTitle == 'Inbound Logistics & Shipments')
              ? TransfersViewMode.receivingQueue
              : ((_transfersTitle == 'Receiving Workflow' ||
                      _transfersTitle == 'Receive Transfer TR-1042')
                  ? TransfersViewMode.receiveTransfer
                  : (_transfersTitle == 'Dispatch Transfer TR-1042'
                      ? TransfersViewMode.dispatchTransfer
                      : ((_transfersTitle == 'TR-1042' ||
                              _transfersTitle == 'Active' ||
                              _transfersTitle == 'Transfer Order')
                          ? TransfersViewMode.orderDetail
                          : TransfersViewMode.overview))));
      return TransfersPage(
        initialMode: mode,
        initialTransferId: 'PO-2024-0847',
        onTitleChanged: (title) {
          if (_transfersTitle != title) {
            setState(() {
              _transfersTitle = title;
            });
          }
        },
        onNavigateToOverview: () {
          setState(() {
            _transfersTitle = 'Receiving';
          });
        },
      );
    }
    if (_selectedIndex == 5) {
      final mode = (_suppliersTitle == 'Partner Directory' || _suppliersTitle == 'Partners & Manufacturers')
          ? SuppliersViewMode.directory
          : SuppliersViewMode.profile;
      return SuppliersPage(
        initialMode: mode,
        supplierName: _suppliersTitle == 'Partner Directory' ? 'Milano Tessuti' : _suppliersTitle,
        onNavigateToPo: (poNumber) {
          setState(() {
            _selectedIndex = 3; // Purchasing
            _purchasingTitle = poNumber;
            _purchasingSubSection = 'poDetail10482';
          });
        },
        onTitleChanged: (title) {
          if (_suppliersTitle != title) {
            setState(() {
              _suppliersTitle = title;
            });
          }
        },
      );
    }
    if (_selectedIndex == 6) {
      final mode = (_insightsSubSection == 'restock_recommendation' || _insightsTitle == 'Restock Recommendation')
          ? InsightsViewMode.restockRecommendation
          : ((_insightsSubSection == 'shrinkage_investigation' || _insightsSubSection == 'investigation')
              ? InsightsViewMode.shrinkageInvestigation
          : ((_insightsSubSection == 'anomaly_center' || _insightsSubSection == 'anomalies')
              ? InsightsViewMode.anomalyCenter
              : (_insightsSubSection == 'dead_stock'
                  ? InsightsViewMode.deadStock
                  : (_insightsSubSection == 'forecast_accuracy' || _insightsSubSection == 'forecasting'
                      ? InsightsViewMode.forecastAccuracy
                      : (_insightsSubSection == 'suppliers'
                          ? InsightsViewMode.supplierPerformance
                          : (_insightsSubSection == 'locations'
                              ? InsightsViewMode.locationComparison
                              : (_insightsSubSection == 'profitability'
                                      ? InsightsViewMode.profitabilityAnalysis
                                      : InsightsViewMode.reportStudio)))))));
      return InsightsPage(
        initialMode: mode,
        showScheduleDialogOnInit: false,
        onTitleChanged: (title) {
          if (_insightsTitle != title) {
            setState(() {
              _insightsTitle = title;
              if (title == 'Shrinkage Investigation') {
                _insightsSubSection = 'shrinkage_investigation';
              } else if (title == 'Anomaly Center') {
                _insightsSubSection = 'anomaly_center';
              }
            });
          }
        },
        onNavigateToAutomations: () {
          setState(() => _selectedIndex = 8);
        },
        onNavigateToInventory: () {
          setState(() => _selectedIndex = 1);
        },
        onNavigateToPurchasing: () {
          setState(() => _selectedIndex = 3);
        },
        onNavigateToSuppliers: () {
          setState(() => _selectedIndex = 5);
        },
      );
    }
    if (_selectedIndex == 7) {
      final mode = (_aiStudioSubSection == 'demand_forecast' || _aiStudioTitle == 'Demand Forecast')
          ? AiStudioViewMode.demandForecast
          : ((_aiStudioSubSection == 'ai_history' || _aiStudioTitle == 'AI History')
              ? AiStudioViewMode.aiHistory
              : ((_aiStudioSubSection == 'proposal_detail' || _aiStudioTitle == 'Proposal Detail')
                  ? AiStudioViewMode.proposalDetail
                  : ((_aiStudioSubSection == 'ai_actions' || _aiStudioTitle == 'AI Actions' || _aiStudioTitle == 'AI Studio')
                      ? AiStudioViewMode.aiActions
                      : AiStudioViewMode.forecastDetail)));
      return AiStudioPage(
        initialMode: mode,
        onTitleChanged: (title) {
          if (_aiStudioTitle != title) {
            setState(() {
              _aiStudioTitle = title;
              if (title == 'Demand Forecast') {
                _aiStudioSubSection = 'demand_forecast';
              } else if (title == 'AI History') {
                _aiStudioSubSection = 'ai_history';
              } else if (title == 'Proposal Detail') {
                _aiStudioSubSection = 'proposal_detail';
              } else if (title == 'AI Actions' || title == 'AI Studio') {
                _aiStudioSubSection = 'ai_actions';
              }
            });
          }
        },
        onNavigateToIndex: (index) {
          setState(() => _selectedIndex = index);
        },
      );
    }
    if (_selectedIndex == 9) {
      return SettingsPage(
        initialSection: _settingsSection,
        onSubNavChanged: (title, subtitle) {
          if (_settingsTitle != title || _settingsSubtitle != subtitle) {
            setState(() {
              _settingsTitle = title;
              _settingsSubtitle = subtitle;
              if (title == 'Settings Search' || title == 'Settings' || title == 'System Settings') {
                _settingsSection = 'settings_search';
              } else if (title == 'Add Location') {
                _settingsSection = 'add_location';
              } else if (title == 'Locations') {
                _settingsSection = 'locations';
              } else if (title == 'Business Profile') {
                _settingsSection = 'business_profile';
              } else if (title == 'Taxes & Currency') {
                _settingsSection = 'taxes_currency';
              } else if (title == 'Document Settings') {
                _settingsSection = 'documents_templates';
              } else if (title == 'Team & Access' || title == 'Team Directory') {
                _settingsSection = 'team_directory';
              } else if (title == 'Roles & Permissions') {
                _settingsSection = 'roles_permissions';
              } else if (title == 'Settings > Notification Settings' ||
                  title == 'Notification Preferences' ||
                  title == 'Notification Settings') {
                _settingsSection = 'notification_settings';
              } else if (title == 'Settings > Barcode & Printing' ||
                  title == 'Barcode & Printing') {
                _settingsSection = 'barcode_printing';
              } else if (title == 'Settings > Inventory Rules' ||
                  title == 'Inventory Rules') {
                _settingsSection = 'inventory_rules';
              } else if (title.contains('Purchasing Defaults') ||
                  title == 'Purchasing') {
                _settingsSection = 'purchasing_defaults';
              }
            });
          }
        },
      );
    }
    if (_selectedIndex == 10) {
      return ProfilePage(
        onConfigureNotifications: () {
          setState(() {
            _selectedIndex = 9;
            _settingsTitle = 'Preferences';
          });
        },
      );
    }
    if (_selectedIndex == 11 || _selectedIndex == 12 || _selectedIndex == 13 || _selectedIndex == 14) {
      return const CatalogManagerPage();
    }
    if (_selectedIndex == 8) {
      final mode = (_automationsSubSection == 'create_automation' || _automationsTitle == 'Create Automation')
          ? AutomationsViewMode.createAutomation
          : AutomationsViewMode.runDetail;
      return AutomationsPage(
        initialMode: mode,
        onTitleChanged: (title) {
          if (_automationsTitle != title) {
            setState(() {
              _automationsTitle = title;
              if (title == 'Create Automation') {
                _automationsSubSection = 'create_automation';
              }
            });
          }
        },
      );
    }
    return _pages[_selectedIndex < _pages.length ? _selectedIndex : 0];
  }

  void _openCommandPalette() {
    CommandPaletteDialog.show(
      context,
      initialQuery: '',
      onNavigateToIndex: (index) {
        setState(() => _selectedIndex = index);
      },
      onNavigateToSalesMode: (mode) {
        setState(() {
          _selectedIndex = 2;
          _salesSubSection = mode;
        });
      },
      onNavigateToInventoryMode: (title) {
        setState(() {
          _selectedIndex = 1;
          _inventoryTitle = title;
        });
      },
      onNavigateToSettingsSection: (sec) {
        setState(() {
          _selectedIndex = 9;
          _settingsSection = sec;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.keyK) &&
              (HardwareKeyboard.instance.isMetaPressed ||
                  HardwareKeyboard.instance.isControlPressed)) {
            _openCommandPalette();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.slash &&
              (HardwareKeyboard.instance.isMetaPressed ||
                  HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isShiftPressed)) {
            KeyboardShortcutsDialog.show(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Row(
          children: [
            // Left Atelier Desktop Sidebar
            _buildSidebar(),

            // Main Workspace Area with Background Texture
            Expanded(
              child: Container(
                color: const Color(0xFFF6F1EA),
                child: Stack(
                  children: [
                    // Atmospheric Silk & Sunlight Background (30% Opacity)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.30,
                        child: Image.asset(
                          'Assets/Desktop_Background.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Foreground Content: Top Bar + Active Page
                    Column(
                      children: [
                        // Top Navigation Bar
                        _buildTopBar(),

                        // Active View with Activity Drawer overlay
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _buildActivePage(),
                              ),

                              // Scrim over page content
                              if (_isActivityDrawerOpen)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isActivityDrawerOpen = false),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.18),
                                    ),
                                  ),
                                ),

                              // Activity Drawer anchored to the right
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                top: 0,
                                bottom: 0,
                                right: _isActivityDrawerOpen ? 0 : -460,
                                width: 440,
                                child: ActivityDrawer(
                                  onClose: () => setState(() => _isActivityDrawerOpen = false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Left Sidebar matching ThreadStock Luxury Aesthetic
  Widget _buildSidebar() {
    return Container(
      width: context.responsiveSidebarWidth,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        border: Border(
          right: BorderSide(color: Color(0xFFEBE2D5), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Monogram + Logo
          Padding(
            padding: EdgeInsets.only(
              left: context.isCompactDesktop ? 16 : 20,
              top: 22,
              bottom: 22,
              right: context.isCompactDesktop ? 12 : 18,
            ),
            child: Row(
              children: [
                Image.asset(
                  'Assets/logo_mark.png',
                  height: context.isCompactDesktop ? 30 : 34,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'THREADSTOCK',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        letterSpacing: 15 * 0.20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1816),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('WORKSPACE'),
                  _buildNavItem(index: 0, label: 'Overview', icon: Icons.home_outlined),
                  _buildNavItem(index: 1, label: 'Inventory', icon: Icons.inventory_2_outlined),
                  if (_selectedIndex == 1 &&
                      (_inventoryTitle == 'Import Inventory' ||
                          _inventoryTitle == 'Map & Validate Data' ||
                          _inventoryTitle == 'Validate Rows' ||
                          _inventoryTitle == 'Review & Import')) ...[
                    const SizedBox(height: 3),
                    _buildInventorySubItem(
                      label: 'Import Inventory',
                      id: 'uploadFile',
                      isSelected: true,
                    ),
                    const SizedBox(height: 5),
                  ],
                  _buildNavItem(index: 2, label: 'Sales', icon: Icons.trending_up_rounded),
                  if (_selectedIndex == 2 &&
                      _salesSubSection != 'analytics' &&
                      _salesSubSection != 'overview' &&
                      _salesSubSection != 'returnExchange') ...[
                    const SizedBox(height: 3),
                    _buildSalesSubItem(
                      label: 'Analytics',
                      id: 'analytics',
                      isSelected: _salesSubSection == 'analytics',
                    ),
                    _buildSalesSubItem(
                      label: 'Customers',
                      id: 'customers',
                      isSelected: _salesSubSection == 'customers',
                    ),
                    _buildSalesSubItem(
                      label: 'New Sale',
                      id: 'newSale',
                      isSelected: _salesSubSection == 'newSale',
                    ),
                    _buildSalesSubItem(
                      label: 'Held Sales',
                      id: 'heldSales',
                      isSelected: _salesSubSection == 'heldSales',
                    ),
                    _buildSalesSubItem(
                      label: 'Invoice',
                      id: 'invoice',
                      isSelected: _salesSubSection == 'invoice',
                    ),
                    const SizedBox(height: 5),
                  ],
                  const SizedBox(height: 18),

                  _buildSectionHeader('OPERATIONS'),
                  _buildNavItem(index: 3, label: 'Purchasing', icon: Icons.shopping_bag_outlined),
                  if (_selectedIndex == 3 &&
                      _purchasingSubSection != 'overview' &&
                      _purchasingSubSection != 'returnToSupplier') ...[
                    const SizedBox(height: 3),
                    _buildPurchasingSubItem(
                      label: 'Overview',
                      id: 'overview',
                      isSelected: _purchasingSubSection == 'overview',
                    ),
                    _buildPurchasingSubItem(
                      label: 'Create PO',
                      id: 'createPo',
                      isSelected: _purchasingSubSection == 'createPo',
                    ),
                    _buildPurchasingSubItem(
                      label: 'PO #10482',
                      id: 'poDetail10482',
                      isSelected: _purchasingSubSection == 'poDetail10482',
                    ),
                    const SizedBox(height: 5),
                  ],
                  _buildNavItem(index: 4, label: 'Transfers', icon: Icons.sync_alt_rounded),
                  _buildNavItem(index: 5, label: 'Suppliers', icon: Icons.people_outline_rounded),
                  const SizedBox(height: 18),

                  _buildSectionHeader('INTELLIGENCE'),
                  _buildNavItem(index: 6, label: 'Insights', icon: Icons.auto_awesome_rounded),
                  if (_selectedIndex == 6 &&
                      _insightsSubSection != 'anomaly_center' &&
                      _insightsSubSection != 'anomalies' &&
                      _insightsSubSection != 'shrinkage_investigation') ...[
                    const SizedBox(height: 3),
                    _buildInsightsSubItem(
                      label: 'Dead Stock',
                      id: 'dead_stock',
                      isSelected: _insightsSubSection == 'dead_stock',
                    ),
                    _buildInsightsSubItem(
                      label: 'Forecasting',
                      id: 'forecasting',
                      isSelected: _insightsSubSection == 'forecasting' || _insightsSubSection == 'forecast_accuracy',
                    ),
                    _buildInsightsSubItem(
                      label: 'Inventory Health',
                      id: 'inventory_health',
                      isSelected: _insightsSubSection == 'inventory_health',
                    ),
                    _buildInsightsSubItem(
                      label: 'Category Analysis',
                      id: 'category_analysis',
                      isSelected: _insightsSubSection == 'category_analysis',
                    ),
                    const SizedBox(height: 5),
                  ],
                  _buildNavItem(index: 7, label: 'AI Studio', icon: Icons.center_focus_strong_outlined),
                  _buildNavItem(index: 8, label: 'Automations', icon: Icons.tune_rounded),
                  const SizedBox(height: 18),

                  _buildSectionHeader('CATALOG SETUP'),
                  _buildNavItem(index: 11, label: 'Catalog Manager', icon: Icons.category_outlined),
                  _buildNavItem(index: 12, label: 'Collections', icon: Icons.collections_bookmark_outlined),
                  _buildNavItem(index: 13, label: 'Brands', icon: Icons.branding_watermark_outlined),
                  _buildNavItem(index: 14, label: 'Attributes', icon: Icons.tune_outlined),
                ],
              ),
            ),
          ),

          // Bottom Settings & Profile Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEBE2D5), width: 1.0),
              ),
            ),
            child: Column(
              children: [
                _buildNavItem(index: 9, label: 'Settings', icon: Icons.settings_outlined),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  tooltip: 'User menu',
                  offset: const Offset(0, -98),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFEADBCA)),
                  ),
                  onSelected: (val) {
                    if (val == 'profile') {
                      setState(() => _selectedIndex = 10);
                    } else if (val == 'shortcuts') {
                      KeyboardShortcutsDialog.show(context);
                    } else if (val == 'switch_business') {
                      SwitchBusinessDialog.show(context);
                    } else if (val == 'sign_out') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Signed out from Central Admin session.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: const Color(0xFF1E1C1A),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'switch_business',
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 17, color: Color(0xFF8D6433)),
                          const SizedBox(width: 10),
                          Text(
                            'Switch Business',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'profile',
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 17, color: Color(0xFF5E574E)),
                          const SizedBox(width: 10),
                          Text(
                            'My Profile',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'shortcuts',
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(Icons.keyboard_outlined, size: 17, color: Color(0xFF5E574E)),
                          const SizedBox(width: 10),
                          Text(
                            'Keyboard Shortcuts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'sign_out',
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, size: 17, color: Color(0xFF9E4738)),
                          const SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9E4738),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: _insightsSubSection == 'suppliers'
                                ? Image.asset(
                                    'Assets/alex_mercer.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        color: ((_selectedIndex == 3 && _purchasingTitle == 'Return to Supplier') ||
                                                (_selectedIndex == 4 &&
                                                    (_transfersTitle == 'TR-1042' ||
                                                        _transfersTitle == 'Active' ||
                                                        _transfersTitle == 'Transfer Order')))
                                            ? const Color(0xFFC88219)
                                            : const Color(0xFF8D7B38),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'AM',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: ((_selectedIndex == 3 && _purchasingTitle == 'Return to Supplier') ||
                                              (_selectedIndex == 4 &&
                                                  (_transfersTitle == 'TR-1042' ||
                                                      _transfersTitle == 'Active' ||
                                                      _transfersTitle == 'Transfer Order')))
                                          ? const Color(0xFFC88219)
                                          : const Color(0xFF8D7B38),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'AM',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ((_selectedIndex == 3 && _purchasingTitle == 'Return to Supplier') ||
                                        (_selectedIndex == 4 &&
                                            (_transfersTitle == 'TR-1042' ||
                                                _transfersTitle == 'Active' ||
                                                _transfersTitle == 'Transfer Order')))
                                    ? 'No user configured'
                                    : 'No user configured',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                              Text(
                                'No workspace configured',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF7E766B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.unfold_more_rounded,
                          size: 16,
                          color: Color(0xFF9E958A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSubItem({
    required String label,
    required String id,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _insightsSubSection = id;
          if (id == 'dead_stock') {
            _insightsTitle = 'Dead Stock Analysis';
          } else if (id == 'forecasting' || id == 'forecast_accuracy') {
            _insightsTitle = 'Forecast Accuracy';
          } else if (id == 'inventory_health') {
            _selectedIndex = 1;
            _inventoryTitle = 'Inventory Analytics';
          } else if (id == 'profitability') {
            _insightsTitle = 'Profitability Analysis';
          } else if (id == 'locations') {
            _insightsTitle = 'Location Comparison';
          } else if (id == 'suppliers') {
            _insightsTitle = 'Supplier Performance';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$label view will be available in the next release.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                backgroundColor: const Color(0xFF1E1C1A),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4, right: 12),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8C5E33)
                    : const Color(0xFF6E665A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF8C5E33)
                    : const Color(0xFF5E574E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSubItem({
    required String label,
    required String id,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _salesSubSection = id;
          if (id == 'analytics') {
            _salesTitle = 'Sales Analytics';
          } else if (id == 'heldSales') {
            _salesTitle = 'Held Sales';
          } else if (id == 'invoice') {
            _salesTitle = 'PO-10482 Invoice';
          } else if (id == 'newSale') {
            _salesTitle = 'New Sale';
          } else {
            _salesTitle = 'Sales';
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4, right: 12),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF6E665A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF5E574E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasingSubItem({
    required String label,
    required String id,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _purchasingSubSection = id;
          if (id == 'createPo') {
            _purchasingTitle = 'Create Purchase Order';
          } else if (id == 'poDetail10482') {
            _purchasingTitle = 'PO #10482';
          } else {
            _purchasingTitle = 'Purchase Orders';
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4, right: 12),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF6E665A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF5E574E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySubItem({
    required String label,
    required String id,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          if (id == 'uploadFile') {
            _inventoryTitle = 'Import Inventory';
          } else if (id == 'mapValidate') {
            _inventoryTitle = 'Map & Validate Data';
          } else {
            _inventoryTitle = 'Stock Ageing Report';
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4, right: 12),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF6E665A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF8C5E33) : const Color(0xFF5E574E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8E867B),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedIndex == index || (index == 9 && _selectedIndex == 10);
    return InkWell(
      onTap: () => setState(() {
        _selectedIndex = index;
        if (index == 9) {
          _settingsSection = 'settings_search';
          _settingsTitle = 'Settings Search';
          _settingsSubtitle = '';
        }
      }),
      borderRadius: BorderRadius.circular(8),
      canRequestFocus: false,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? ((index == 0 || index == 7 || index == 6 || index == 8 || index == 3 || index == 4) ? const Color(0xFFFAF3E8) : const Color(0xFFF1E9DE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (index == 7)
              Container(
                width: 20,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB37B42) : const Color(0xFF8E867B),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  'AI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 19,
                color: isSelected
                    ? ((index == 9 || index == 6 || index == 0 || index == 7 || index == 8 || index == 3 || index == 4)
                        ? const Color(0xFFB37B42)
                        : const Color(0xFF1E1C1A))
                    : const Color(0xFF635C53),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? ((index == 0 || index == 7 || index == 6 || index == 8 || index == 3 || index == 4) ? const Color(0xFFB37B42) : const Color(0xFF1E1C1A))
                      : const Color(0xFF4C453C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar with responsive desktop layout
  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveHorizontalMargin,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.48),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFEADBCA),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Page Title + Divider + Location Dropdown
              Expanded(
                child: Row(
                  children: [
                    if (_selectedIndex == 3 &&
                        (_purchasingTitle == 'Return to Supplier' ||
                            _purchasingTitle == 'POs / Returns'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Purchasing',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 13.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'POs / Returns',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 13.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Return to Supplier',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 4 && _transfersTitle == 'New Stock Transfer')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _transfersTitle = 'Receiving');
                            },
                            child: Text(
                              'Transfers',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'New Stock Transfer',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Inter-Location Replenishment Ledger',
                                style: GoogleFonts.inter(
                                  fontSize: context.isCompactDesktop ? 13 : 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ],
                      )
                    else if (_selectedIndex == 4 &&
                        (_transfersTitle == 'Receiving' ||
                            _transfersTitle == 'Inbound Logistics & Shipments' ||
                            _transfersTitle == 'Receiving Workflow' ||
                            _transfersTitle == 'Receive Transfer TR-1042' ||
                            _transfersTitle == 'Dispatch Transfer TR-1042' ||
                            _transfersTitle == 'TR-1042' ||
                            _transfersTitle == 'Active' ||
                            _transfersTitle == 'Transfer Order'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _transfersTitle = 'Receiving');
                            },
                            child: Text(
                              'Transfers',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          if (_transfersTitle == 'Receiving' ||
                              _transfersTitle == 'Inbound Logistics & Shipments') ...[
                            InkWell(
                              onTap: () {
                                setState(() => _transfersTitle = 'Receiving');
                              },
                              child: Text(
                                'Receiving',
                                style: GoogleFonts.inter(
                                  fontSize: context.isCompactDesktop ? 13 : 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Inbound Logistics & Shipments',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ] else if (_transfersTitle == 'Receiving Workflow' ||
                              _transfersTitle == 'Receive Transfer TR-1042') ...[
                            Text(
                              'Receiving Workflow',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Central Warehouse (Zone A)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              _transfersTitle == 'Dispatch Transfer TR-1042'
                                  ? 'Prepare'
                                  : 'Active',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text(
                              _transfersTitle == 'Dispatch Transfer TR-1042'
                                  ? 'Dispatch Transfer TR-1042'
                                  : 'TR-1042',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_selectedIndex == 5)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _suppliersTitle = 'Milano Tessuti');
                            },
                            child: Text(
                              'Suppliers',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            _suppliersTitle,
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 8 &&
                        (_automationsSubSection == 'create_automation' ||
                            _automationsTitle == 'Create Automation'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Automations',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Create Automation',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 6 &&
                        (_insightsSubSection == 'shrinkage_investigation' ||
                            _insightsSubSection == 'investigation'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _insightsSubSection = 'anomaly_center';
                                _insightsTitle = 'Anomaly Center';
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Insights',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _insightsSubSection = 'anomaly_center';
                                _insightsTitle = 'Anomaly Center';
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Anomalies',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Shrinkage Investigation',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 6 &&
                        (_insightsSubSection == 'anomaly_center' ||
                            _insightsSubSection == 'anomalies'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Intelligence',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Anomaly Center',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 7 &&
                        (_aiStudioSubSection == 'proposal_detail' ||
                            _aiStudioTitle == 'Proposal Detail'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Proposal Detail',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 7 &&
                        (_aiStudioSubSection == 'demand_forecast' ||
                            _aiStudioTitle == 'Demand Forecast' ||
                            _aiStudioSubSection == 'ai_history' ||
                            _aiStudioTitle == 'AI History' ||
                            _aiStudioSubSection == 'ai_actions' ||
                            _aiStudioTitle == 'AI Actions' ||
                            _aiStudioTitle == 'AI Studio'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI Studio',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 7)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI Studio',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Forecasts',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Classic White Oxford — M',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          AtelierDropdown<String>(
                            value: _selectedLocation,
                            isBorderless: true,
                            menuWidth: 260,
                            triggerLabel: (item) => 'Central Warehouse (Zone A)',
                            items: const [
                              AtelierDropdownItem(
                                value: 'central_warehouse',
                                title: 'Central Warehouse',
                                subtitle: 'Zone A',
                                icon: Icons.warehouse_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'delhi_flagship',
                                title: 'Delhi Flagship',
                                subtitle: 'Zone B',
                                icon: Icons.storefront_outlined,
                              ),
                              AtelierDropdownItem(
                                value: 'mumbai_boutique',
                                title: 'Mumbai Boutique',
                                subtitle: 'Zone C',
                                icon: Icons.storefront_outlined,
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedLocation = val);
                            },
                          ),
                        ],
                      )
                    else if (_selectedIndex == 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Overview',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Product details')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Inventory'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Product details',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Inventory')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Inventory',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Variant Matrix Configurator')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Products',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Create New Product'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Merino Wool Crewneck',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Matrix Setup',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Create New Product')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Products',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Setup Ledger',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Create New Product',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Stock Count Reconciliation')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Stock Count Reconciliation',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Q3 Full Inventory Count — Audit Workspace',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Active Stock Count')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Active Stock Count',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Q3 Full Inventory Count — Zone A',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 9 && (_settingsSection == 'roles_permissions' || _settingsTitle == 'Roles & Permissions'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _settingsSection = 'system_settings';
                              _settingsTitle = 'System Settings';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Settings',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Roles & Permissions',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 9 && (_settingsSection == 'team_directory' || _settingsTitle == 'Team & Access'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Settings',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Labels')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Labels',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Store',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'SoHo Flagship Store')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Locations'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Locations',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'SoHo Flagship Store'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'SoHo Flagship Store',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Inventory',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Locations')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Locations',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 &&
                        (_inventoryTitle == 'New Adjustment' ||
                            _inventoryTitle == 'Stock Adjustment' ||
                            _inventoryTitle == 'Adjustments'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'New Adjustment'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Adjustments',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'New Adjustment',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Store',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Import Inventory')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Import Inventory',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Map & Validate Data')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Import Inventory'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Import Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Map & Validate Data',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Validate Rows')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Map & Validate Data'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Map & Validate',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Validate Rows',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Review & Import')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Stock Ageing Report'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _inventoryTitle = 'Validate Rows'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Validate Rows',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Review & Import',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Stock Ageing Report')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stock Ageing Report',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Valuation Cost Basis',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF355E82),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 1 && _inventoryTitle == 'Inventory Analytics')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Inventory Analytics',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                        ],
                      )
                    else if (_selectedIndex == 2 &&
                        (_salesSubSection == 'returnExchange' || _salesTitle == 'Return / Exchange'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Return / Exchange',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 2 && _salesSubSection == 'customers')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _salesSubSection = 'analytics';
                              _salesTitle = 'Sales Analytics';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Sales',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Customers',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 2 && _salesSubSection == 'heldSales')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _salesSubSection = 'analytics';
                              _salesTitle = 'Sales Analytics';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Sales',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Held Sales',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 2 && _salesSubSection == 'invoice')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _salesSubSection = 'analytics';
                              _salesTitle = 'Sales Analytics';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Sales',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'PO-10482 Invoice',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 2 && _salesTitle == 'Sales Analytics')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sales Analytics',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'All India Operations',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 3 && _purchasingSubSection == 'createPo')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _purchasingSubSection = 'overview';
                              _purchasingTitle = 'Purchase Orders';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Purchasing',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Create Purchase Order',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 3 && _purchasingSubSection == 'poDetail10482')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              _purchasingSubSection = 'overview';
                              _purchasingTitle = 'Purchase Orders';
                            }),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Purchasing',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'PO #10482',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 6 && _insightsSubSection == 'dead_stock')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Dead Stock Analysis',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Stockage Age > 90 Days',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF355E82),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 6 &&
                        (_insightsSubSection == 'restock_recommendation' ||
                            _insightsTitle == 'Restock Recommendation'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _insightsSubSection = 'forecast_accuracy'),
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'AI Insights',
                              style: GoogleFonts.inter(
                                fontSize: context.isCompactDesktop ? 13 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Restock Recommendation',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Central Warehouse (Zone A)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_selectedIndex == 6 &&
                        (_insightsSubSection == 'profitability' ||
                            _insightsSubSection == 'locations' ||
                            _insightsSubSection == 'suppliers' ||
                            _insightsSubSection == 'forecast_accuracy'))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Intelligence Hub',
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFDCD2C3),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            _insightsSubSection == 'locations'
                                ? 'Location Comparison'
                                : (_insightsSubSection == 'suppliers'
                                    ? 'Supplier Performance'
                                    : (_insightsSubSection == 'forecast_accuracy'
                                        ? 'Forecast Accuracy'
                                        : 'Profitability Analysis')),
                            style: GoogleFonts.inter(
                              fontSize: context.isCompactDesktop ? 13 : 14.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Flexible(
                        child: (_selectedIndex == 9 && _settingsTitle.contains(' > '))
                            ? _buildSettingsBreadcrumbTitle()
                            : Text(
                                _selectedIndex == 9 ? _settingsTitle : _getPageTitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (_selectedIndex == 8 ||
                                        (_selectedIndex == 1 &&
                                            (_inventoryTitle == 'Stock Ageing Report' ||
                                                _inventoryTitle == 'Inventory Analytics')) ||
                                        (_selectedIndex == 6 &&
                                            (_insightsSubSection == 'dead_stock' ||
                                                _insightsSubSection == 'forecast_accuracy' ||
                                                _insightsSubSection == 'forecasting')))
                                    ? GoogleFonts.inter(
                                        fontSize: context.isCompactDesktop ? 18 : 21,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF181614),
                                        letterSpacing: -0.3,
                                      )
                                    : GoogleFonts.cormorantGaramond(
                                        fontSize: context.isCompactDesktop ? 26 : 32,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF181614),
                                      ),
                              ),
                      ),
                      if (!(_selectedIndex == 9 && _settingsTitle.contains(' > '))) ...[
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 20,
                          color: const Color(0xFFDCD2C3),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ],
                    if (_selectedIndex == 9 &&
                        _settingsSection != 'system_settings' &&
                        _settingsSection != 'settings_search' &&
                        _settingsSection != 'data_retention' &&
                        _settingsSection != 'taxes_currency' &&
                        _settingsSection != 'documents_templates' &&
                        _settingsSection != 'team_directory' &&
                        _settingsSection != 'roles_permissions' &&
                        _settingsSection != 'edit_role' &&
                        _settingsSection != 'security_sso' &&
                        _settingsSection != 'security' &&
                        _settingsSection != 'sales_channels' &&
                        _settingsSection != 'integrations' &&
                        _settingsSection != 'shopify_connector' &&
                        _settingsSection != 'notification_settings' &&
                        _settingsSection != 'notifications_schema' &&
                        _settingsSection != 'barcode_printing' &&
                        _settingsSection != 'barcode' &&
                        _settingsSection != 'inventory_rules' &&
                        _settingsSection != 'rules' &&
                        _settingsSection != 'purchasing_defaults' &&
                        _settingsSection != 'purchasing' &&
                        _settingsSection != 'transfer_settings' &&
                        _settingsSection != 'transfer_defaults' &&
                        _settingsSection != 'import_export' &&
                        _settingsSection != 'import_export_studio' &&
                        _settingsSection != 'import_export_center' &&
                        _settingsSection != 'api_webhooks' &&
                        _settingsSection != 'webhooks' &&
                        _settingsSection != 'api' &&
                        _settingsSection != 'audit_log' &&
                        _settingsSection != 'system_audit_log' &&
                        _settingsSection != 'activity_logs' &&
                        !_settingsTitle.contains(' > '))
                      Flexible(
                        child: AtelierDropdown<String>(
                          value: _settingsSection,
                          isBorderless: true,
                          menuWidth: 260,
                          triggerLabel: (item) {
                            if (_settingsSection == 'system_settings') {
                              return 'Settings';
                            }
                            if (_settingsSection == 'add_location') {
                              return 'Settings → Locations → Add Location';
                            }
                            return 'Settings > ${item.title}';
                          },
                          items: const [
                            AtelierDropdownItem(
                              value: 'system_settings',
                              title: 'System Settings',
                              subtitle: 'Overview & Hub',
                              icon: Icons.settings_suggest_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'add_location',
                              title: 'Add Location',
                              subtitle: 'New Operational Node',
                              icon: Icons.add_business_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'locations',
                              title: 'Locations',
                              subtitle: 'Stores & Warehouses',
                              icon: Icons.storefront_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'business_profile',
                              title: 'Business Profile',
                              subtitle: 'Identity & Registry',
                              icon: Icons.business_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'taxes_currency',
                              title: 'Taxes & Currency',
                              subtitle: 'Fiscal & Localization',
                              icon: Icons.toll_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'documents_templates',
                              title: 'Document Settings',
                              subtitle: 'Sequences & PDF Layout',
                              icon: Icons.description_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'team_directory',
                              title: 'Team & Access',
                              subtitle: 'Staff & Roles',
                              icon: Icons.people_outline_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'roles_permissions',
                              title: 'Roles & Permissions',
                              subtitle: 'Access Matrix',
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'security_sso',
                              title: 'Security',
                              subtitle: 'SSO & Access Rules',
                              icon: Icons.security_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'sales_channels',
                              title: 'Sales Channels',
                              subtitle: 'Physical & Online POS',
                              icon: Icons.point_of_sale_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'integrations',
                              title: 'Integrations',
                              subtitle: 'APIs & Ecosystem',
                              icon: Icons.extension_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'notification_settings',
                              title: 'Notification Settings',
                              subtitle: 'Alerts & Channels',
                              icon: Icons.notifications_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'barcode_printing',
                              title: 'Barcode & Printing',
                              subtitle: 'Hardware & Labels',
                              icon: Icons.print_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'inventory_rules',
                              title: 'Inventory Rules',
                              subtitle: 'Thresholds & Reordering',
                              icon: Icons.inventory_2_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'purchasing_defaults',
                              title: 'Purchasing Defaults',
                              subtitle: 'Terms & Approvals',
                              icon: Icons.shopping_cart_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'transfer_settings',
                              title: 'Transfer Settings',
                              subtitle: 'Workflows & Transit',
                              icon: Icons.swap_horiz_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'import_export',
                              title: 'Import / Export Center',
                              subtitle: 'Data Hub & Logs',
                              icon: Icons.file_upload_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'api_webhooks',
                              title: 'API & Webhooks',
                              subtitle: 'Access & Endpoints',
                              icon: Icons.link_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'audit_log',
                              title: 'System Audit Log',
                              subtitle: 'Activity & Audit Trail',
                              icon: Icons.article_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'sync_queue',
                              title: 'System Integration Sync',
                              subtitle: 'Live Sync Queue & Jobs',
                              icon: Icons.sync_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'preferences',
                              title: 'Preferences',
                              subtitle: 'Theme & Language',
                              icon: Icons.grid_view_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'subscription',
                              title: 'Subscription & Plan',
                              subtitle: 'Tier & Entitlements',
                              icon: Icons.subtitles_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'billing',
                              title: 'Billing',
                              subtitle: 'Invoices & Payment',
                              icon: Icons.receipt_long_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'account',
                              title: 'Account',
                              subtitle: 'Profile & Security',
                              icon: Icons.person_outline_rounded,
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'account') {
                              setState(() => _selectedIndex = 10);
                            } else {
                              setState(() {
                                _settingsSection = val;
                                if (val == 'system_settings') {
                                  _settingsTitle = 'Settings';
                                  _settingsSubtitle = '';
                                } else if (val == 'add_location') {
                                  _settingsTitle = 'Add Location';
                                  _settingsSubtitle = 'Settings → Locations → Add Location';
                                } else if (val == 'locations') {
                                  _settingsTitle = 'Locations';
                                  _settingsSubtitle = 'Settings > Locations';
                                } else if (val == 'business_profile') {
                                  _settingsTitle = 'Business Profile';
                                  _settingsSubtitle = 'Settings > Business Profile';
                                } else if (val == 'taxes_currency') {
                                  _settingsTitle = 'Taxes & Currency';
                                  _settingsSubtitle =
                                      'Manage your default currency, display formats, tax profiles, and calculation rules.';
                                } else if (val == 'documents_templates') {
                                  _settingsTitle = 'Document Settings';
                                  _settingsSubtitle =
                                      'Configure document formats, serial numbers, and brand elements for system-generated and external PDFs.';
                                } else if (val == 'team_directory') {
                                  _settingsTitle = 'Team & Access';
                                  _settingsSubtitle =
                                      'Manage your team, node allocations, and access permissions.';
                                } else if (val == 'roles_permissions') {
                                  _settingsTitle = 'Roles & Permissions';
                                  _settingsSubtitle =
                                      'Manage workspace roles, permissions and granular system capabilities.';
                                } else if (val == 'security_sso' || val == 'security') {
                                  _settingsTitle = 'Settings > Security';
                                  _settingsSubtitle =
                                      'Enforce strong security policies, session handling and review active team session logs.';
                                } else if (val == 'sales_channels') {
                                  _settingsTitle = 'Settings > Sales Channels';
                                  _settingsSubtitle =
                                      'Connect, manage and configure active physical or digital checkout points of sale.';
                                } else if (val == 'integrations') {
                                  _settingsTitle = 'Settings > Integrations';
                                  _settingsSubtitle =
                                      'Link e-commerce channels, courier aggregators, and enterprise accounting software.';
                                } else if (val == 'notification_settings' ||
                                    val == 'notifications_schema') {
                                  _settingsTitle = 'Settings > Notification Settings';
                                  _settingsSubtitle =
                                      'Choose which alerts you wish to receive across each system channel.';
                                } else if (val == 'barcode_printing' ||
                                    val == 'barcode') {
                                  _settingsTitle = 'Settings > Barcode & Printing';
                                  _settingsSubtitle =
                                      'Configure barcode settings, manage printers and customize label templates.';
                                } else if (val == 'inventory_rules' ||
                                    val == 'rules') {
                                  _settingsTitle = 'Settings > Inventory Rules';
                                  _settingsSubtitle =
                                      'Define stock thresholds, reorder logic, and additional inventory rules for your business.';
                                } else if (val == 'purchasing_defaults' ||
                                    val == 'purchasing') {
                                  _settingsTitle =
                                      'Settings > Purchasing Defaults > Central Warehouse (Zone A)';
                                  _settingsSubtitle =
                                      'Configure buying, receiving and cost settings for your business.';
                                } else if (val == 'transfer_settings' ||
                                    val == 'transfer_defaults') {
                                  _settingsTitle =
                                      'Settings > Transfer Settings > Central Warehouse (Zone A)';
                                  _settingsSubtitle =
                                      'Configure stock transfer workflows, transit times and receiving preferences.';
                                } else if (val == 'import_export' ||
                                    val == 'import_export_studio' ||
                                    val == 'import_export_center') {
                                  _settingsTitle =
                                      'Settings > Import / Export Center > Central Warehouse (Zone A)';
                                  _settingsSubtitle =
                                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.';
                                } else if (val == 'api_webhooks' ||
                                    val == 'webhooks' ||
                                    val == 'api') {
                                  _settingsTitle =
                                      'Settings > API & Webhooks > Central Warehouse (Zone A)';
                                  _settingsSubtitle =
                                      'Manage API access, configure webhooks, and integrate with external systems.';
                                } else if (val == 'audit_log' ||
                                    val == 'system_audit_log' ||
                                    val == 'activity_logs') {
                                  _settingsTitle =
                                      'Settings > System Audit Log > Central Warehouse (Zone A)';
                                  _settingsSubtitle =
                                      'Track all system changes, user actions, and important events across ThreadStock.';
                                } else if (val == 'sync_queue' ||
                                    val == 'system_integration_sync') {
                                  _settingsTitle =
                                      'Sync Queue > System Status > Sync';
                                  _settingsSubtitle =
                                      'Monitor real-time data flows between ThreadStock and connected external integrations.';
                                } else if (val == 'preferences') {
                                  _settingsTitle = 'Preferences';
                                  _settingsSubtitle =
                                      'Tailor the interface and default configurations for Atelier OS';
                                } else if (val == 'subscription') {
                                  _settingsTitle = 'Subscription & Plan';
                                  _settingsSubtitle =
                                      'Manage billing cycles, system limits, and package upgrades.';
                                } else if (val == 'billing') {
                                  _settingsTitle = 'Billing';
                                  _settingsSubtitle =
                                      'Manage payment instruments, corporate GSTIN, and past statements.';
                                }
                              });
                            }
                          },
                        ),
                      )
                    else if (_selectedIndex == 10)
                      Flexible(
                        child: AtelierDropdown<String>(
                          value: 'account',
                          isBorderless: true,
                          menuWidth: 260,
                          triggerLabel: (_) => 'Settings → Account',
                          items: const [
                            AtelierDropdownItem(
                              value: 'account',
                              title: 'Settings → Account',
                              subtitle: 'Profile & Security',
                              icon: Icons.person_outline_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'preferences',
                              title: 'Settings → Preferences',
                              subtitle: 'Theme & Language',
                              icon: Icons.grid_view_rounded,
                            ),
                            AtelierDropdownItem(
                              value: 'subscription',
                              title: 'Settings → Plan',
                              subtitle: 'Subscription & Tier',
                              icon: Icons.subtitles_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'billing',
                              title: 'Settings → Billing',
                              subtitle: 'Invoices & Payment',
                              icon: Icons.receipt_long_outlined,
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'account') {
                              setState(() => _selectedIndex = 10);
                            } else {
                              setState(() => _selectedIndex = 9);
                            }
                          },
                        ),
                      )
                    else if (_selectedIndex == 8 &&
                        (_automationsTitle == 'Run History' ||
                            _automationsTitle.contains('RUN-1847') ||
                            _automationsTitle.contains('Failed')))
                      Flexible(
                        child: Text(
                          _automationsTitle.contains('RUN-1847')
                              ? 'Automations > Run History > RUN-1847'
                              : 'Automations > Run History',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: context.isCompactDesktop ? 13 : 14.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF355E82),
                          ),
                        ),
                      )
                    else if (!(_selectedIndex == 7) &&
                        !(_selectedIndex == 3 &&
                            (_purchasingTitle == 'Return to Supplier' ||
                                _purchasingTitle == 'POs / Returns')) &&
                        !(_selectedIndex == 4 &&
                            (_transfersTitle == 'New Stock Transfer' ||
                                _transfersTitle == 'TR-1042' ||
                                _transfersTitle == 'Active' ||
                                _transfersTitle == 'Transfer Order')) &&
                        !(_selectedIndex == 0 && _overviewTitle == 'Approval Center') &&
                        !(_selectedIndex == 9 && (_settingsSection == 'roles_permissions' || _settingsTitle == 'Roles & Permissions' || _settingsSection == 'team_directory' || _settingsTitle == 'Team & Access' || _settingsTitle.contains(' > '))) &&
                        !(_selectedIndex == 2 && _salesTitle == 'Sales Analytics') &&
                        !(_selectedIndex == 1 &&
                            (_inventoryTitle == 'Product details' ||
                                _inventoryTitle == 'Inventory' ||
                                _inventoryTitle == 'Variant Matrix Configurator' ||
                                _inventoryTitle == 'Create New Product' ||
                                _inventoryTitle == 'Stock Count Reconciliation' ||
                                _inventoryTitle == 'Active Stock Count' ||
                                _inventoryTitle == 'Labels' ||
                                _inventoryTitle == 'SoHo Flagship Store' ||
                                _inventoryTitle == 'Locations' ||
                                _inventoryTitle == 'Stock Ageing Report')) &&
                        !(_selectedIndex == 6 &&
                            (_insightsSubSection == 'restock_recommendation' ||
                                _insightsSubSection == 'anomaly_center' ||
                                _insightsSubSection == 'anomalies' ||
                                _insightsSubSection == 'profitability' ||
                                _insightsSubSection == 'locations' ||
                                _insightsSubSection == 'suppliers' ||
                                _insightsSubSection == 'forecast_accuracy' ||
                                _insightsSubSection == 'dead_stock')))
                      Flexible(
                        child: AtelierDropdown<String>(
                          value: _selectedLocation,
                          isBorderless: true,
                          menuWidth: 260,
                          triggerLabel: (item) => context.isCompactDesktop
                              ? item.title
                              : (item.subtitle != null && item.subtitle!.isNotEmpty
                                  ? '${item.title} (${item.subtitle})'
                                  : item.title),
                          items: const [
                            AtelierDropdownItem(
                              value: 'central_warehouse',
                              title: 'Central Warehouse',
                              subtitle: 'Zone A',
                              icon: Icons.warehouse_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'delhi_flagship',
                              title: 'Delhi Flagship',
                              subtitle: 'Zone B',
                              icon: Icons.storefront_outlined,
                            ),
                            AtelierDropdownItem(
                              value: 'mumbai_boutique',
                              title: 'Mumbai Boutique',
                              subtitle: 'Zone C',
                              icon: Icons.storefront_outlined,
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedLocation = val);
                          },
                          footerAction: AtelierDropdownAction(
                            label: 'Manage locations',
                            icon: Icons.settings_outlined,
                            onTap: () {
                              setState(() => _selectedIndex = 9);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Right: Search Bar + Atelier AI Button + Notification
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar with ⌘ K badge
                  InkWell(
                    onTap: _openCommandPalette,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: context.isCompactDesktop ? 220 : 290,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF8C8478)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              controller: (_selectedIndex == 9 && _settingsSection == 'settings_search')
                                  ? TextEditingController(text: 'tax')
                                  : null,
                              onTap: _openCommandPalette,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF181513),
                              ),
                              decoration: InputDecoration(
                                hintText: _getSearchHint(),
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9E958A),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_selectedIndex == 9 && _settingsSection == 'settings_search')
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _settingsSection = 'system_settings';
                                  _settingsTitle = 'System Settings';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: Color(0xFF7A7267),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: _openCommandPalette,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3ECE1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFDCCFBD)),
                                ),
                                child: Text(
                                  '⌘ K',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7A7267),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Dark Mode / Theme Toggle
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: const Icon(
                        Icons.dark_mode_outlined,
                        size: 18,
                        color: Color(0xFF3A352F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ThreadStock / Atelier AI Action Button
                  Container(
                    height: 38,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.isCompactDesktop ? 10 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EFE4).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDECDB9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_outlined, size: 16, color: Color(0xFFBA8A55)),
                        const SizedBox(width: 6),
                        Text(
                          context.isCompactDesktop
                              ? 'AI'
                              : (_selectedIndex == 7 &&
                                      (_aiStudioSubSection == 'demand_forecast' ||
                                          _aiStudioTitle == 'Demand Forecast' ||
                                          _aiStudioSubSection == 'ai_history' ||
                                          _aiStudioTitle == 'AI History' ||
                                          _aiStudioSubSection == 'ai_actions' ||
                                          _aiStudioSubSection == 'proposal_detail' ||
                                          _aiStudioTitle == 'Proposal Detail' ||
                                          _aiStudioTitle == 'AI Actions' ||
                                          _aiStudioTitle == 'AI Studio')
                                  ? 'AI Studio Active'
                                  : (_selectedIndex == 6 &&
                                          (_insightsSubSection == 'profitability' ||
                                              _insightsSubSection == 'locations' ||
                                              _insightsSubSection == 'suppliers' ||
                                              _insightsSubSection == 'forecast_accuracy')
                                      ? 'AI Agent'
                                      : (_selectedIndex == 9 ? 'Atelier AI' : 'ThreadStock AI'))),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (_selectedIndex == 6 &&
                                    (_insightsSubSection == 'profitability' ||
                                        _insightsSubSection == 'locations' ||
                                        _insightsSubSection == 'suppliers' ||
                                        _insightsSubSection == 'forecast_accuracy'))
                                ? const Color(0xFF1E1C1A)
                                : const Color(0xFF946A36),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                    // Bell Notification Icon with Toggle & Unread Dot
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isActivityDrawerOpen = !_isActivityDrawerOpen;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isActivityDrawerOpen
                              ? const Color(0xFFF3ECE2)
                              : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isActivityDrawerOpen
                                ? const Color(0xFFBA8A55)
                                : const Color(0xFFDFD4C5),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 18,
                              color: Color(0xFF3A352F),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBA8A55),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!(_selectedIndex == 2 && _salesTitle == 'Sales Analytics') &&
                        !(_selectedIndex == 1 && _inventoryTitle == 'Inventory Analytics')) ...[
                      const SizedBox(width: 10),

                      // User Profile Avatar & Switch Business Popup
                      PopupMenuButton<String>(
                      tooltip: 'Alex Mercer • Workspace',
                      offset: const Offset(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEADBCA), width: 1),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      onSelected: (val) {
                        if (val == 'switch_business') {
                          SwitchBusinessDialog.show(context);
                        } else if (val == 'profile') {
                          setState(() => _selectedIndex = 10);
                        } else if (val == 'shortcuts') {
                          KeyboardShortcutsDialog.show(context);
                        } else if (val == 'sign_out') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Signed out from Central Admin session.',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              backgroundColor: const Color(0xFF1E1C1A),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'switch_business',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(Icons.apartment_rounded, size: 17, color: Color(0xFF8D6433)),
                              const SizedBox(width: 10),
                              Text(
                                'Switch Business',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'profile',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 17, color: Color(0xFF5E574E)),
                              const SizedBox(width: 10),
                              Text(
                                'My Profile',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'shortcuts',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(Icons.keyboard_outlined, size: 17, color: Color(0xFF5E574E)),
                              const SizedBox(width: 10),
                              Text(
                                'Keyboard Shortcuts',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'sign_out',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 17, color: Color(0xFF9E4738)),
                              const SizedBox(width: 10),
                              Text(
                                'Sign Out',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9E4738),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ((_selectedIndex == 6 &&
                                        (_insightsSubSection == 'anomaly_center' ||
                                            _insightsSubSection == 'anomalies' ||
                                            _insightsSubSection == 'locations' ||
                                            _insightsSubSection == 'profitability' ||
                                            _insightsSubSection == 'suppliers' ||
                                            _insightsSubSection == 'forecast_accuracy' ||
                                            _insightsSubSection == 'dead_stock')) ||
                                    (_selectedIndex == 1 &&
                                        _inventoryTitle == 'Stock Ageing Report') ||
                                    (_selectedIndex == 0 &&
                                        _overviewTitle == 'Approval Center') ||
                                    (_selectedIndex == 8 ||
                                    _selectedIndex == 7))
                                ? Colors.white.withOpacity(0.85)
                                : const Color(0xFF1E1C1A),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: const Color(0xFFDFD4C5), width: 1),
                          ),
                          child: ((_selectedIndex == 6 &&
                                      (_insightsSubSection == 'anomaly_center' ||
                                          _insightsSubSection == 'anomalies' ||
                                          _insightsSubSection == 'locations' ||
                                          _insightsSubSection == 'profitability' ||
                                          _insightsSubSection == 'suppliers' ||
                                          _insightsSubSection == 'forecast_accuracy' ||
                                          _insightsSubSection == 'dead_stock')) ||
                                  (_selectedIndex == 1 &&
                                      _inventoryTitle == 'Stock Ageing Report') ||
                                  (_selectedIndex == 0 &&
                                      _overviewTitle == 'Approval Center') ||
                                  (_selectedIndex == 8 ||
                                  _selectedIndex == 7))
                              ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 19,
                                  color: Color(0xFF3A352F),
                                )
                              : Image.asset(
                                  'Assets/alex_mercer.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(
                                      'AM',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return _overviewTitle;
      case 1:
        return _inventoryTitle;
      case 2:
        return _salesTitle;
      case 3:
        return _purchasingTitle;
      case 4:
        return 'Transfers';
      case 5:
        return 'Suppliers';
      case 6:
        return _insightsTitle;
      case 7:
        return _aiStudioTitle;
      case 8:
        return _automationsTitle;
      case 9:
        return 'Settings';
      case 10:
        return 'My Profile';
      case 11:
        return 'Catalog Manager';
      case 12:
        return 'Collections';
      case 13:
        return 'Brands';
      case 14:
        return 'Attributes';
      default:
        return 'Operational Overview';
    }
  }

  Widget _buildSettingsBreadcrumbTitle() {
    final parts = _settingsTitle.split(' > ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '›',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E958A),
                ),
              ),
            ),
          ],
          InkWell(
            onTap: () {
              if (i == 0) {
                if (parts[0] == 'Integrations') {
                  setState(() {
                    _settingsSection = 'integrations';
                    _settingsTitle = 'Settings > Integrations';
                    _settingsSubtitle =
                        'Link e-commerce channels, courier aggregators, and enterprise accounting software.';
                  });
                } else {
                  setState(() {
                    _settingsSection = 'system_settings';
                    _settingsTitle = 'Settings';
                    _settingsSubtitle = '';
                  });
                }
              } else if (i == 1 && parts[1] == 'System Status') {
                setState(() {
                  _settingsSection = 'system_settings';
                  _settingsTitle = 'Settings';
                  _settingsSubtitle = '';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Roles' || parts[1] == 'Roles & Permissions')) {
                setState(() {
                  _settingsSection = 'roles_permissions';
                  _settingsTitle = 'Roles & Permissions';
                  _settingsSubtitle =
                      'Manage workspace roles, permissions and granular system capabilities.';
                });
              } else if (i == 1 && parts[1] == 'Sales Channels') {
                setState(() {
                  _settingsSection = 'sales_channels';
                  _settingsTitle = 'Settings > Sales Channels';
                  _settingsSubtitle =
                      'Connect, manage and configure active physical or digital checkout points of sale.';
                });
              } else if (i == 1 && parts[1] == 'Integrations') {
                setState(() {
                  _settingsSection = 'integrations';
                  _settingsTitle = 'Settings > Integrations';
                  _settingsSubtitle =
                      'Link e-commerce channels, courier aggregators, and enterprise accounting software.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Notification Settings' ||
                      parts[1] == 'Notifications Schema' ||
                      parts[1] == 'Notification Preferences')) {
                setState(() {
                  _settingsSection = 'notification_settings';
                  _settingsTitle = 'Settings > Notification Settings';
                  _settingsSubtitle =
                      'Choose which alerts you wish to receive across each system channel.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Barcode & Printing' ||
                      parts[1] == 'Barcode')) {
                setState(() {
                  _settingsSection = 'barcode_printing';
                  _settingsTitle = 'Settings > Barcode & Printing';
                  _settingsSubtitle =
                      'Configure barcode settings, manage printers and customize label templates.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Inventory Rules' ||
                      parts[1] == 'Rules')) {
                setState(() {
                  _settingsSection = 'inventory_rules';
                  _settingsTitle = 'Settings > Inventory Rules';
                  _settingsSubtitle =
                      'Define stock thresholds, reorder logic, and additional inventory rules for your business.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Purchasing Defaults' ||
                      parts[1] == 'Purchasing')) {
                setState(() {
                  _settingsSection = 'purchasing_defaults';
                  _settingsTitle =
                      'Settings > Purchasing Defaults > Central Warehouse (Zone A)';
                  _settingsSubtitle =
                      'Configure buying, receiving and cost settings for your business.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Transfer Settings' ||
                      parts[1] == 'Transfers')) {
                setState(() {
                  _settingsSection = 'transfer_settings';
                  _settingsTitle =
                      'Settings > Transfer Settings > Central Warehouse (Zone A)';
                  _settingsSubtitle =
                      'Configure stock transfer workflows, transit times and receiving preferences.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'Import / Export Center' ||
                      parts[1] == 'Import / Export' ||
                      parts[1] == 'Import/Export Studio')) {
                setState(() {
                  _settingsSection = 'import_export';
                  _settingsTitle =
                      'Settings > Import / Export Center > Central Warehouse (Zone A)';
                  _settingsSubtitle =
                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'API & Webhooks' ||
                      parts[1] == 'Webhooks' ||
                      parts[1] == 'API')) {
                setState(() {
                  _settingsSection = 'api_webhooks';
                  _settingsTitle =
                      'Settings > API & Webhooks > Central Warehouse (Zone A)';
                  _settingsSubtitle =
                      'Manage API access, configure webhooks, and integrate with external systems.';
                });
              } else if (i == 1 &&
                  (parts[1] == 'System Audit Log' ||
                      parts[1] == 'Audit Log' ||
                      parts[1] == 'Activity Logs')) {
                setState(() {
                  _settingsSection = 'audit_log';
                  _settingsTitle =
                      'Settings > System Audit Log > Central Warehouse (Zone A)';
                  _settingsSubtitle =
                      'Track all system changes, user actions, and important events across ThreadStock.';
                });
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    parts[i],
                    style: i == parts.length - 1
                        ? GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181614),
                          )
                        : GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF7E766B),
                          ),
                  ),
                  if (i == parts.length - 1 &&
                      (parts[i] == 'Notification Settings' ||
                          parts[i] == 'Notifications Schema' ||
                          parts[i] == 'Notification Preferences' ||
                          parts[i] == 'Barcode & Printing' ||
                          parts[i] == 'Barcode' ||
                          parts[i] == 'Inventory Rules' ||
                          parts[i] == 'Rules' ||
                          parts[i] == 'Central Warehouse (Zone A)' ||
                          parts[i].contains('Warehouse') ||
                          parts[i].contains('Purchasing Defaults') ||
                          parts[i].contains('Transfer Settings') ||
                          parts[i].contains('Import / Export') ||
                          parts[i].contains('API & Webhooks') ||
                          parts[i].contains('Audit Log') ||
                          parts[i].contains('Sync'))) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF181614),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
