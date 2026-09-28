// ignore_for_file: deprecated_member_use
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';
import '../../../../core/responsive/desktop_layout.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../data/business_profile_repository.dart';

class BusinessProfileView extends StatefulWidget {
  const BusinessProfileView({
    super.key,
    this.repository,
  });

  final BusinessProfileRepository? repository;

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  late final BusinessProfileRepository _repository;

  // Business Identity
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _legalEntityController = TextEditingController();
  String _businessType = 'Apparel & Accessories Retail';
  String _registeredCountry = 'India (IN)';
  String? _currentLogoUrl;

  // Contact Matrix
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Registered Office Address
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // System Localization
  String _defaultLanguage = 'English (United States)';
  String _timezone = 'India Standard Time (GMT+5:30)';
  String _accountingCurrency = 'INR (₹) - Indian Rupee';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BusinessProfileRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final bizId = CurrentBusinessService.instance.currentBusinessId ??
        await CurrentBusinessService.instance.resolveCurrentBusinessId();
    if (bizId == null || bizId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _repository.loadProfile(businessId: bizId);
      if (!mounted) return;
      setState(() {
        if (data['display_name'] != null && (data['display_name'] as String).isNotEmpty) {
          _businessNameController.text = data['display_name'] as String;
        }
        if (data['legal_entity_name'] != null && (data['legal_entity_name'] as String).isNotEmpty) {
          _legalEntityController.text = data['legal_entity_name'] as String;
        }
        if (data['business_type'] != null) {
          _businessType = data['business_type'] as String;
        }
        if (data['registered_country'] != null) {
          _registeredCountry = data['registered_country'] as String;
        }
        if (data['email'] != null) {
          _emailController.text = data['email'] as String;
        }
        if (data['phone'] != null) {
          _phoneController.text = data['phone'] as String;
        }
        if (data['website'] != null) {
          _websiteController.text = data['website'] as String;
        }
        if (data['street_address'] != null) {
          _streetAddressController.text = data['street_address'] as String;
        }
        if (data['city'] != null) {
          _cityController.text = data['city'] as String;
        }
        if (data['postal_code'] != null) {
          _postalCodeController.text = data['postal_code'] as String;
        }
        if (data['default_language'] != null) {
          _defaultLanguage = data['default_language'] as String;
        }
        if (data['timezone'] != null) {
          _timezone = data['timezone'] as String;
        }
        if (data['primary_currency'] != null) {
          _accountingCurrency = data['primary_currency'] as String;
        }
        if (data['logo_url'] != null) {
          _currentLogoUrl = data['logo_url'] as String;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[BusinessProfileView] Error loading business profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final bizId = CurrentBusinessService.instance.currentBusinessId ??
        await CurrentBusinessService.instance.resolveCurrentBusinessId();
    if (bizId == null || bizId.isEmpty) {
      _showFeedback('No active business selected.', isError: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      final url = await _repository.uploadLogo(
        businessId: bizId,
        bytes: file.bytes!,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() {
        _currentLogoUrl = url;
        _isUploadingLogo = false;
      });
      _showFeedback('Company logo updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingLogo = false);
      _showFeedback('Error uploading logo: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    final bizId = CurrentBusinessService.instance.currentBusinessId ??
        await CurrentBusinessService.instance.resolveCurrentBusinessId();
    if (bizId == null || bizId.isEmpty) {
      _showFeedback('No active business selected.', isError: true);
      return;
    }
    if (_businessNameController.text.trim().isEmpty) {
      _showFeedback('Business Name is required.', isError: true);
      return;
    }
    if (_legalEntityController.text.trim().isEmpty) {
      _showFeedback('Legal Entity Name is required.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repository.saveProfile(
        businessId: bizId,
        displayName: _businessNameController.text.trim(),
        legalEntityName: _legalEntityController.text.trim(),
        businessType: _businessType,
        registeredCountry: _registeredCountry,
        primaryCurrency: _accountingCurrency,
        defaultLanguage: _defaultLanguage,
        timezone: _timezone,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        streetAddress: _streetAddressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showFeedback('Business profile parameters saved successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showFeedback('Failed to save business profile: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalEntityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? const Color(0xFFFCA5A5) : const Color(0xFFBA8A55),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFF991B1B) : const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(color: Color(0xFFBA8A55)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Business Profile Title + Subtitle + Save Changes CTA
              _buildHeader(),
              const SizedBox(height: 24),

              // Card 1: Business Identity & Brand Logo
              _buildBusinessIdentityCard(),
              const SizedBox(height: 18),

              // Card 2: Contact Matrix
              _buildContactMatrixCard(),
              const SizedBox(height: 18),

              // Card 3: Registered Office Address
              _buildOfficeAddressCard(),
              const SizedBox(height: 18),

              // Card 4: System Localization
              _buildLocalizationCard(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: Business Profile Title + Save Changes Button
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Profile',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update workspace identity parameters, registry addresses, contact details, and localization matrices.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Save Changes Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving ? null : _saveProfile,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF382718),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1C1A).withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.save_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
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
      ],
    );
  }

  // ========================================================
  // CARD 1: BUSINESS IDENTITY & BRAND LOGO
  // ========================================================
  Widget _buildBusinessIdentityCard() {
    return _buildCardContainer(
      icon: Icons.business_outlined,
      title: 'BUSINESS IDENTITY',
      subtitle: 'Basic information and brand assets for your business entity.',
      child: Column(
        children: [
          // Logo Upload / Display section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DCD0)),
            ),
            child: Row(
              children: [
                SafeImage(
                  source: _currentLogoUrl,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(8),
                  fallbackIcon: Icons.storefront_rounded,
                  fallbackColor: const Color(0xFFEDE5DA),
                  iconColor: const Color(0xFFBA8A55),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Brand Logo',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload your business logo for sidebar, invoices, and documents (PNG, JPG, or WEBP).',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6E665B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                  icon: _isUploadingLogo
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFBA8A55),
                          ),
                        )
                      : const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(_currentLogoUrl != null ? 'Change Logo' : 'Upload Logo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF382718),
                    side: const BorderSide(color: Color(0xFFBA8A55)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Business Name * & Legal Entity Name *
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Business Name',
                  isRequired: true,
                  controller: _businessNameController,
                  icon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'Legal Entity Name',
                  isRequired: true,
                  controller: _legalEntityController,
                  icon: Icons.storefront_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Business Type & Registered Country
          Row(
            children: [
              Expanded(
                child: _buildSelectField(
                  label: 'Business Type',
                  value: _businessType,
                  icon: Icons.storefront_outlined,
                  options: const [
                    'Apparel & Accessories Retail',
                    'Luxury Fashion Wholesale',
                    'Textile Manufacturing',
                    'Haute Couture Studio',
                  ],
                  onSelected: (val) => setState(() => _businessType = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSelectField(
                  label: 'Registered Country',
                  value: _registeredCountry,
                  icon: Icons.public_outlined,
                  options: const [
                    'India (IN)',
                    'United States (US)',
                    'United Kingdom (UK)',
                    'United Arab Emirates (AE)',
                    'Singapore (SG)',
                  ],
                  onSelected: (val) => setState(() => _registeredCountry = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 2: CONTACT MATRIX
  // ========================================================
  Widget _buildContactMatrixCard() {
    return _buildCardContainer(
      icon: Icons.phone_outlined,
      title: 'CONTACT MATRIX',
      subtitle: 'Primary contact information for operational communication.',
      child: Row(
        children: [
          // Operational Email *
          Expanded(
            child: _buildInputField(
              label: 'Operational Email',
              isRequired: true,
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(width: 16),

          // Billing Phone *
          Expanded(
            child: _buildInputField(
              label: 'Billing Phone',
              isRequired: true,
              controller: _phoneController,
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(width: 16),

          // Public Website
          Expanded(
            child: _buildInputField(
              label: 'Public Website',
              isRequired: false,
              controller: _websiteController,
              icon: Icons.link_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 3: REGISTERED OFFICE ADDRESS
  // ========================================================
  Widget _buildOfficeAddressCard() {
    return _buildCardContainer(
      icon: Icons.location_on_outlined,
      title: 'REGISTERED OFFICE ADDRESS',
      subtitle: 'Legal address registered with authorities.',
      child: Row(
        children: [
          // Street Address Line 1 *
          Expanded(
            flex: 5,
            child: _buildInputField(
              label: 'Street Address Line 1',
              isRequired: true,
              controller: _streetAddressController,
              icon: Icons.apartment_outlined,
            ),
          ),
          const SizedBox(width: 16),

          // City / Region *
          Expanded(
            flex: 4,
            child: _buildInputField(
              label: 'City / Region',
              isRequired: true,
              controller: _cityController,
              icon: Icons.location_city_outlined,
            ),
          ),
          const SizedBox(width: 16),

          // Postal Code *
          Expanded(
            flex: 3,
            child: _buildInputField(
              label: 'Postal Code',
              isRequired: true,
              controller: _postalCodeController,
              icon: Icons.mail_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 4: SYSTEM LOCALIZATION
  // ========================================================
  Widget _buildLocalizationCard() {
    return _buildCardContainer(
      icon: Icons.language_rounded,
      title: 'SYSTEM LOCALIZATION',
      subtitle: 'Regional settings for your workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of 3 Selectors
          Row(
            children: [
              // Default Language
              Expanded(
                child: _buildSelectField(
                  label: 'Default Language',
                  value: _defaultLanguage,
                  icon: Icons.translate_rounded,
                  options: const [
                    'English (United States)',
                    'English (United Kingdom)',
                    'French (Français)',
                    'Italian (Italiano)',
                  ],
                  onSelected: (val) => setState(() => _defaultLanguage = val),
                ),
              ),
              const SizedBox(width: 16),

              // Timezone
              Expanded(
                child: _buildSelectField(
                  label: 'Timezone',
                  value: _timezone,
                  icon: Icons.access_time_rounded,
                  options: const [
                    'India Standard Time (GMT+5:30)',
                    'Greenwich Mean Time (GMT+0:00)',
                    'Eastern Standard Time (GMT-5:00)',
                    'Pacific Standard Time (GMT-8:00)',
                  ],
                  onSelected: (val) => setState(() => _timezone = val),
                ),
              ),
              const SizedBox(width: 16),

              // Accounting Currency
              Expanded(
                child: _buildSelectField(
                  label: 'Accounting Currency',
                  value: _accountingCurrency,
                  icon: Icons.currency_rupee_rounded,
                  options: const [
                    'INR (₹) - Indian Rupee',
                    'USD (\$) - US Dollar',
                    'EUR (€) - Euro',
                    'GBP (£) - British Pound',
                  ],
                  onSelected: (val) {
                    setState(() => _accountingCurrency = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bottom Info Note Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFFBA8A55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes will be applied to your workspace settings and may affect data formatting, reports, and user experience.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF756C60),
                      fontWeight: FontWeight.w400,
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

  // ========================================================
  // REUSABLE CARD CONTAINER
  // ========================================================
  Widget _buildCardContainer({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: const Color(0xFFBA8A55)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ========================================================
  // REUSABLE INPUT FIELD
  // ========================================================
  Widget _buildInputField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF474035),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC0392B),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD6C9)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF7A7268)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================
  // REUSABLE SELECT DROPDOWN FIELD
  // ========================================================
  Widget _buildSelectField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final effectiveOptions = options.contains(value) || value.isEmpty
        ? options
        : [value, ...options];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF474035),
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          onSelected: onSelected,
          color: const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDFD4C5)),
          ),
          itemBuilder: (ctx) => effectiveOptions.map((opt) {
            final isSelected = opt == value;
            return PopupMenuItem<String>(
              value: opt,
              height: 38,
              child: Row(
                children: [
                  Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF1E1C1A)
                          : const Color(0xFF4A4237),
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD6C9)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF7A7268)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B6358),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
