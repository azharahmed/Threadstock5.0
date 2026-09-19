// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccessRestrictedView extends StatefulWidget {
  const AccessRestrictedView({
    super.key,
    this.resourceName = 'Purchasing settings',
    this.roleName = 'Cashier',
    this.onRequestAccess,
    this.onGoToDashboard,
    this.onSwitchToAdmin,
  });

  final String resourceName;
  final String roleName;
  final VoidCallback? onRequestAccess;
  final VoidCallback? onGoToDashboard;
  final VoidCallback? onSwitchToAdmin;

  @override
  State<AccessRestrictedView> createState() => _AccessRestrictedViewState();
}

class _AccessRestrictedViewState extends State<AccessRestrictedView> {
  bool _isRequestSent = false;

  void _handleRequestAccess() {
    setState(() => _isRequestSent = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFFD5A46C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Access request submitted to Central Admin (Alex Mercer). You will receive an alert upon approval.',
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
        duration: const Duration(milliseconds: 3000),
      ),
    );
    widget.onRequestAccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 0
                  ? constraints.maxHeight - 48
                  : 580,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top optional demo switcher
                if (widget.onSwitchToAdmin != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: widget.onSwitchToAdmin,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEADBCA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 14,
                              color: Color(0xFF7A481B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Switch to Admin Role',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7A481B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),

                // Center: Access Restricted Card
                Center(
                  child: Container(
                    width: 500,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 42,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEADBCA),
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Lock Icon in circular warm badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF3E8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF2E7D5),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 34,
                              color: Color(0xFF8D6433),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Access Restricted',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description paragraph
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B6357),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'You don’t have permission to view ',
                              ),
                              TextSpan(
                                text: '${widget.resourceName}.',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              const TextSpan(
                                text: '\nYour current role (',
                              ),
                              TextSpan(
                                text: widget.roleName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              const TextSpan(
                                text: ') doesn’t include this permission.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action Button 1: Request Access (Dark solid espresso)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isRequestSent
                                ? null
                                : _handleRequestAccess,
                            icon: Icon(
                              _isRequestSent
                                  ? Icons.check_rounded
                                  : Icons.key_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isRequestSent
                                  ? 'Access Requested'
                                  : 'Request Access',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF231F1C),
                              disabledBackgroundColor:
                                  const Color(0xFF5E574E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action Button 2: Go to Dashboard (Outlined)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: widget.onGoToDashboard,
                            icon: const Icon(
                              Icons.home_outlined,
                              size: 16,
                              color: Color(0xFF181513),
                            ),
                            label: Text(
                              'Go to Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFDFD5C6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider line
                        const Divider(
                          height: 1,
                          color: Color(0xFFF0EAE1),
                        ),
                        const SizedBox(height: 16),

                        // Bottom Help Row: (i) Contact administrator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF7E766B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact your administrator for role changes.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Left: Security Quote
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gold bar
                      Container(
                        width: 2.5,
                        height: 38,
                        color: const Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“Right access to the right people\nkeeps your business secure.”',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 15.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A4137),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '— ThreadStock',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8C8377),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
