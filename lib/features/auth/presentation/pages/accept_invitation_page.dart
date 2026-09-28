import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../../../core/business/current_business_service.dart';
import '../../../../core/navigation/navigation_guard.dart';

class AcceptInvitationPage extends StatefulWidget {
  const AcceptInvitationPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isWrongEmail = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tokenController.text.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _tokenController.text = args;
      } else if (args is Map && args['token'] is String) {
        _tokenController.text = args['token'] as String;
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide an invitation token.';
        _successMessage = null;
        _isWrongEmail = false;
      });
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'You must be signed in to accept an invitation.';
        _successMessage = null;
        _isWrongEmail = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _isWrongEmail = false;
    });

    try {
      final sb = Supabase.instance.client;
      final response = await sb.rpc(
        'accept_team_invitation',
        params: {
          'payload': {'token': token},
        },
      );

      final result = response is Map ? Map<String, dynamic>.from(response) : null;
      final acceptedBizId = result?['business_id'] as String?;

      if (acceptedBizId != null && acceptedBizId.isNotEmpty) {
        // Refresh business & authorization context
        await CurrentBusinessService.instance.resolveCurrentBusinessId(
          forceRefresh: true,
        );
        CurrentBusinessService.instance.setCurrentBusinessId(acceptedBizId);
        await AuthorizationService.instance.refreshAuthorization(
          businessId: acceptedBizId,
        );

        if (!mounted) return;

        setState(() {
          _successMessage = 'Invitation accepted! Redirecting to workspace...';
        });

        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        await NavigationGuard.safePushReplacementNamed(
          context,
          AppRoutes.overview,
          source: 'AcceptInvitationPage._handleAccept.success',
        );
      } else {
        setState(() {
          _errorMessage = 'Invitation accepted but business resolution was incomplete.';
        });
      }
    } on PostgrestException catch (pe) {
      final msg = pe.message.toLowerCase();
      final isEmailIssue = msg.contains('email') ||
          msg.contains('not match') ||
          msg.contains('recipient');

      setState(() {
        _isWrongEmail = isEmailIssue;
        if (msg.contains('location is no longer available')) {
          _errorMessage =
              'The assigned location for this invitation has been deleted. Invitation cannot be accepted.';
        } else if (msg.contains('already accepted')) {
          _errorMessage = 'This invitation has already been accepted.';
        } else if (msg.contains('expired')) {
          _errorMessage = 'This invitation has expired.';
        } else if (msg.contains('revoked')) {
          _errorMessage = 'This invitation was revoked by the workspace owner.';
        } else if (msg.contains('invalid') || msg.contains('not found')) {
          _errorMessage = 'The invitation token is invalid or does not exist.';
        } else {
          _errorMessage = pe.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
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
            constraints: const BoxConstraints(maxWidth: 480),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: ThreadStockTheme.champagne.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ThreadStockTheme.champagne.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: ThreadStockTheme.champagne,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'TEAM INVITATION',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Accept your workspace invitation to begin collaborating',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (user == null) ...[
                    // Not signed in state
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ThreadStockTheme.champagne.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ThreadStockTheme.champagne.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock_person_outlined,
                            color: ThreadStockTheme.champagne,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign In Required',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please sign in or create an account with the email address where you received the invitation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('invite_signin_button'),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(AppRoutes.login);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryTextColor,
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('invite_signup_button'),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(AppRoutes.signup);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThreadStockTheme.champagne,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Create Account'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Signed in indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282522) : const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: Color(0xFF0E9F6E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Signed in as: ${user.email ?? user.id}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFF9B1C1C),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF9B1C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isWrongEmail) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                key: const Key('invite_switch_account_link'),
                                onTap: () async {
                                  await AuthService.instance.signOut();
                                  if (context.mounted) {
                                    await NavigationGuard.safePushReplacementNamed(
                                      context,
                                      AppRoutes.login,
                                      source: 'AcceptInvitationPage.switchAccount',
                                    );
                                  }
                                },
                                child: Text(
                                  'Switch Account →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9B1C1C),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF7EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBCF0DA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              color: Color(0xFF0E9F6E),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0E9F6E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    Text(
                      'Invitation Token',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('invite_token_input'),
                      controller: _tokenController,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste 32-byte hex token',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: secondaryTextColor.withValues(alpha: 0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.vpn_key_outlined,
                          size: 18,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF282522)
                            : const Color(0xFFFAF7F2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThreadStockTheme.champagne,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('invite_accept_button'),
                        onPressed: _isLoading ? null : _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThreadStockTheme.champagne,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              ThreadStockTheme.champagne.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Accept Workspace Invitation',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
