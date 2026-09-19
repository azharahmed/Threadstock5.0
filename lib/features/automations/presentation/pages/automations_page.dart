// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../widgets/low_stock_auto_reorder_view.dart';
import '../widgets/run_detail_view.dart';
import '../widgets/create_automation_view.dart';
import '../widgets/run_history_view.dart';

enum AutomationsViewMode {
  runDetail,
  runHistory,
  lowStockAutoReorder,
  rulesWorkspace,
  createAutomation,
}

class AutomationsPage extends StatefulWidget {
  const AutomationsPage({
    super.key,
    this.initialMode = AutomationsViewMode.runDetail,
    this.onTitleChanged,
  });

  final AutomationsViewMode initialMode;
  final ValueChanged<String>? onTitleChanged;

  @override
  State<AutomationsPage> createState() => _AutomationsPageState();
}

class _AutomationRule {
  const _AutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.lastRun,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.icon,
    required this.naturalDefinition,
    required this.automationMode,
    required this.triggerCondition,
    required this.preferredSupplier,
    required this.safetyThreshold,
    required this.affectedSkus,
    required this.recommendedUnits,
    required this.estimatedValue,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final String badge;
  final Color badgeBg;
  final Color badgeColor;
  final String lastRun;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final IconData icon;
  final String naturalDefinition;
  final String automationMode;
  final String triggerCondition;
  final String preferredSupplier;
  final String safetyThreshold;
  final String affectedSkus;
  final String recommendedUnits;
  final String estimatedValue;
  final bool isActive;

  _AutomationRule copyWith({
    bool? isActive,
    String? automationMode,
  }) {
    return _AutomationRule(
      id: id,
      title: title,
      description: description,
      badge: badge,
      badgeBg: badgeBg,
      badgeColor: badgeColor,
      lastRun: lastRun,
      status: status,
      statusBg: statusBg,
      statusColor: statusColor,
      icon: icon,
      naturalDefinition: naturalDefinition,
      automationMode: automationMode ?? this.automationMode,
      triggerCondition: triggerCondition,
      preferredSupplier: preferredSupplier,
      safetyThreshold: safetyThreshold,
      affectedSkus: affectedSkus,
      recommendedUnits: recommendedUnits,
      estimatedValue: estimatedValue,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _AutomationsPageState extends State<AutomationsPage> {
  late AutomationsViewMode _mode;
  int _selectedTab = 1; // 0: All, 1: Active, 2: Draft, 3: Paused, 4: Archived
  String _selectedRuleId = 'rule-1';
  final _searchController = TextEditingController();

  late List<_AutomationRule> _rules;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == AutomationsViewMode.runDetail) {
      widget.onTitleChanged?.call('Run #RUN-1847 — Failed');
    } else if (_mode == AutomationsViewMode.runHistory) {
      widget.onTitleChanged?.call('Run History');
    } else if (_mode == AutomationsViewMode.lowStockAutoReorder) {
      widget.onTitleChanged?.call('Low Stock Auto-Reorder');
    } else if (_mode == AutomationsViewMode.createAutomation) {
      widget.onTitleChanged?.call('Create Automation');
    } else {
      widget.onTitleChanged?.call('Rules Workspace');
    }
    _rules = [
      const _AutomationRule(
        id: 'rule-1',
        title: 'Low Stock Replenishment',
        description: 'When projected coverage < 14 days',
        badge: 'Requires Approval',
        badgeBg: Color(0xFFFAF3E8),
        badgeColor: Color(0xFF9E6516),
        lastRun: '2 hours ago',
        status: 'Active',
        statusBg: Color(0xFFE9F6EE),
        statusColor: Color(0xFF1F7A46),
        icon: Icons.inventory_2_outlined,
        naturalDefinition:
            'When projected stock coverage falls below 14 days, prepare a purchase order to replenish stock based on forecasted demand.',
        automationMode: 'Prepare for Approval',
        triggerCondition:
            'Daily velocity tracking shows depletion of critical sizes (M, L) within 14 business days.',
        preferredSupplier:
            'Biella Fabric Group (Milan, Italy) – 12 days lead time.',
        safetyThreshold:
            'Requires manual authorization for order values exceeding ₹2,50,000.',
        affectedSkus: '18 SKUs',
        recommendedUnits: '1,240 units',
        estimatedValue: '₹6,42,000',
        isActive: true,
      ),
      const _AutomationRule(
        id: 'rule-2',
        title: 'Price Adjustment Alert',
        description: 'When competitor price changes > 10%',
        badge: 'Suggest',
        badgeBg: Color(0xFFEAF1FB),
        badgeColor: Color(0xFF2662BA),
        lastRun: '1 day ago',
        status: 'Active',
        statusBg: Color(0xFFE9F6EE),
        statusColor: Color(0xFF1F7A46),
        icon: Icons.local_offer_outlined,
        naturalDefinition:
            'When verified luxury competitor prices fluctuate beyond 10%, surface a targeted price adjustment proposal.',
        automationMode: 'Suggest',
        triggerCondition:
            'External market scraping detects pricing divergence on matched product taxonomy.',
        preferredSupplier: 'Direct Atelier Pricing Matrix',
        safetyThreshold: 'Requires merchandising director review.',
        affectedSkus: '6 SKUs',
        recommendedUnits: '—',
        estimatedValue: '₹1,20,000',
        isActive: true,
      ),
      const _AutomationRule(
        id: 'rule-3',
        title: 'Dead Stock Flagging',
        description: 'When no sales in 60 days',
        badge: 'Automatic',
        badgeBg: Color(0xFFFCEEEB),
        badgeColor: Color(0xFFC2410C),
        lastRun: '6 hours ago',
        status: 'Active',
        statusBg: Color(0xFFE9F6EE),
        statusColor: Color(0xFF1F7A46),
        icon: Icons.warning_amber_rounded,
        naturalDefinition:
            'Automatically flag inventory holding units that have not logged a sale across all boutique channels for 60 consecutive days.',
        automationMode: 'Automatic',
        triggerCondition: 'Sales ledger records zero units moved within 60 days.',
        preferredSupplier: 'Regional Warehouse Redistribution',
        safetyThreshold: 'Applies only to items with on-hand value > ₹50,000.',
        affectedSkus: '12 SKUs',
        recommendedUnits: '340 units',
        estimatedValue: '₹4,10,000',
        isActive: true,
      ),
      const _AutomationRule(
        id: 'rule-4',
        title: 'Seasonal Collection Transition',
        description: '30 days before season end',
        badge: 'Suggest',
        badgeBg: Color(0xFFEAF1FB),
        badgeColor: Color(0xFF2662BA),
        lastRun: 'Never run',
        status: 'Draft',
        statusBg: Color(0xFFF0ECE5),
        statusColor: Color(0xFF6B6358),
        icon: Icons.calendar_today_outlined,
        naturalDefinition:
            'Prepare collection transition markdown and archival proposals 30 days prior to the official seasonal calendar change.',
        automationMode: 'Suggest',
        triggerCondition: 'Calendar reaches 30-day threshold before seasonal closing date.',
        preferredSupplier: 'Outlet Distribution Network',
        safetyThreshold: 'Requires seasonal markdown budget approval.',
        affectedSkus: '24 SKUs',
        recommendedUnits: '890 units',
        estimatedValue: '₹11,50,000',
        isActive: false,
      ),
      const _AutomationRule(
        id: 'rule-5',
        title: 'Transfer Optimization',
        description: 'Suggest inter-warehouse transfers',
        badge: 'Automatic',
        badgeBg: Color(0xFFE9F6EE),
        badgeColor: Color(0xFF1F7A46),
        lastRun: '3 days ago',
        status: 'Active',
        statusBg: Color(0xFFE9F6EE),
        statusColor: Color(0xFF1F7A46),
        icon: Icons.local_shipping_outlined,
        naturalDefinition:
            'Balance inventory nodes by routing excess central warehouse stock to regional boutiques projected to run out of stock.',
        automationMode: 'Automatic',
        triggerCondition: 'Regional boutique stock falls below safety buffer while Central Warehouse has excess stock.',
        preferredSupplier: 'Vrindavan Express Regional Logistics',
        safetyThreshold: 'Auto-approves transfer lots up to ₹1,50,000.',
        affectedSkus: '8 SKUs',
        recommendedUnits: '520 units',
        estimatedValue: '₹3,45,000',
        isActive: true,
      ),
      const _AutomationRule(
        id: 'rule-6',
        title: 'Purchase Order Reminder',
        description: 'Remind pending POs after 48 hours',
        badge: 'Suggest',
        badgeBg: Color(0xFFEAF1FB),
        badgeColor: Color(0xFF2662BA),
        lastRun: '12 hours ago',
        status: 'Active',
        statusBg: Color(0xFFE9F6EE),
        statusColor: Color(0xFF1F7A46),
        icon: Icons.description_outlined,
        naturalDefinition:
            'Send automated reminder notifications to approvers when purchase orders remain pending without sign-off for over 48 hours.',
        automationMode: 'Suggest',
        triggerCondition: 'Purchase order status == Awaiting Approval && elapsed time > 48h.',
        preferredSupplier: 'Internal Procurement Operations',
        safetyThreshold: 'Escalates to Central Admin if unacknowledged after 72h.',
        affectedSkus: '—',
        recommendedUnits: '—',
        estimatedValue: '—',
        isActive: true,
      ),
    ];

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _AutomationRule? get _selectedRule {
    try {
      return _rules.firstWhere((r) => r.id == _selectedRuleId);
    } catch (_) {
      return null;
    }
  }

  List<_AutomationRule> get _filteredRules {
    final query = _searchController.text.trim().toLowerCase();

    return _rules.where((rule) {
      // 1. Tab filter
      if (_selectedTab == 1 && !rule.isActive) return false;
      if (_selectedTab == 2 && rule.status != 'Draft') return false;
      if (_selectedTab == 3 && rule.status != 'Paused') return false;
      if (_selectedTab == 4 && rule.status != 'Archived') return false;

      // 2. Search query filter
      if (query.isNotEmpty) {
        final matches = rule.title.toLowerCase().contains(query) ||
            rule.description.toLowerCase().contains(query) ||
            rule.badge.toLowerCase().contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == AutomationsViewMode.createAutomation) {
      return CreateAutomationView(
        onSaveAndActivate: () {
          _showFeedback('Automation rule activated successfully.');
        },
        onSaveDraft: () {
          _showFeedback('Rule draft saved.');
        },
        onBackToAutomations: () {
          setState(() {
            _mode = AutomationsViewMode.rulesWorkspace;
            widget.onTitleChanged?.call('Rules Workspace');
          });
        },
      );
    }

    if (_mode == AutomationsViewMode.runDetail) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RunDetailView(
                  runId: 'RUN-1847',
                  onRetryRun: () {
                    _showFeedback('Retrying automation run RUN-1847...');
                  },
                  onSkipAndContinue: () {
                    setState(() {
                      _mode = AutomationsViewMode.runHistory;
                      widget.onTitleChanged?.call('Run History');
                    });
                  },
                  onEditAutomationRule: () {
                    setState(() {
                      _mode = AutomationsViewMode.lowStockAutoReorder;
                      widget.onTitleChanged?.call('Low Stock Auto-Reorder');
                    });
                  },
                  onViewAllAffectedItems: () {
                    _showFeedback('Viewing complete manifest of 18 affected variants');
                  },
                  onSelectRelatedRun: (runId) {
                    _showFeedback('Opening run log $runId');
                  },
                  onGetAiRecommendation: () {
                    _showFeedback('AI generated recommendation: Switch endpoint to secondary gateway with 45s timeout.');
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    if (_mode == AutomationsViewMode.runHistory) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RunHistoryView(
                  onSelectAutomation: (automationName) {
                    if (automationName == 'Low Stock Auto-Reorder') {
                      setState(() {
                        _mode = AutomationsViewMode.lowStockAutoReorder;
                        widget.onTitleChanged?.call('Low Stock Auto-Reorder');
                      });
                    } else {
                      _showFeedback('Viewing execution profile for $automationName');
                    }
                  },
                  onSelectRun: (runId) {
                    setState(() {
                      _mode = AutomationsViewMode.runDetail;
                      widget.onTitleChanged?.call('Run #$runId — Failed');
                    });
                  },
                  onExportLogs: () {
                    _showFeedback('Exporting all 234 automation run records to CSV');
                  },
                  onViewInsights: () {
                    _showFeedback('Navigating to full 30-day automation performance audit');
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    if (_mode == AutomationsViewMode.lowStockAutoReorder) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LowStockAutoReorderView(
                  onEditConfiguration: () {
                    setState(() {
                      _mode = AutomationsViewMode.rulesWorkspace;
                      widget.onTitleChanged?.call('Rules Workspace');
                    });
                  },
                  onEditAutomation: () {
                    setState(() {
                      _mode = AutomationsViewMode.rulesWorkspace;
                      widget.onTitleChanged?.call('Rules Workspace');
                    });
                  },
                  onViewRunLogs: () {
                    setState(() {
                      _mode = AutomationsViewMode.runHistory;
                      widget.onTitleChanged?.call('Run History');
                    });
                  },
                  onDeleteAutomation: () {
                    _showFeedback('Delete automation confirmation triggered');
                  },
                  onViewRecommendations: () {
                    _showFeedback('Analyzing stock levels & generating transfer/reorder recommendations');
                  },
                  onViewAllActivity: () {
                    setState(() {
                      _mode = AutomationsViewMode.runHistory;
                      widget.onTitleChanged?.call('Run History');
                    });
                  },
                  onViewProductSkus: (skus) {
                    _showFeedback('Filtering inventory view by $skus');
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    final selectedRule = _selectedRule;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Split Layout: Left Rules Workspace vs Right Configuring Rule
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Rules Workspace (Header + Tabs + Filters + Rules List + Pagination)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildTabsRow(),
                              const SizedBox(height: 18),
                              _buildFilterToolbar(),
                              const SizedBox(height: 16),
                              _buildRulesList(),
                              const SizedBox(height: 16),
                              _buildPaginationFooter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),

                        // Right Column: Configuring Rule Panel + Recent Activity (approx 380px width)
                        SizedBox(
                          width: 380,
                          child: Column(
                            children: [
                              if (selectedRule != null)
                                _buildConfiguringRuleCard(selectedRule),
                              const SizedBox(height: 20),
                              _buildRecentActivityCard(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Compact / Stacked Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTabsRow(),
                      const SizedBox(height: 18),
                      _buildFilterToolbar(),
                      const SizedBox(height: 16),
                      _buildRulesList(),
                      const SizedBox(height: 16),
                      _buildPaginationFooter(),
                      const SizedBox(height: 24),
                      if (selectedRule != null)
                        _buildConfiguringRuleCard(selectedRule),
                      const SizedBox(height: 20),
                      _buildRecentActivityCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 1. HEADER ROW: Rules Workspace + 12 active + Create Automation
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Active Count Badge
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _mode = AutomationsViewMode.lowStockAutoReorder;
                  widget.onTitleChanged?.call('Low Stock Auto-Reorder');
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFF8C5A2B)),
                    const SizedBox(width: 4),
                    Text(
                      'Back to Auto-Reorder',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C5A2B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Rules Workspace',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF2FA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '12 active',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2B5FA3),
                ),
              ),
            ),
          ],
        ),

        // Create Automation CTA Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C1A),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1C1A).withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showFeedback('Create automation rule workflow opened.'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Create Automation',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // 2. STATUS TABS ROW
  // ========================================================
  Widget _buildTabsRow() {
    final tabs = [
      {'label': 'All', 'count': '12'},
      {'label': 'Active', 'count': '8'},
      {'label': 'Draft', 'count': '2'},
      {'label': 'Paused', 'count': '1'},
      {'label': 'Archived', 'count': '1'},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8DFD3), width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = _selectedTab == index;

            return InkWell(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFBA8A55)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E1C1A)
                            : const Color(0xFF7E766B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFAF3E6)
                            : const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab['count']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF9E6516)
                              : const Color(0xFF7E766B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ========================================================
  // 3. FILTER TOOLBAR
  // ========================================================
  Widget _buildFilterToolbar() {
    return Row(
      children: [
        // Search Input Field
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: Color(0xFF8A8275),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search automation rules...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF9E958A),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Dropdown: All Types
        _buildDropdownFilter('All Types'),
        const SizedBox(width: 10),

        // Dropdown: Last Run
        _buildDropdownFilter('Last Run'),
      ],
    );
  }

  Widget _buildDropdownFilter(String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFD4C5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF8A8275),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 4. RULES LIST (STACKED RULE CARDS)
  // ========================================================
  Widget _buildRulesList() {
    final rules = _filteredRules;

    if (rules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8DFD3)),
        ),
        child: Center(
          child: Text(
            'No automation rules found matching filter.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF7E766B),
            ),
          ),
        ),
      );
    }

    return Column(
      children: rules.map((rule) {
        final isSelected = _selectedRuleId == rule.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedRuleId = rule.id),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFDFBF7)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBA8A55)
                      : const Color(0xFFE8DFD3),
                  width: isSelected ? 1.3 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A231A).withOpacity(isSelected ? 0.04 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Inset Box
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF4EA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFBA8A55)
                            : const Color(0xFFEADBCA),
                      ),
                    ),
                    child: Icon(
                      rule.icon,
                      size: 19,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Rule Title & Subtitle + Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                rule.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rule.badgeBg,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                rule.badge,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: rule.badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rule.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Last Run
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Last Run',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8A8275),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rule.lastRun,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3E362E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rule.statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rule.status,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: rule.statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Chevron Right
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF8A8275),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========================================================
  // 5. PAGINATION FOOTER
  // ========================================================
  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing 1–6 of 12 rules',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: Color(0xFF8A8275),
            ),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFBA8A55)),
              ),
              child: Center(
                child: Text(
                  '1',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBA8A55),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Center(
                child: Text(
                  '2',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8A8275),
            ),
            const SizedBox(width: 12),

            // Dropdown: 6 per page
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Row(
                children: [
                  Text(
                    '6 per page',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Color(0xFF8A8275),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 6. RIGHT PANEL: CONFIGURING RULE CARD
  // ========================================================
  Widget _buildConfiguringRuleCard(_AutomationRule rule) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Label: CONFIGURING RULE + More menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONFIGURING RULE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF946A36),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                color: const Color(0xFF7E766B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFeedback('Rule configuration options menu'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title & Active Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rule.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rule.isActive ? 'Active' : 'Paused',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: rule.isActive
                          ? const Color(0xFF1F7A46)
                          : const Color(0xFF8A8275),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 24,
                    width: 38,
                    child: Switch(
                      value: rule.isActive,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF1F7A46),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCDC2B4),
                      onChanged: (val) {
                        setState(() {
                          final idx = _rules.indexWhere((r) => r.id == rule.id);
                          if (idx != -1) {
                            _rules[idx] = _rules[idx].copyWith(isActive: val);
                          }
                        });
                        _showFeedback(val
                            ? '${rule.title} enabled.'
                            : '${rule.title} paused.');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Natural Language Definition Inset Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA8A55),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF423B33),
                        height: 1.45,
                      ),
                      children: const [
                        TextSpan(
                          text: 'When projected stock coverage falls below ',
                        ),
                        TextSpan(
                          text: '14 days',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1C1A),
                          ),
                        ),
                        TextSpan(
                          text:
                              ', prepare a purchase order to replenish stock based on forecasted demand.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // AUTOMATION MODE Segmented Control
          Text(
            'AUTOMATION MODE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildModeSegment(rule, 'Suggest'),
                _buildModeSegment(rule, 'Prepare for Approval'),
                _buildModeSegment(rule, 'Automatic'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trigger Condition
          _buildConditionField(
            label: 'Trigger Condition',
            value: rule.triggerCondition,
          ),
          const SizedBox(height: 12),

          // Preferred Supplier
          _buildConditionField(
            label: 'Preferred Supplier',
            value: rule.preferredSupplier,
          ),
          const SizedBox(height: 12),

          // Safety Warning Threshold
          _buildConditionField(
            label: 'Safety Warning Threshold',
            value: rule.safetyThreshold,
            valueColor: const Color(0xFFC2410C),
          ),
          const SizedBox(height: 18),

          // AFFECTED ITEMS (EST.) Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE5DA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AFFECTED ITEMS (EST.)',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF946A36),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildEstMetricTile(
                        icon: Icons.inventory_2_outlined,
                        value: rule.affectedSkus,
                        subtitle: 'Below threshold',
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFEADBCA)),
                    Expanded(
                      child: _buildEstMetricTile(
                        icon: Icons.track_changes_rounded,
                        value: rule.recommendedUnits,
                        subtitle: 'Recommended',
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFEADBCA)),
                    Expanded(
                      child: _buildEstMetricTile(
                        icon: Icons.shopping_bag_outlined,
                        value: rule.estimatedValue,
                        subtitle: 'Estimated value',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Save Changes Primary CTA
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF322316), Color(0xFF1C1814)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E2014).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showFeedback('Changes saved for ${rule.title}.'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pause Rule Secondary CTA
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    final idx = _rules.indexWhere((r) => r.id == rule.id);
                    if (idx != -1) {
                      _rules[idx] = _rules[idx].copyWith(isActive: !rule.isActive);
                    }
                  });
                  _showFeedback(rule.isActive
                      ? '${rule.title} paused.'
                      : '${rule.title} activated.');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        rule.isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 16,
                        color: const Color(0xFF1E1C1A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rule.isActive ? 'Pause Rule' : 'Resume Rule',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegment(_AutomationRule rule, String mode) {
    final isSelected = rule.automationMode == mode;
    final flex = mode == 'Prepare for Approval' ? 14 : 9;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            final idx = _rules.indexWhere((r) => r.id == rule.id);
            if (idx != -1) {
              _rules[idx] = _rules[idx].copyWith(automationMode: mode);
            }
          });
          _showFeedback('Automation mode updated to $mode.');
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: const Color(0xFFEADBCA))
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A231A).withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                mode,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1E1C1A)
                      : const Color(0xFF6B6358),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionField({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7E766B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: valueColor ?? const Color(0xFF2A231A),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEstMetricTile({
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: const Color(0xFF9E6516)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 7. RIGHT PANEL: RECENT ACTIVITY CARD
  // ========================================================
  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Recent Activity + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              InkWell(
                onTap: () => _showFeedback('All activity audit log opened.'),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item 1: Rule executed
          _buildActivityItem(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF1F7A46),
            title: 'Rule executed',
            timestamp: '2 hours ago',
            subtitle: 'Detected 18 SKUs below 14 days coverage.',
          ),
          const SizedBox(height: 14),

          // Item 2: Draft PO created
          _buildActivityItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF1E1C1A),
            title: 'Draft PO created',
            timestamp: '2 hours ago',
            subtitle: 'PO-DRAFT-7721 (₹6,42,000)',
          ),
          const SizedBox(height: 14),

          // Item 3: Approval pending
          _buildActivityItem(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF7E766B),
            title: 'Approval pending',
            timestamp: '2 hours ago',
            subtitle: 'Waiting for Central Admin approval.',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String timestamp,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEADBCA)),
          ),
          child: Icon(icon, size: 15, color: iconColor),
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
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  Text(
                    timestamp,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8275),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
