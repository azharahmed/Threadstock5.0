// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/approval_center_view.dart';
import '../../../../core/responsive/desktop_layout.dart';
import '../../../../core/business/current_business_service.dart';
import '../../../inventory/data/location_repository.dart';
import '../../../inventory/data/supplier_repository.dart';
import '../../../inventory/domain/inventory_change_notifier.dart';
import '../../../inventory/presentation/widgets/stock_adjustment_view.dart';
import '../../../sales/data/sales_repository.dart';
import '../../data/dashboard_repository.dart';
import '../widgets/live_dashboard_header.dart';

enum OverviewPageMode { approvalCenter, operationalOverview }

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    this.initialMode = OverviewPageMode.operationalOverview,
    this.autoShowSessionExpired = false,
    this.autoShowSwitchBusiness = false,
    this.onNavigateToIndex,
    this.onNavigateToSection,
    this.onTitleChanged,
    this.dashboardRepository,
  });

  final OverviewPageMode initialMode;
  final bool autoShowSessionExpired;
  final bool autoShowSwitchBusiness;
  final ValueChanged<int>? onNavigateToIndex;
  final void Function(int index, {String? title, String? subSection})? onNavigateToSection;
  final ValueChanged<String>? onTitleChanged;
  final DashboardRepository? dashboardRepository;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late OverviewPageMode _mode;
  String _selectedChartTab = '7D';

  late final DashboardRepository _dashboardRepository;
  DashboardData _dashboardData = const DashboardData();
  bool _isLoading = true;
  bool _isFetching = false;
  bool _hasPendingReload = false;
  bool _hasZeroLocations = false;
  bool _supplierSkipped = false;
  final LocationRepository _locationRepository = LocationRepository();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _dashboardRepository = widget.dashboardRepository ?? DashboardRepository();

    CurrentBusinessService.instance.addListener(_onStateChanged);
    InventoryChangeNotifier.instance.addListener(_onStateChanged);
    CustomerChangeNotifier.instance.addListener(_onStateChanged);

    if (_mode == OverviewPageMode.approvalCenter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onTitleChanged?.call('Approval Center');
        }
      });
    }

    _loadDashboardData();
  }

  @override
  void dispose() {
    CurrentBusinessService.instance.removeListener(_onStateChanged);
    InventoryChangeNotifier.instance.removeListener(_onStateChanged);
    CustomerChangeNotifier.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (_isFetching) {
      _hasPendingReload = true;
      return;
    }
    _isFetching = true;
    try {
      final bizId = CurrentBusinessService.instance.currentBusinessId;
      if (widget.dashboardRepository == null) {
        final locations = await _locationRepository.getLocations(
          businessId: bizId,
          onlyActive: true,
        );

        if (locations.isEmpty) {
          if (mounted) {
            setState(() {
              _hasZeroLocations = true;
              _isLoading = false;
            });
          }
          return;
        }
      }

      _hasZeroLocations = false;
      _dashboardRepository.locationId =
          CurrentBusinessService.instance.currentLocationId;
      _dashboardRepository.chartRange = _selectedChartTab;
      final data = await _dashboardRepository.fetchDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
      if (_hasPendingReload) {
        _hasPendingReload = false;
        _loadDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == OverviewPageMode.approvalCenter) {
      return ApprovalCenterView(
        onViewOperationalOverview: () {
          setState(() {
            _mode = OverviewPageMode.operationalOverview;
            widget.onTitleChanged?.call('Overview');
          });
        },
      );
    }

    if (_hasZeroLocations) {
      return _buildZeroLocationsView();
    }

    final isFresh = _dashboardData.isFreshWorkspace;

    return SingleChildScrollView(
      child: DesktopContentConstraint(
        verticalPadding: 24,
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFC5A059),
                      ),
                    ),
                  ),
                ),
              )
            : (isFresh
                ? _buildFreshWorkspaceView()
                : _buildMatureOperationalView()),
      ),
    );
  }

  Widget _buildFreshWorkspaceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Fresh Hero
        _buildFreshHero(),
        const SizedBox(height: 24),

        // 2. Getting Started Checklist Panel
        _buildGettingStartedPanel(),
        const SizedBox(height: 20),

        // 3. Compact Status Summary
        _buildCompactStatusSummary(),
      ],
    );
  }

  Widget _buildMatureOperationalView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Greeting Section
        _buildGreetingRow(),
        const SizedBox(height: 20),

        // 2. 4 KPI Metrics Cards
        _buildKpiRow(),
        const SizedBox(height: 20),

        // 3. Middle Section: Recent Activity & Sales Trend Chart
        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 980;
            if (isStacked) {
              return Column(
                children: [
                  _buildRecentActivityCard(),
                  const SizedBox(height: 20),
                  _buildSalesTrendCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Recent Activity (~32%)
                Expanded(flex: 4, child: _buildRecentActivityCard()),
                const SizedBox(width: 20),

                // Right Column: Sales Trend Chart (~68%)
                Expanded(flex: 7, child: _buildSalesTrendCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 4. Bottom Row: Top Categories + Stock Health + AI Insight
        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 1100;
            if (isStacked) {
              return Column(
                children: [
                  _buildTopCategoriesCard(),
                  const SizedBox(height: 20),
                  _buildStockHealthCard(),
                  const SizedBox(height: 20),
                  _buildAiInsightCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildTopCategoriesCard()),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: _buildStockHealthCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildAiInsightCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildZeroLocationsView() {
    return SingleChildScrollView(
      child: DesktopContentConstraint(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingRow(),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5DACD)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F1E5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBA8A55).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFFBA8A55),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No location configured',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first location to start inventory and sales.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B655B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddLocationDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Add Location',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1C1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDevDiagnostics(),
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    String locationType = 'Retail Store';
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Location',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location Name *',
                      hintText: 'e.g. Flagship Boutique',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: locationType,
                    decoration: const InputDecoration(
                      labelText: 'Location Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Retail Store', child: Text('Retail Store')),
                      DropdownMenuItem(value: 'Warehouse', child: Text('Warehouse')),
                      DropdownMenuItem(value: 'Showroom', child: Text('Showroom')),
                      DropdownMenuItem(value: 'Office', child: Text('Office')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => locationType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      hintText: 'Street address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: postalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  setDialogState(() => dialogError = 'Enter a location name.');
                                  return;
                                }
                                setDialogState(() {
                                  isSaving = true;
                                  dialogError = null;
                                });
                                try {
                                  final bizId = CurrentBusinessService.instance.currentBusinessId;
                                  final created = await _locationRepository.createLocation(
                                    name: name,
                                    locationType: locationType,
                                    streetAddress: streetCtrl.text.trim(),
                                    city: cityCtrl.text.trim(),
                                    postalCode: postalCtrl.text.trim(),
                                    businessId: bizId,
                                  );
                                  CurrentBusinessService.instance.setCurrentLocationId(created.id);
                                  if (context.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                    _loadDashboardData();
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isSaving = false;
                                    dialogError = 'Could not save location: $e';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1C1A),
                          foregroundColor: Colors.white,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Location'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevDiagnostics() {
    return const SizedBox.shrink();
  }

  // ===========================================================================
  // FRESH WORKSPACE GETTING STARTED COMPONENTS
  // ===========================================================================
  int get _completedSetupSteps {
    int count = 1; // Step 0: Business & location setup
    if (_dashboardData.hasProducts) count++;
    if (_dashboardData.hasStock) count++;
    if (_dashboardData.hasCompletedSale) count++;
    return count;
  }

  Widget _buildFreshHero() {
    final biz = CurrentBusinessService.instance.currentBusiness?.legalName.trim();
    final bizName = (biz != null && biz.isNotEmpty) ? biz : 'LaunchGrid';

    return LiveDashboardHeader(
      userName: _dashboardData.userName,
      businessName: bizName,
      locationName: _dashboardData.locationName,
      locationOffset: _dashboardData.timezoneOffset,
      locationTimezone: _dashboardData.timezone,
      isFreshMode: true,
    );
  }

  Widget _buildGettingStartedPanel() {
    final completed = _completedSetupSteps;
    final hasProducts = _dashboardData.hasProducts;
    final hasStock = _dashboardData.hasStock;
    final hasSale = _dashboardData.hasCompletedSale;
    final hasSuppliers = _dashboardData.hasSuppliers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E2D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            'GET STARTED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFFBA8A55),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Get started with ThreadStock',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
              Text(
                'Store setup  •  $completed of 4 ready',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8C7B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Complete these steps to start managing stock and making sales.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF6B655B),
            ),
          ),
          const SizedBox(height: 16),

          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: completed / 4.0,
              minHeight: 4,
              backgroundColor: const Color(0xFFEFE9DF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA8A55)),
            ),
          ),
          const SizedBox(height: 24),

          // Step 0: Business & location setup
          _buildChecklistRow(
            isDone: true,
            stepNumber: 0,
            title: 'Business & location setup',
            subtitle: 'Store location and currency configured.',
          ),
          _buildStepDivider(),

          // Step 1: Add your first product
          _buildChecklistRow(
            isDone: hasProducts,
            isActive: !hasProducts,
            stepNumber: 1,
            title: 'Add your first product',
            subtitle: hasProducts
                ? '${_dashboardData.totalProductsCount} product${_dashboardData.totalProductsCount == 1 ? '' : 's'} created.'
                : 'Create a product, price it and add variants.',
            action: !hasProducts
                ? ElevatedButton(
                    key: const ValueKey('fresh_setup_add_product_button'),
                    style: _primaryStepButtonStyle(),
                    onPressed: _handleAddProduct,
                    child: const Text('Add Product'),
                  )
                : null,
          ),
          _buildStepDivider(),

          // Step 2: Add stock
          _buildChecklistRow(
            isDone: hasStock,
            isActive: hasProducts && !hasStock,
            stepNumber: 2,
            title: 'Add stock',
            subtitle: hasStock
                ? '${_dashboardData.totalStockCount} units recorded in inventory.'
                : 'Record opening inventory for your product.',
            action: (hasProducts && !hasStock)
                ? ElevatedButton(
                    key: const ValueKey('fresh_setup_add_stock_button'),
                    style: _primaryStepButtonStyle(),
                    onPressed: _handleAddStock,
                    child: const Text('Add Stock'),
                  )
                : null,
          ),
          _buildStepDivider(),

          // Step 3: Add a supplier (Optional)
          _buildChecklistRow(
            isDone: hasSuppliers || _supplierSkipped,
            stepNumber: 3,
            isOptional: true,
            title: 'Add a supplier',
            subtitle: hasSuppliers
                ? '${_dashboardData.supplierCount} supplier connected.'
                : (_supplierSkipped
                    ? 'Optional step skipped.'
                    : 'Optional — connect a supplier for purchasing.'),
            action: (!hasSuppliers && !_supplierSkipped)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        key: const ValueKey('fresh_setup_add_supplier_button'),
                        style: _secondaryStepButtonStyle(),
                        onPressed: _handleAddSupplier,
                        child: const Text('Add Supplier'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        key: const ValueKey('fresh_setup_skip_supplier_button'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8C7B6B),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => setState(() => _supplierSkipped = true),
                        child: const Text('Skip'),
                      ),
                    ],
                  )
                : null,
          ),
          _buildStepDivider(),

          // Step 4: Make your first sale
          _buildChecklistRow(
            isDone: hasSale,
            isActive: hasStock && !hasSale,
            stepNumber: 4,
            title: 'Make your first sale',
            subtitle: hasSale
                ? 'First transaction completed.'
                : 'Open Sales and complete your first transaction.',
            action: (hasStock && !hasSale)
                ? ElevatedButton(
                    key: const ValueKey('fresh_setup_start_sale_button'),
                    style: _primaryStepButtonStyle(),
                    onPressed: _handleStartSale,
                    child: const Text('Start a Sale'),
                  )
                : (!hasSale && !hasStock
                    ? OutlinedButton(
                        key: const ValueKey('fresh_setup_start_sale_button'),
                        style: _mutedStepButtonStyle(),
                        onPressed: _handleStartSale,
                        child: const Text('Start a Sale'),
                      )
                    : null),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow({
    required bool isDone,
    bool isActive = false,
    bool isOptional = false,
    required int stepNumber,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    Widget indicator;
    if (isDone) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFD1FAE5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 16,
          color: Color(0xFF059669),
        ),
      );
    } else if (isActive) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1C1A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNumber',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2DACF)),
        ),
        alignment: Alignment.center,
        child: Text(
          stepNumber == 0 ? '✓' : '$stepNumber',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8C7B6B),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indicator,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: isDone
                            ? FontWeight.w500
                            : (isActive ? FontWeight.w700 : FontWeight.w600),
                        color: isDone
                            ? const Color(0xFF1E1C1A)
                            : (isActive
                                ? const Color(0xFF1E1C1A)
                                : const Color(0xFF5E574E)),
                      ),
                    ),
                    if (isOptional && !isDone) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFE6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Optional',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8C7B6B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF8C7B6B),
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return const Divider(height: 1, color: Color(0xFFF0EBE1));
  }

  ButtonStyle _primaryStepButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E1C1A),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _secondaryStepButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1E1C1A),
      side: const BorderSide(color: Color(0xFFD5CDC2)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _mutedStepButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF8C7B6B),
      side: const BorderSide(color: Color(0xFFE2DACF)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCompactStatusSummary() {
    final sym = _dashboardData.currencySymbol;
    final salesCents = _dashboardData.todaySalesCents;
    final salesFormatted = '$sym${(salesCents / 100).toStringAsFixed(0)}';
    final totalStock = _dashboardData.totalStockCount;
    final totalProducts = _dashboardData.totalProductsCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBE4D8)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statusSummaryItem('Products', '$totalProducts'),
          Container(width: 1, height: 14, color: const Color(0xFFDFD7CA)),
          _statusSummaryItem('Stock', '$totalStock'),
          Container(width: 1, height: 14, color: const Color(0xFFDFD7CA)),
          _statusSummaryItem('Sales', salesFormatted),
        ],
      ),
    );
  }

  Widget _statusSummaryItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C7B6B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }

  void _handleAddProduct() {
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(1, title: 'Add Product');
    } else {
      widget.onNavigateToIndex?.call(1);
    }
  }

  void _handleAddStock() {
    if (_dashboardData.totalProductsCount == 1) {
      _openStockAdjustmentDialog(_dashboardData.firstProductId);
    } else {
      if (widget.onNavigateToSection != null) {
        widget.onNavigateToSection!(1, title: 'Inventory');
      } else {
        widget.onNavigateToIndex?.call(1);
      }
    }
  }

  void _openStockAdjustmentDialog(String? productId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
          child: StockAdjustmentView(
            initialProductId: productId,
            initialAdjustmentType: StockAdjustmentType.add,
            onAdjustStockCompleted: () {
              Navigator.of(ctx).pop();
              _loadDashboardData();
            },
          ),
        ),
      ),
    );
  }

  void _handleAddSupplier() {
    _showAddSupplierDialog();
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Add Supplier',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('supplier_name_input'),
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Supplier Name *',
                    hintText: 'e.g. Acme Fabrics Ltd.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    hintText: 'orders@acmefabrics.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    hintText: '+91 98765 43210',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('save_supplier_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await SupplierRepository().createSupplier(
                          name: name,
                          contactEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _loadDashboardData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error saving supplier: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Supplier'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStartSale() {
    if (!_dashboardData.hasStock) {
      _showAddStockRequiredNotice();
      return;
    }
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(2, title: 'New Sale', subSection: 'newSale');
    } else {
      widget.onNavigateToIndex?.call(2);
    }
  }

  void _showAddStockRequiredNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFBA8A55), size: 22),
            const SizedBox(width: 8),
            Text(
              'Stock Required',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1C1A),
              ),
            ),
          ],
        ),
        content: Text(
          'Add stock before starting a sale.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5E574E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('notice_add_stock_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleAddStock();
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. GREETING ROW
  // ===========================================================================
  Widget _buildGreetingRow() {
    final biz = CurrentBusinessService.instance.currentBusiness?.legalName.trim();
    final bizName = (biz != null && biz.isNotEmpty) ? biz : 'LaunchGrid';

    return LiveDashboardHeader(
      userName: _dashboardData.userName,
      businessName: bizName,
      locationName: _dashboardData.locationName,
      locationOffset: _dashboardData.timezoneOffset,
      locationTimezone: _dashboardData.timezone,
      isFreshMode: false,
    );
  }

  // ===========================================================================
  // 2. 4 KPI METRICS ROW
  // ===========================================================================
  Widget _buildKpiRow() {
    final sym = _dashboardData.currencySymbol;
    final salesCents = _dashboardData.todaySalesCents;
    final salesFormatted = '$sym${(salesCents / 100).toStringAsFixed(0)}';
    final totalStock = _dashboardData.totalStockCount;
    final lowStock = _dashboardData.lowStockCount;
    final pendingTransfers = _dashboardData.resolvedPendingTransfers;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            children: [
              _buildKpiCard(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFD1FAE5),
                title: "Today's Sales",
                value: salesFormatted,
                tooltip: 'Sum of completed sales for today at the selected business/location.',
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Total Stock',
                value: '$totalStock',
                tooltip: 'Sellable units currently available across tracked inventory.',
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Low-Stock SKUs',
                value: '$lowStock SKUs',
                tooltip: 'Tracked SKUs at or below their configured low-stock threshold.',
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Pending Transfers',
                value: pendingTransfers,
                tooltip: 'Transfers awaiting completion.',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFD1FAE5),
                title: "Today's Sales",
                value: salesFormatted,
                tooltip: 'Sum of completed sales for today at the selected business/location.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Total Stock',
                value: '$totalStock',
                tooltip: 'Sellable units currently available across tracked inventory.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Low-Stock SKUs',
                value: '$lowStock SKUs',
                tooltip: 'Tracked SKUs at or below their configured low-stock threshold.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Pending Transfers',
                value: pendingTransfers,
                tooltip: 'Transfers awaiting completion.',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    String? tooltip,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, size: 20, color: iconColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor ?? const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      card = Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        showDuration: const Duration(seconds: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: card,
      );
    }

    return card;
  }

  // ===========================================================================
  // 3. RECENT ACTIVITY CARD (Left Column)
  // ===========================================================================
  Widget _buildRecentActivityCard() {
    final activities = _dashboardData.recentActivities;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF8F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 22,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Activity will appear here as you add products, make sales, receive stock and transfer inventory.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: activities.map((act) {
                return _buildActivityItem(
                  icon: act['icon'] as IconData? ?? Icons.inventory_2_outlined,
                  iconColor:
                      act['iconColor'] as Color? ?? const Color(0xFF059669),
                  iconBg: act['iconBg'] as Color? ?? const Color(0xFFD1FAE5),
                  title: act['title'] as String? ?? '',
                  subtitle: act['subtitle'] as String?,
                  detail: act['detail'] as String?,
                  time: act['time'] as String? ?? '',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? detail,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, size: 16, color: iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. SALES TREND CHART CARD (Right Column)
  // ===========================================================================
  Widget _buildSalesTrendCard() {
    final hasSales = _dashboardData.hasSalesData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Trend',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Row(
                children: ['7D', '30D', '90D'].map((tab) {
                  final isSelected = tab == _selectedChartTab;
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      if (_selectedChartTab != tab) {
                        setState(() {
                          _selectedChartTab = tab;
                        });
                        _loadDashboardData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF1F5F9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasSales)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF8F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        size: 22,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sales data yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sales trends will populate as transactions occur.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 170,
              width: double.infinity,
              child: CustomPaint(
                painter: _SalesChartPainter(
                  points: _dashboardData.salesTrend,
                  currencySymbol: _dashboardData.currencySymbol,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildChartLabels(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildChartLabels() {
    final trend = _dashboardData.salesTrend;
    if (trend.isEmpty) return const [];

    List<String> labels;
    if (trend.length <= 7) {
      labels = trend.map((p) => p['date'] as String? ?? '').toList();
    } else {
      const int targetCount = 7;
      final step = (trend.length - 1) / (targetCount - 1);
      labels = [
        for (int i = 0; i < targetCount; i++)
          trend[(i * step).round()]['date'] as String? ?? '',
      ];
    }

    return labels.map((day) {
      return Text(
        day,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w400,
        ),
      );
    }).toList();
  }

  // ===========================================================================
  // 5. BOTTOM ROW CARDS
  // ===========================================================================
  Widget _buildTopCategoriesCard() {
    final categories = _dashboardData.topCategories;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF8F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 20,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No category data yet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Categories will appear here once products are added to your catalog.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _CategoryDonutPainter(),
                    child: Center(
                      child: Text(
                        '${categories.length}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.take(4).map((c) {
                      return _buildCategoryLegendItem(
                        c['name'] as String? ?? '',
                        c['percent'] as String? ?? '0%',
                        const Color(0xFFD97706),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegendItem(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            percent,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHealthCard() {
    final hasInventory = _dashboardData.hasInventory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Health',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          if (!hasInventory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF8F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No inventory data yet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Stock health metrics will update as inventory is received.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildHealthBar(
              'In Stock',
              _dashboardData.stockHealth['inStock'] ?? 0,
              _dashboardData.stockHealthPercentages['inStock'] ?? (hasInventory ? '100%' : '0%'),
              _dashboardData.stockHealthRatios['inStock'] ?? (hasInventory ? 1.0 : 0.0),
              const Color(0xFF047857),
            ),
            const SizedBox(height: 10),
            _buildHealthBar(
              'Low Stock',
              _dashboardData.stockHealth['lowStock'] ?? 0,
              _dashboardData.stockHealthPercentages['lowStock'] ?? '0%',
              _dashboardData.stockHealthRatios['lowStock'] ?? 0.0,
              const Color(0xFFD97706),
            ),
            const SizedBox(height: 10),
            _buildHealthBar(
              'Out of Stock',
              _dashboardData.stockHealth['outOfStock'] ?? 0,
              _dashboardData.stockHealthPercentages['outOfStock'] ?? '0%',
              _dashboardData.stockHealthRatios['outOfStock'] ?? 0.0,
              const Color(0xFFDC2626),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthBar(
    String label,
    int count,
    String percent,
    double ratio,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            percent,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightCard() {
    final hasRealInsight =
        _dashboardData.aiInsight != null &&
        _dashboardData.aiInsight!.isNotEmpty;
    final insightText = hasRealInsight
        ? _dashboardData.aiInsight!
        : 'Insights will appear once there is enough business activity to analyze.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFFBA8A55),
              ),
              const SizedBox(width: 6),
              Text(
                'ThreadStock AI',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8D6433),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insightText,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: const Color(0xFF451A03),
            ),
          ),
          if (hasRealInsight) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                widget.onNavigateToIndex?.call(6); // AI Studio / Insights
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Recommendation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS (Used only when real data is present)
// =============================================================================

class _SalesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final String currencySymbol;

  _SalesChartPainter({
    this.points = const [],
    this.currencySymbol = '₹',
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingBottom = 16.0;
    const double paddingTop = 20.0;
    const double paddingLeft = 10.0;
    const double paddingRight = 10.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // 1. Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight * (i / 3.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    if (points.isEmpty) return;

    // 2. Compute Max Value
    double maxVal = 0.0;
    for (final p in points) {
      final val = (p['amount'] as num?)?.toDouble() ?? 0.0;
      if (val > maxVal) maxVal = val;
    }

    final double effectiveMax = maxVal > 0 ? maxVal * 1.18 : 1000.0;

    // 3. Compute Coordinates
    final List<Offset> offsets = [];
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final x = n == 1
          ? paddingLeft + chartWidth / 2
          : paddingLeft + (i / (n - 1)) * chartWidth;
      final val = (points[i]['amount'] as num?)?.toDouble() ?? 0.0;
      final normalizedY = (val / effectiveMax).clamp(0.0, 1.0);
      final y = paddingTop + chartHeight * (1.0 - normalizedY);
      offsets.add(Offset(x, y));
    }

    // 4. Gradient Fill Under Curve
    final fillPath = Path();
    fillPath.moveTo(offsets.first.dx, paddingTop + chartHeight);
    for (final pt in offsets) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(offsets.last.dx, paddingTop + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x33C5A059),
          Color(0x00C5A059),
        ],
      ).createShader(Rect.fromLTWH(0, paddingTop, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // 5. Line Stroke
    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFFC5A059)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, strokePaint);

    // 6. Data Points & Value Badges for Non-Zero Points
    final dotFillPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFFC5A059)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < offsets.length; i++) {
      final val = (points[i]['amount'] as num?)?.toDouble() ?? 0.0;
      final pt = offsets[i];

      // Draw dot for points with value > 0 or latest point
      if (val > 0 || i == offsets.length - 1) {
        canvas.drawCircle(pt, 4.0, dotFillPaint);
        canvas.drawCircle(pt, 4.0, dotBorderPaint);
      }

      // Draw value badge for non-zero points
      if (val > 0) {
        final textSpan = TextSpan(
          text: '$currencySymbol${val.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeX = (pt.dx - tp.width / 2).clamp(
          paddingLeft,
          size.width - paddingRight - tp.width,
        );
        final badgeY = pt.dy - tp.height - 6;
        tp.paint(canvas, Offset(badgeX, badgeY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.currencySymbol != currencySymbol;
  }
}

class _CategoryDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final paint = Paint()
      ..color = const Color(0xFFBA8A55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
