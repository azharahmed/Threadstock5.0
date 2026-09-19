// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ai_actions_view.dart';
import '../widgets/ai_history_view.dart';
import '../widgets/demand_forecast_view.dart';
import '../widgets/product_demand_forecast_view.dart';
import '../widgets/proposal_detail_view.dart';
import '../../../../core/responsive/desktop_layout.dart';

enum AiStudioViewMode {
  forecastDetail,
  assistantWorkspace,
  aiActions,
  proposalDetail,
  aiHistory,
  demandForecast,
}

class AiStudioPage extends StatefulWidget {
  const AiStudioPage({
    super.key,
    this.initialMode = AiStudioViewMode.forecastDetail,
    this.onTitleChanged,
    this.onNavigateToIndex,
  });

  final AiStudioViewMode initialMode;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<int>? onNavigateToIndex;

  @override
  State<AiStudioPage> createState() => _AiStudioPageState();
}

class _AiStudioPageState extends State<AiStudioPage> {
  late AiStudioViewMode _viewMode;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
    if (_viewMode == AiStudioViewMode.forecastDetail) {
      widget.onTitleChanged?.call('Forecasts > Classic White Oxford — M');
    } else if (_viewMode == AiStudioViewMode.aiActions) {
      widget.onTitleChanged?.call('AI Studio');
    } else if (_viewMode == AiStudioViewMode.proposalDetail) {
      widget.onTitleChanged?.call('Proposal Detail');
    } else if (_viewMode == AiStudioViewMode.aiHistory) {
      widget.onTitleChanged?.call('AI Studio');
    } else if (_viewMode == AiStudioViewMode.demandForecast) {
      widget.onTitleChanged?.call('AI Studio');
    } else {
      widget.onTitleChanged?.call('AI Studio');
    }
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
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode == AiStudioViewMode.demandForecast) {
      return DemandForecastView(
        onPreparePo: (sku) {
          _showFeedback('PO drafted for $sku (80 units).');
        },
        onViewFullForecast: () {
          _showFeedback('Full forecast detail opened.');
        },
        onCreatePoForRow: (row) {
          _showFeedback('PO created for ${row.name}.');
        },
        onViewAllProducts: () {
          _showFeedback('Viewing all products requiring attention.');
        },
      );
    }

    if (_viewMode == AiStudioViewMode.aiHistory) {
      return AiHistoryView(
        onExportHistory: () {
          _showFeedback('AI History audit log exported to CSV.');
        },
        onViewRelatedActions: () {
          setState(() {
            _viewMode = AiStudioViewMode.aiActions;
            widget.onTitleChanged?.call('AI Studio');
          });
        },
        onReRunDiagnostic: () {
          _showFeedback('Diagnostic query re-run initiated for Zone A.');
        },
      );
    }

    if (_viewMode == AiStudioViewMode.proposalDetail) {
      return ProposalDetailView(
        onBackToActions: () {
          setState(() {
            _viewMode = AiStudioViewMode.aiActions;
            widget.onTitleChanged?.call('AI Studio');
          });
        },
        onApprovePo: () {
          _showFeedback('Replenishment Proposal approved. PO generated for Vrindavan Express route.');
        },
        onRejectPlan: () {
          _showFeedback('Replenishment plan rejected.');
        },
        onEditQuantities: () {
          _showFeedback('Quantity modification mode toggled.');
        },
        onViewFullAnalysis: () {
          _showFeedback('Opening full replenishment analysis report.');
        },
      );
    }

    if (_viewMode == AiStudioViewMode.aiActions) {
      return AiActionsView(
        onAskThreadStockAi: () {
          _showFeedback('ThreadStock AI assistant activated.');
        },
        onReviewAction: (actionId) {
          setState(() {
            _viewMode = AiStudioViewMode.proposalDetail;
            widget.onTitleChanged?.call('Proposal Detail');
          });
        },
      );
    }

    if (_viewMode == AiStudioViewMode.forecastDetail) {
      return ProductDemandForecastView(
        onNavigateToPurchasing: () => widget.onNavigateToIndex?.call(3),
        onDraftReplenishmentPo: () => widget.onNavigateToIndex?.call(3),
        onSwitchToWorkspace: () {
          setState(() {
            _viewMode = AiStudioViewMode.assistantWorkspace;
            widget.onTitleChanged?.call('AI Studio');
          });
        },
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Split Layout: Left Session Workspace vs Right Prepared Plan
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Active Session & Prompts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActiveSessionCard(),
                              const SizedBox(height: 22),
                              _buildSuggestedPromptsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),

                        // Right Column: AI Prepared Plan (approx 380px width)
                        SizedBox(
                          width: 380,
                          child: _buildAiPreparedPlanCard(),
                        ),
                      ],
                    );
                  }

                  // Compact / Stacked Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActiveSessionCard(),
                      const SizedBox(height: 22),
                      _buildSuggestedPromptsSection(),
                      const SizedBox(height: 24),
                      _buildAiPreparedPlanCard(),
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
  // 1. ACTIVE SESSION CARD (LEFT MAIN CARD)
  // ========================================================
  Widget _buildActiveSessionCard() {
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
          // Header: ACTIVE SESSION: STORE REPLENISHMENT + Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE SESSION: STORE REPLENISHMENT',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Model Version Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3E8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEADBCA)),
                    ),
                    child: Text(
                      'Eid Season Model v2.4',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E6516),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Model Ready Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F7A46),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Model Ready',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F7A46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDE5DA), height: 1),
          const SizedBox(height: 18),

          // User Prompt Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Circle AM
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDFD4C5)),
                  ),
                  child: Center(
                    child: Text(
                      'AM',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Mercer • Delhi Hub',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prepare replenishment for stores likely to run out of high-velocity linen and cotton shirts during Eid. Focus on regional transit clusters and use fastest route logic.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1C1A),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Response Lead Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Color(0xFFBA8A55),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I have prepared a predictive replenishment model based on Delhi Warehouse (Zone A) supply vectors.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Analyzing Delhi flagship, Lucknow boutique, and Mumbai central hubs. Regional transit shows potential stockouts in 3 core SKUs due to the upcoming holiday demand surge.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6358),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Three Metric Stat Cards
          Row(
            children: [
              // 1. Stockout Risk
              Expanded(
                child: _buildStatMetricCard(
                  label: 'STOCKOUT RISK',
                  value: '18 SKUs',
                  trendBadge: '+12%',
                  isNegativeTrend: true,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Optimized Volume
              Expanded(
                child: _buildStatMetricCard(
                  label: 'OPTIMIZED VOLUME',
                  value: '1,420 units',
                  trendBadge: '+8%',
                  isNegativeTrend: false,
                ),
              ),
              const SizedBox(width: 12),

              // 3. Confidence Level
              Expanded(
                child: _buildConfidenceMetricCard(),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Recommendations Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE5DA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.track_changes_rounded,
                        size: 16,
                        color: Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF1EAE0), height: 1),

                // Item 1: Dispatch
                _buildRecommendationRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Dispatch 840 units to Delhi Flagship Hub',
                  subtitle: 'Based on predicted demand and current on-hand levels.',
                  badgeText: 'High Priority',
                  badgeBg: const Color(0xFFFAF3E8),
                  badgeColor: const Color(0xFF9E6516),
                  onTap: () => _showFeedback('Dispatching to Delhi Flagship Hub recommendation opened.'),
                ),
                const Divider(color: Color(0xFFF6F1EA), height: 1),

                // Item 2: Route
                _buildRecommendationRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Route via Vrindavan Express',
                  subtitle: 'Estimated delivery: 42 hours. Saves ₹12,000 in transit costs.',
                  badgeText: 'Optimized Route',
                  badgeBg: const Color(0xFFE9F6EE),
                  badgeColor: const Color(0xFF1F7A46),
                  onTap: () => _showFeedback('Vrindavan Express routing applied.'),
                ),
                const Divider(color: Color(0xFFF6F1EA), height: 1),

                // Item 3: Varieties
                _buildRecommendationRow(
                  icon: Icons.sell_outlined,
                  title: 'Include linen blend varieties',
                  subtitle: 'Higher demand expected during Eid season.',
                  badgeText: 'AI Suggestion',
                  badgeBg: const Color(0xFFEAF1FB),
                  badgeColor: const Color(0xFF2662BA),
                  onTap: () => _showFeedback('Linen blend varieties included in draft order.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Interactive Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFBA8A55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1E1C1A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask ThreadStock AI to tweak quantities or route priorities...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF9E958A),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _showFeedback('Simulating adjustment: "$val"');
                        _promptController.clear();
                      }
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    final text = _promptController.text.trim();
                    if (text.isNotEmpty) {
                      _showFeedback('Simulating adjustment: "$text"');
                      _promptController.clear();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF352315),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
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

  Widget _buildStatMetricCard({
    required String label,
    required String value,
    required String trendBadge,
    required bool isNegativeTrend,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isNegativeTrend
                      ? const Color(0xFFB83A28)
                      : const Color(0xFF1E1C1A),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 15,
                    color: isNegativeTrend
                        ? const Color(0xFFB83A28)
                        : const Color(0xFF1F7A46),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    trendBadge,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isNegativeTrend
                          ? const Color(0xFFB83A28)
                          : const Color(0xFF1F7A46),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceMetricCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIDENCE LEVEL',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '94.2% Accurate',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const Icon(
                Icons.track_changes_rounded,
                size: 18,
                color: Color(0xFF0F766E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF946A36),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C1A),
                    ),
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
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8A8275),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // 2. SUGGESTED PROMPTS & REFINEMENTS (BELOW MAIN CARD)
  // ========================================================
  Widget _buildSuggestedPromptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Prompts & Refinements',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1C1A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildPromptChip('“Limit total cost to ₹5,00,000 max”'),
            _buildPromptChip('“Prioritize cargo air transit”'),
            _buildPromptChip('“Include linen blend varieties”'),
            // Dropdown more button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'More',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: Color(0xFF7E766B),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptChip(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _promptController.text = label.replaceAll('“', '').replaceAll('”', '');
        });
        _showFeedback('Selected prompt: $label');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEADBCA)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2721),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 3. AI PREPARED PLAN (RIGHT SIDE CARD)
  // ========================================================
  Widget _buildAiPreparedPlanCard() {
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
          // Header: AI PREPARED PLAN + Title + More options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI PREPARED PLAN',
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
                onPressed: () => _showFeedback('Prepared plan options'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Eid Replenishment Order',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 18),

          // 2x2 KPI Grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.storefront_outlined,
                      label: 'AFFECTED STORES',
                      value: '3 nodes',
                      valueColor: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.local_offer_outlined,
                      label: 'AFFECTED SKUs',
                      value: '18 variants',
                      valueColor: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.bar_chart_rounded,
                      label: 'PROJECTED COST',
                      value: '₹6,42,000',
                      valueColor: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.trending_up_rounded,
                      label: 'LOST SALES AVOIDED',
                      value: '₹2,18,000',
                      valueColor: const Color(0xFF1F7A46),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // PRESCRIBED TRANSFERS Header
          Text(
            'PRESCRIBED TRANSFERS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 12),

          // Prescribed transfers list
          _buildPrescribedTransferRow('Delhi Flagship Hub', '840 units'),
          const SizedBox(height: 8),
          _buildPrescribedTransferRow('Lucknow Regent St', '380 units'),
          const SizedBox(height: 8),
          _buildPrescribedTransferRow('Mumbai Phoenix', '200 units'),
          const SizedBox(height: 18),

          // LOGISTICS ACTION PATH Inset Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBDCBF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 15,
                      color: Color(0xFF9E6516),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LOGISTICS ACTION PATH',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: const Color(0xFF9E6516),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF423B33),
                      height: 1.45,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Recommend dispatcher routing via ',
                      ),
                      TextSpan(
                        text: 'Vrindavan Express',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1C1A),
                        ),
                      ),
                      TextSpan(
                        text:
                            ' to secure a ₹12,000 transit discount. Expected delivery window: 42 hours.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary CTA: Approve & Send Plan
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
                onTap: () => _showFeedback(
                    'Eid Replenishment Order approved and dispatched to warehouses!'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Approve & Send Plan',
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

          // Secondary CTAs: Edit Plan & Review Details
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEADBCA)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showFeedback('Opening Plan Editor...'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: Color(0xFF1E1C1A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Edit Plan',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEADBCA)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showFeedback('Opening Full Details Breakdown...'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 15,
                              color: Color(0xFF1E1C1A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Review Details',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanKpiBox({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: const Color(0xFF9E6516),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescribedTransferRow(String destination, String quantity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          destination,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2520),
          ),
        ),
        Text(
          quantity,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }
}
