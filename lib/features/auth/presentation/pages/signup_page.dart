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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final username = _usernameController.text.trim().toLowerCase();
      final mobile = _mobileController.text.trim();

      final response = await AuthService.instance.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username.isEmpty ? null : username,
        phone: mobile.isEmpty ? null : mobile,
      );

      if (!mounted) return;

      if (response.session == null) {
        // Confirmation email required
        await NavigationGuard.safePushReplacementNamed(
          context,
          AppRoutes.checkEmail,
          arguments: email,
          source: 'SignupPage._handleSignup.checkEmail',
        );
      } else {
        // User session immediately active -> bootstrap & route to onboarding or dashboard
        final bootstrap = await AppBootstrapService.bootstrap();
        if (!mounted) return;
        await NavigationGuard.safePushReplacementNamed(
          context,
          bootstrap.initialRoute,
          source: 'SignupPage._handleSignup.sessionActive',
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
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
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: ThreadStockTheme.champagne.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ThreadStockTheme.champagne.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_add_outlined,
                            color: ThreadStockTheme.champagne,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'CREATE ACCOUNT',
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
                        'Establish your ThreadStock merchant identity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 26),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF8B4B4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFF9B1C1C),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
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
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Full name input
                      Text(
                        'Full Name',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_fullname_input'),
                        controller: _fullNameController,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Azhar Ahmed',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            size: 19,
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter your full name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Username input
                      Text(
                        'Username',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_username_input'),
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_]')),
                          LengthLimitingTextInputFormatter(30),
                        ],
                        onChanged: (v) {
                          final lower = v.toLowerCase();
                          if (v != lower) {
                            _usernameController.value =
                                _usernameController.value.copyWith(
                                  text: lower,
                                  selection: TextSelection.collapsed(
                                      offset: lower.length),
                                );
                          }
                        },
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. azhar_merchant',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            size: 19,
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
                          helperText:
                              'Lowercase, letters/numbers/underscore, 3–30 chars.',
                          helperStyle: GoogleFonts.inter(
                              fontSize: 11, color: secondaryTextColor),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Choose a username.';
                          }
                          final v2 = val.trim();
                          if (v2.length < 3) {
                            return 'Username must be at least 3 characters.';
                          }
                          if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v2)) {
                            return 'Only lowercase letters, numbers and _ allowed.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email input
                      Text(
                        'Email Address',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_email_input'),
                        controller: _emailController,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'merchant@domain.com',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 19,
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter your email address.';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mobile number (optional)
                      Text(
                        'Mobile Number (optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_mobile_input'),
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\+\s\-\(\)]')),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            size: 19,
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
                          helperText: 'Include country code, e.g. +91',
                          helperStyle: GoogleFonts.inter(
                              fontSize: 11, color: secondaryTextColor),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null; // optional
                          }
                          final digits = val.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 6 || digits.length > 15) {
                            return 'Enter a valid mobile number with country code.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      Text(
                        'Password',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_password_input'),
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'At least 8 characters',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                            color: secondaryTextColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 19,
                              color: secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter a password.';
                          }
                          if (val.length < 8) {
                            return 'Password must be at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password input
                      Text(
                        'Confirm Password',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('signup_confirm_password_input'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignup(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_reset_rounded,
                            size: 19,
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
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),

                      // Submit button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('signup_submit_button'),
                          onPressed: _isLoading ? null : _handleSignup,
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
                                  'Create Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                          GestureDetector(
                            key: const Key('signup_login_link'),
                            onTap: () {
                              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                            },
                            child: Text(
                              'Sign in',
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
