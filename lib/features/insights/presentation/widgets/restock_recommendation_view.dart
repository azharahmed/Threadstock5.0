// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestockRecommendationView extends StatefulWidget {
  const RestockRecommendationView({
    super.key,
    this.onCreatePo,
    this.onDismiss,
    this.onRefresh,
    this.onViewAllWarnings,
  });

  final VoidCallback? onCreatePo;
  final VoidCallback? onDismiss;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAllWarnings;

  @override
  State<RestockRecommendationView> createState() =>
      _RestockRecommendationViewState();
}

class _RestockRecommendationViewState extends State<RestockRecommendationView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title, Subtitle & Action button
          _buildHeader(),
          const SizedBox(height: 32),

          // 2. Honest Empty State
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Not enough data yet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ThreadStock AI will generate restock recommendations after sufficient sales and inventory history is available.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restock Recommendation',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI-powered insights to keep your inventory in the right place, at the right time.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed:
                  widget.onRefresh ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Checking sales and inventory records...',
                        ),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Insights'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
