import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final routeEmail = ModalRoute.of(context)?.settings.arguments as String?;
    final displayEmail = email ?? routeEmail ?? 'your email address';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF141312) : ThreadStockTheme.ivory;
    final cardColor = isDark ? const Color(0xFF1E1C1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF332F2A) : const Color(0xFFE7DFC7);
    final primaryTextColor = isDark ? const Color(0xFFF6F1EA) : ThreadStockTheme.graphite;
    final secondaryTextColor = isDark ? const Color(0xFFA69F94) : const Color(0xFF6B655B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ThreadStockTheme.champagne.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThreadStockTheme.champagne.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: ThreadStockTheme.champagne,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'CHECK YOUR INBOX',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'We have dispatched instructions to\n',
                        ),
                        TextSpan(
                          text: displayEmail,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const TextSpan(
                          text: '.\nPlease inspect your inbox or spam directory to continue.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('check_email_login_button'),
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThreadStockTheme.champagne,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Return to Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
