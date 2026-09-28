import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/authorization_service.dart';
import '../../core/business/app_bootstrap_service.dart';
import '../../core/business/current_business_service.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Luxury splash / loading shell displayed while authoritative bootstrap is in progress.
///
/// Prevents premature rendering of onboarding steps (e.g. Step 1 or Step 4)
/// before the authoritative database status of the user's business is resolved.
class AppLoadingShell extends StatefulWidget {
  const AppLoadingShell({this.targetRoute, super.key});

  final String? targetRoute;

  @override
  State<AppLoadingShell> createState() => _AppLoadingShellState();
}

class _AppLoadingShellState extends State<AppLoadingShell> {
  bool _isResolving = false;
  bool _redirectScheduled = false;
  String? _errorMessage;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _resolveBootstrap();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveBootstrap() async {
    if (_isResolving || AppBootstrapService.isBootstrapping || _redirectScheduled) return;
    setState(() {
      _isResolving = true;
      _errorMessage = null;
    });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isResolving && !_redirectScheduled) {
        setState(() {
          _isResolving = false;
          _errorMessage = 'Workspace loading timed out. Tap to retry.';
        });
      }
    });

    try {
      final String destination;
      if (!AppBootstrapService.isBootstrapped) {
        final result = await AppBootstrapService.bootstrap();
        if (!mounted) return;

        if (!AuthService.instance.isAuthenticated) {
          destination = AppRoutes.login;
        } else if (result.isOnboardingComplete) {
          destination = widget.targetRoute != null &&
                  !_isOnboardingRoute(widget.targetRoute!)
              ? widget.targetRoute!
              : AppRoutes.overview;
        } else {
          destination = result.initialRoute;
        }
      } else {
        if (!mounted) return;
        final lastResult = AppBootstrapService.lastResult;
        if (lastResult != null && lastResult.isOnboardingComplete) {
          destination = widget.targetRoute != null &&
                  !_isOnboardingRoute(widget.targetRoute!)
              ? widget.targetRoute!
              : AppRoutes.overview;
        } else if (lastResult != null) {
          destination = lastResult.initialRoute;
        } else {
          destination = AppRoutes.overview;
        }
      }

      _timeoutTimer?.cancel();
      if (_redirectScheduled || !mounted) return;
      _redirectScheduled = true;
      await NavigationGuard.safePushReplacementNamed(
        context,
        destination,
        source: 'AppLoadingShell._resolveBootstrap',
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isResolving = false;
          _errorMessage = 'Failed to load workspace. Tap to retry.';
        });
      }
    }
  }

  bool _isOnboardingRoute(String route) {
    return route.startsWith('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141312) : ThreadStockTheme.ivory;
    final primaryTextColor = isDark ? const Color(0xFFF6F1EA) : ThreadStockTheme.graphite;
    final secondaryTextColor = isDark ? const Color(0xFFA69F94) : const Color(0xFF6B655B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ThreadStockTheme.champagne.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThreadStockTheme.champagne.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: ThreadStockTheme.champagne,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'THREADSTOCK',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparing luxury workspace…',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _resolveBootstrap,
                  child: const Text('Retry'),
                ),
              ] else ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThreadStockTheme.champagne,
                    ),
                  ),
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAGNOSTICS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('currentBusinessId: ${CurrentBusinessService.instance.currentBusinessId ?? "none"}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                      Text('onboarding status: ${OnboardingRepository.instance.currentProgress.isOnboardingCompleted ? "complete" : "in_progress"}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                      Text('authorization ready: ${AuthorizationService.instance.isOwner || AuthorizationService.instance.permissions.isNotEmpty}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                      Text('currentLocationId: ${CurrentBusinessService.instance.currentLocationId ?? "none"}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                      Text('target route: ${widget.targetRoute ?? NavigationGuard.currentRoute ?? "unknown"}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                      Text('navigation lock: ${NavigationGuard.isNavigating}', style: GoogleFonts.robotoMono(fontSize: 9.5, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
