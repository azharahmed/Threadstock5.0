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
    this.initialMode = AiStudioViewMode.demandForecast,
    this.locationId,
    this.onTitleChanged,
    this.onNavigateToIndex,
  });

  final AiStudioViewMode initialMode;
  final String? locationId;
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
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFBA8A55),
              size: 18,
            ),
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
        locationId: widget.locationId,
        onPreparePo: (sku) {
          _showFeedback('PO drafted for $sku.');
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
          _showFeedback(
            'Replenishment Proposal approved. PO generated for Vrindavan Express route.',
          );
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
                        SizedBox(width: 380, child: _buildAiPreparedPlanCard()),
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
                    'AI ASSISTANT WORKSPACE',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBA8A55),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Awaiting Sufficient History',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E6516),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDE5DA), height: 1),
          const SizedBox(height: 18),

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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDFD4C5)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights_rounded,
                      size: 20,
                      color: Color(0xFF946A36),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autonomous Replenishment Engine',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ThreadStock AI will build replenishment proposals and demand models once sufficient sales history and inventory activity are recorded.',
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

          Row(
            children: [
              Expanded(
                child: _buildStatMetricCard(
                  label: 'STOCKOUT RISK',
                  value: '—',
                  trendBadge: 'Awaiting history',
                  isNegativeTrend: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatMetricCard(
                  label: 'OPTIMIZED VOLUME',
                  value: '—',
                  trendBadge: 'Awaiting history',
                  isNegativeTrend: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildConfidenceMetricCard()),
            ],
          ),
          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE5DA)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.track_changes_rounded,
                  size: 28,
                  color: Color(0xFFBA8A55),
                ),
                const SizedBox(height: 10),
                Text(
                  'No AI recommendations yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommendations will appear here as store inventory levels and transaction velocity develop.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

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
                      hintText:
                          'Ask ThreadStock AI for replenishment intelligence...',
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
                        _showFeedback(
                          'AI models will become active once operational data requirements are satisfied.',
                        );
                        _promptController.clear();
                      }
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    final text = _promptController.text.trim();
                    if (text.isNotEmpty) {
                      _showFeedback(
                        'AI models will become active once operational data requirements are satisfied.',
                      );
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
              Text(
                trendBadge,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7E766B),
                ),
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
                '—',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7E766B),
                ),
              ),
              const Icon(
                Icons.track_changes_rounded,
                size: 18,
                color: Color(0xFF7E766B),
              ),
            ],
          ),
        ],
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
          'Suggested Inquiries',
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
            _buildPromptChip('“Check catalog coverage”'),
            _buildPromptChip('“Assess inventory balance”'),
            _buildPromptChip('“View forecast readiness criteria”'),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptChip(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _promptController.text = label
              .replaceAll('“', '')
              .replaceAll('”', '');
        });
        _showFeedback('Selected inquiry: $label');
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
          Text(
            'AI PREPARED PLAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF946A36),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No Active Plan',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 18),

          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.storefront_outlined,
                      label: 'AFFECTED STORES',
                      value: '—',
                      valueColor: const Color(0xFF7E766B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.local_offer_outlined,
                      label: 'AFFECTED SKUs',
                      value: '—',
                      valueColor: const Color(0xFF7E766B),
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
                      value: '—',
                      valueColor: const Color(0xFF7E766B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanKpiBox(
                      icon: Icons.trending_up_rounded,
                      label: 'LOST SALES AVOIDED',
                      value: '—',
                      valueColor: const Color(0xFF7E766B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEDE5DA)),
            ),
            child: Center(
              child: Text(
                'No prescribed transfers available yet.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
                Text(
                  'Logistics optimizations will appear once demand patterns and store transfers are established.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF423B33),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEADBCA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: Color(0xFF9E958A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Approve & Send Plan',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9E958A),
                    ),
                  ),
                ],
              ),
            ),
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
                child: Icon(icon, size: 14, color: const Color(0xFF9E6516)),
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
}
