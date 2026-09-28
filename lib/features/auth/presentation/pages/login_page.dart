// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/business/app_bootstrap_service.dart';
import '../../../../core/navigation/navigation_guard.dart';

// ---------------------------------------------------------------------------
// Country / ISD data
// ---------------------------------------------------------------------------
class _IsdCountry {
  const _IsdCountry({required this.name, required this.flag, required this.dial});
  final String name;
  final String flag;
  final String dial; // e.g. '+91'
}

const List<_IsdCountry> _kCountries = [
  _IsdCountry(name: 'India', flag: '🇮🇳', dial: '+91'),
  _IsdCountry(name: 'United States', flag: '🇺🇸', dial: '+1'),
  _IsdCountry(name: 'United Kingdom', flag: '🇬🇧', dial: '+44'),
  _IsdCountry(name: 'United Arab Emirates', flag: '🇦🇪', dial: '+971'),
  _IsdCountry(name: 'Canada', flag: '🇨🇦', dial: '+1'),
  _IsdCountry(name: 'Australia', flag: '🇦🇺', dial: '+61'),
  _IsdCountry(name: 'Singapore', flag: '🇸🇬', dial: '+65'),
  _IsdCountry(name: 'Saudi Arabia', flag: '🇸🇦', dial: '+966'),
  _IsdCountry(name: 'Qatar', flag: '🇶🇦', dial: '+974'),
  _IsdCountry(name: 'Kuwait', flag: '🇰🇼', dial: '+965'),
  _IsdCountry(name: 'Bahrain', flag: '🇧🇭', dial: '+973'),
  _IsdCountry(name: 'Oman', flag: '🇴🇲', dial: '+968'),
  _IsdCountry(name: 'Pakistan', flag: '🇵🇰', dial: '+92'),
  _IsdCountry(name: 'Bangladesh', flag: '🇧🇩', dial: '+880'),
  _IsdCountry(name: 'Sri Lanka', flag: '🇱🇰', dial: '+94'),
  _IsdCountry(name: 'Nepal', flag: '🇳🇵', dial: '+977'),
  _IsdCountry(name: 'Germany', flag: '🇩🇪', dial: '+49'),
  _IsdCountry(name: 'France', flag: '🇫🇷', dial: '+33'),
  _IsdCountry(name: 'Italy', flag: '🇮🇹', dial: '+39'),
  _IsdCountry(name: 'Spain', flag: '🇪🇸', dial: '+34'),
  _IsdCountry(name: 'Japan', flag: '🇯🇵', dial: '+81'),
  _IsdCountry(name: 'South Korea', flag: '🇰🇷', dial: '+82'),
  _IsdCountry(name: 'China', flag: '🇨🇳', dial: '+86'),
  _IsdCountry(name: 'Malaysia', flag: '🇲🇾', dial: '+60'),
  _IsdCountry(name: 'Indonesia', flag: '🇮🇩', dial: '+62'),
  _IsdCountry(name: 'Thailand', flag: '🇹🇭', dial: '+66'),
  _IsdCountry(name: 'South Africa', flag: '🇿🇦', dial: '+27'),
  _IsdCountry(name: 'Nigeria', flag: '🇳🇬', dial: '+234'),
  _IsdCountry(name: 'Kenya', flag: '🇰🇪', dial: '+254'),
  _IsdCountry(name: 'Ghana', flag: '🇬🇭', dial: '+233'),
];

// ---------------------------------------------------------------------------
// Main LoginPage
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _OtpStep { enterPhone, enterCode }

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Password-flow
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Mobile/OTP flow
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  _IsdCountry _selectedCountry = _kCountries.first; // India (+91)
  _OtpStep _otpStep = _OtpStep.enterPhone;
  String? _pendingPhone; // E.164 phone that OTP was sent to

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && _tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  String _toE164(String localNumber) {
    final stripped = localNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (stripped.startsWith('+')) return stripped;
    final digits = stripped.replaceAll(RegExp(r'^\+?0+'), '');
    return '${_selectedCountry.dial}$digits';
  }

  Future<void> _navigateAfterAuth() async {
    final bootstrap = await AppBootstrapService.bootstrap();
    if (!mounted) return;
    await NavigationGuard.safePushReplacementNamed(
      context,
      bootstrap.initialRoute,
      source: 'LoginPage._navigateAfterAuth',
    );
  }

  void _setError(String? msg) {
    if (mounted) setState(() => _errorMessage = msg);
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  // -------------------------------------------------------------------------
  // Password Login
  // -------------------------------------------------------------------------
  Future<void> _handlePasswordLogin() async {
    if (_isLoading) return;
    _setError(null);
    if (!_passwordFormKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await AuthService.instance.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------------------------------------------------------
  // OTP — Send
  // -------------------------------------------------------------------------
  Future<void> _handleSendOtp() async {
    if (_isLoading) return;
    _setError(null);
    if (!_otpFormKey.currentState!.validate()) return;
    final phone = _toE164(_phoneController.text.trim());
    _setLoading(true);
    try {
      final sb = Supabase.instance.client;
      await sb.auth.signInWithOtp(phone: phone);
      if (mounted) {
        setState(() {
          _pendingPhone = phone;
          _otpStep = _OtpStep.enterCode;
          _otpController.clear();
          _errorMessage = null;
        });
      }
    } on AuthException catch (e) {
      // Supabase Phone auth not configured → surface backend requirement
      if (e.message.toLowerCase().contains('provider') ||
          e.message.toLowerCase().contains('not enabled') ||
          e.message.toLowerCase().contains('sms') ||
          e.message.toLowerCase().contains('phone')) {
        _setError(
          'BACKEND CONFIGURATION REQUIRED\n\n'
          'Phone / SMS authentication is not enabled in your Supabase project. '
          'Enable the Phone provider and configure an SMS gateway in '
          'Supabase → Authentication → Providers → Phone.',
        );
      } else {
        _setError(e.message);
      }
    } catch (e) {
      _setError(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------------------------------------------------------
  // OTP — Verify
  // -------------------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    if (_isLoading) return;
    _setError(null);
    final code = _otpController.text.trim();
    if (code.length < 4) {
      _setError('Enter the OTP sent to $_pendingPhone');
      return;
    }
    _setLoading(true);
    try {
      final sb = Supabase.instance.client;
      await sb.auth.verifyOTP(
        type: OtpType.sms,
        phone: _pendingPhone!,
        token: code,
      );
      if (!mounted) return;
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  // Progress Bar for Step 1
  // -------------------------------------------------------------------------
  Widget _buildLoginProgressBar() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '0% completed',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A7062),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 100,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D9CC),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '|',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFFD0C4B4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '6 of 6 steps left',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A7062),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF141312) : ThreadStockTheme.ivory;
    final cardColor = isDark ? const Color(0xFF1E1C1A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF332F2A) : const Color(0xFFE7DFC7);
    final primaryText =
        isDark ? const Color(0xFFF6F1EA) : ThreadStockTheme.graphite;
    final secondaryText =
        isDark ? const Color(0xFFA69F94) : const Color(0xFF6B655B);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 480;
    final horizontalScreenPadding = isCompact ? 16.0 : 24.0;
    final horizontalCardPadding = isCompact ? 20.0 : 36.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalScreenPadding,
            vertical: isCompact ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalCardPadding,
                isCompact ? 24 : 36,
                horizontalCardPadding,
                isCompact ? 24 : 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Brand crest ----
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ThreadStockTheme.champagne
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ThreadStockTheme.champagne
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        color: ThreadStockTheme.champagne,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ---- Step 1 Tag ----
                  Center(
                    child: Text(
                      'STEP 1 OF 6 — LOGIN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: ThreadStockTheme.champagne,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ---- Brand name ----
                  Text(
                    'THREADSTOCK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Workspace: New Business Setup',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Compact Progress Bar ----
                  _buildLoginProgressBar(),
                  const SizedBox(height: 20),

                  // ---- Tab selector ----
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF282522)
                          : const Color(0xFFF4EFE6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      key: const Key('login_tab_bar'),
                      controller: _tabController,
                      onTap: (index) {
                        if (_selectedTabIndex != index) {
                          setState(() {
                            _selectedTabIndex = index;
                            _errorMessage = null;
                          });
                        }
                      },
                      indicator: BoxDecoration(
                        color: ThreadStockTheme.champagne,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: secondaryText,
                      tabs: const [
                        Tab(key: Key('tab_password'), text: 'Password'),
                        Tab(key: Key('tab_otp'), text: 'Mobile OTP'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- Error banner ----
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(_errorMessage!),
                    const SizedBox(height: 18),
                  ],

                  // ---- Tab body ----
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    child: _selectedTabIndex == 0
                        ? KeyedSubtree(
                            key: const ValueKey('password_form_view'),
                            child: _buildPasswordTab(
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              isDark: isDark,
                            ),
                          )
                        : KeyedSubtree(
                            key: ValueKey('otp_form_view_${_otpStep.name}'),
                            child: _buildOtpTab(
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              isDark: isDark,
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

  // -------------------------------------------------------------------------
  // Password tab
  // -------------------------------------------------------------------------
  Widget _buildPasswordTab({
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required bool isDark,
  }) {
    final fillColor =
        isDark ? const Color(0xFF282522) : const Color(0xFFFAF7F2);
    return Form(
      key: _passwordFormKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('Email Address', primaryText),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('login_email_input'),
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(fontSize: 14, color: primaryText),
              decoration: _inputDecoration(
                hint: 'merchant@domain.com',
                prefixIcon: Icons.mail_outline_rounded,
                borderColor: borderColor,
                fillColor: fillColor,
                secondaryText: secondaryText,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your email address.';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Password row with Forgot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _fieldLabel('Password', primaryText)),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('login_forgot_password_link'),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.forgotPassword),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThreadStockTheme.champagne,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('login_password_input'),
              controller: _passwordController,
              autofillHints: const [AutofillHints.password],
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handlePasswordLogin(),
              style: GoogleFonts.inter(fontSize: 14, color: primaryText),
              decoration: _inputDecoration(
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                borderColor: borderColor,
                fillColor: fillColor,
                secondaryText: secondaryText,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: secondaryText,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password.';
                return null;
              },
            ),
            const SizedBox(height: 26),

            _primaryButton(
              key: const Key('login_submit_button'),
              label: 'Sign In',
              onPressed: _handlePasswordLogin,
            ),
            const SizedBox(height: 20),
            _buildFooterLinks(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // OTP tab
  // -------------------------------------------------------------------------
  Widget _buildOtpTab({
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required bool isDark,
  }) {
    final fillColor =
        isDark ? const Color(0xFF282522) : const Color(0xFFFAF7F2);

    if (_otpStep == _OtpStep.enterPhone) {
      return Form(
        key: _otpFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('Mobile Number', primaryText),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ISD / country picker
                GestureDetector(
                  key: const Key('login_isd_picker'),
                  onTap: () => _showCountryPicker(context, primaryText,
                      secondaryText, borderColor, isDark),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCountry.dial,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: secondaryText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('login_phone_input'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\-\(\)]')),
                    ],
                    onFieldSubmitted: (_) => _handleSendOtp(),
                    style: GoogleFonts.inter(fontSize: 14, color: primaryText),
                    decoration: _inputDecoration(
                      hint: '98765 43210',
                      prefixIcon: Icons.phone_outlined,
                      borderColor: borderColor,
                      fillColor: fillColor,
                      secondaryText: secondaryText,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your mobile number.';
                      }
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 6 || digits.length > 15) {
                        return 'Enter a valid mobile number.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _primaryButton(
              key: const Key('login_send_otp_button'),
              label: 'Send OTP',
              onPressed: _handleSendOtp,
            ),
            const SizedBox(height: 20),
            _buildFooterLinks(),
          ],
        ),
      );
    }

    // --- OTP entry screen ---
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF22543D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sms_outlined,
                color: Color(0xFF22543D), size: 24),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your OTP',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A one-time code was sent to\n$_pendingPhone',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, color: secondaryText, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextFormField(
          key: const Key('login_otp_input'),
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => _handleVerifyOtp(),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            color: primaryText,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '······',
            hintStyle: GoogleFonts.inter(
              fontSize: 24,
              letterSpacing: 8,
              color: secondaryText.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF282522)
                : const Color(0xFFFAF7F2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
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
        _primaryButton(
          key: const Key('login_verify_otp_button'),
          label: 'Verify & Sign In',
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            key: const Key('login_otp_back_button'),
            onPressed: () {
              setState(() {
                _otpStep = _OtpStep.enterPhone;
                _pendingPhone = null;
                _otpController.clear();
                _errorMessage = null;
              });
            },
            child: Text(
              '← Change number',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ThreadStockTheme.champagne,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Country picker
  // -------------------------------------------------------------------------
  void _showCountryPicker(
    BuildContext context,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    bool isDark,
  ) {
    showDialog<_IsdCountry>(
      context: context,
      builder: (ctx) => _CountryPickerDialog(
        countries: _kCountries,
        selected: _selectedCountry,
        primaryText: primaryText,
        secondaryText: secondaryText,
        borderColor: borderColor,
        isDark: isDark,
      ),
    ).then((c) {
      if (c != null && mounted) {
        setState(() => _selectedCountry = c);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Shared widgets
  // -------------------------------------------------------------------------
  Widget _fieldLabel(String label, Color color) => Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required Color borderColor,
    required Color fillColor,
    required Color secondaryText,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryText.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(prefixIcon, size: 19, color: secondaryText),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: ThreadStockTheme.champagne, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF8B4B4)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF8B4B4), width: 1.4),
        ),
      );

  Widget _primaryButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        height: 48,
        child: ElevatedButton(
          key: key,
          onPressed: _isLoading ? null : onPressed,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      );

  Widget _buildErrorBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF8B4B4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline_rounded,
                  color: Color(0xFF9B1C1C), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9B1C1C),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFooterLinks() => Column(
        children: [
          GestureDetector(
            key: const Key('login_forgot_password_bottom'),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            child: Text(
              'Forgot Password',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ThreadStockTheme.champagne,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B655B),
                ),
              ),
              GestureDetector(
                key: const Key('login_signup_link'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.signup),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThreadStockTheme.champagne,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Country picker dialog
// ---------------------------------------------------------------------------
class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({
    required this.countries,
    required this.selected,
    required this.primaryText,
    required this.secondaryText,
    required this.borderColor,
    required this.isDark,
  });

  final List<_IsdCountry> countries;
  final _IsdCountry selected;
  final Color primaryText;
  final Color secondaryText;
  final Color borderColor;
  final bool isDark;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  String _query = '';

  List<_IsdCountry> get _filtered => _query.isEmpty
      ? widget.countries
      : widget.countries.where((c) {
          final q = _query.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.dial.contains(q) ||
              c.flag.contains(q);
        }).toList();

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDark ? const Color(0xFF1E1C1A) : Colors.white;
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Country',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('country_search_input'),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search country or dial code…',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: widget.secondaryText),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: widget.secondaryText),
                      filled: true,
                      fillColor: widget.isDark
                          ? const Color(0xFF282522)
                          : const Color(0xFFF4EFE6),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: widget.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: widget.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ThreadStockTheme.champagne,
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
                  final isSelected = c.dial == widget.selected.dial &&
                      c.name == widget.selected.name;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Text(c.flag,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              c.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: widget.primaryText,
                              ),
                            ),
                          ),
                          Text(
                            c.dial,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: widget.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: ThreadStockTheme.champagne,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
