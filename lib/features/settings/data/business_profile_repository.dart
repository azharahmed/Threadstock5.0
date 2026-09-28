import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/business/current_business_service.dart';
import '../../../core/config/app_preferences_service.dart';

class BusinessProfileRepository {
  BusinessProfileRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// In-memory cache for test/offline environments
  static final Map<String, Map<String, dynamic>> _inMemoryProfiles = {};

  static String _formatCountryOption(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return 'India (IN)';
    final code = countryCode.trim().toUpperCase();
    switch (code) {
      case 'IN':
        return 'India (IN)';
      case 'US':
        return 'United States (US)';
      case 'GB':
      case 'UK':
        return 'United Kingdom (UK)';
      case 'AE':
        return 'United Arab Emirates (AE)';
      case 'SG':
        return 'Singapore (SG)';
      default:
        return 'India (IN)';
    }
  }

  static String _formatCurrencyOption(String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return 'INR (₹) - Indian Rupee';
    }
    final code = currencyCode.trim().toUpperCase();
    switch (code) {
      case 'INR':
        return 'INR (₹) - Indian Rupee';
      case 'USD':
        return 'USD (\$) - US Dollar';
      case 'GBP':
        return 'GBP (£) - British Pound';
      case 'EUR':
        return 'EUR (€) - Euro';
      case 'AED':
        return 'AED (د.إ) - UAE Dirham';
      case 'SGD':
        return 'SGD (\$) - Singapore Dollar';
      default:
        return '$code - $code';
    }
  }

  /// Loads business profile from `businesses`, `business_profile_settings`, and preferences/storage.
  /// Falls back authoritatively to `businesses` table and `CurrentBusinessService`.
  Future<Map<String, dynamic>> loadProfile({required String businessId}) async {
    final sb = _resolvedClient;

    // Resolve active business context as authoritative fallback
    final activeBiz = (CurrentBusinessService.instance.currentBusinessId == businessId ||
            CurrentBusinessService.instance.currentBusiness?.id == businessId)
        ? CurrentBusinessService.instance.currentBusiness
        : null;

    Map<String, dynamic>? bizRow;
    Map<String, dynamic>? profileRow;
    String? logoUrl = AppPreferencesService.instance.getCompanyLogoUrl(businessId);

    if (sb != null && sb.auth.currentUser != null) {
      try {
        // 1. Fetch from businesses
        bizRow = await sb
            .from('businesses')
            .select('id, legal_name, business_type, country_code, currency_code, location_range')
            .eq('id', businessId)
            .maybeSingle();

        // 2. Fetch from business_profile_settings
        profileRow = await sb
            .from('business_profile_settings')
            .select()
            .eq('business_id', businessId)
            .maybeSingle();

        // 3. Resolve logo
        if (logoUrl == null || logoUrl.isEmpty) {
          try {
            final files = await sb.storage.from('product-media').list(path: '$businessId/company');
            if (files.isNotEmpty) {
              files.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
              final latestFile = files.first;
              logoUrl = sb.storage
                  .from('product-media')
                  .getPublicUrl('$businessId/company/${latestFile.name}');
              await AppPreferencesService.instance.setCompanyLogoUrl(businessId, logoUrl);
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('[BusinessProfileRepository] loadProfile error: $e');
      }
    }

    final cached = _inMemoryProfiles[businessId] ?? {};

    // Authoritative fallback values from businesses / CurrentBusiness
    final fallbackLegalName = bizRow?['legal_name'] as String? ?? activeBiz?.legalName ?? '';
    final fallbackBusinessType = bizRow?['business_type'] as String? ?? activeBiz?.businessType ?? 'Apparel & Accessories Retail';
    final rawCountry = bizRow?['country_code'] as String? ?? activeBiz?.countryCode ?? 'IN';
    final rawCurrency = bizRow?['currency_code'] as String? ?? activeBiz?.currencyCode ?? 'INR';

    final result = <String, dynamic>{
      'business_id': businessId,
      'display_name': profileRow?['display_name'] ??
          cached['display_name'] ??
          (fallbackLegalName.isNotEmpty ? fallbackLegalName : ''),
      'legal_entity_name': profileRow?['legal_entity_name'] ??
          cached['legal_entity_name'] ??
          (fallbackLegalName.isNotEmpty ? fallbackLegalName : ''),
      'business_type': profileRow?['business_type'] ??
          cached['business_type'] ??
          fallbackBusinessType,
      'registered_country': profileRow?['registered_country'] ??
          cached['registered_country'] ??
          _formatCountryOption(rawCountry),
      'primary_currency': profileRow?['primary_currency'] ??
          cached['primary_currency'] ??
          _formatCurrencyOption(rawCurrency),
      'default_language': profileRow?['default_language'] ??
          cached['default_language'] ??
          'English (United States)',
      'timezone': profileRow?['timezone'] ??
          cached['timezone'] ??
          'India Standard Time (GMT+5:30)',
      'email': profileRow?['email'] ?? cached['email'] ?? '',
      'phone': profileRow?['phone'] ?? cached['phone'] ?? '',
      'website': profileRow?['website'] ?? cached['website'] ?? '',
      'street_address': profileRow?['street_address'] ?? cached['street_address'] ?? '',
      'city': profileRow?['city'] ?? cached['city'] ?? '',
      'postal_code': profileRow?['postal_code'] ?? cached['postal_code'] ?? '',
      if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
    };

    _inMemoryProfiles[businessId] = result;
    return result;
  }

  /// Persists business profile updates to `businesses` and `business_profile_settings`.
  Future<void> saveProfile({
    required String businessId,
    required String displayName,
    required String legalEntityName,
    required String businessType,
    required String registeredCountry,
    required String primaryCurrency,
    required String defaultLanguage,
    required String timezone,
    required String email,
    required String phone,
    required String website,
    required String streetAddress,
    required String city,
    required String postalCode,
  }) async {
    final sb = _resolvedClient;

    final profileData = {
      'business_id': businessId,
      'display_name': displayName.trim(),
      'legal_entity_name': legalEntityName.trim(),
      'business_type': businessType.trim(),
      'registered_country': registeredCountry.trim(),
      'primary_currency': primaryCurrency.trim(),
      'default_language': defaultLanguage.trim(),
      'timezone': timezone.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'website': website.trim(),
      'street_address': streetAddress.trim(),
      'city': city.trim(),
      'postal_code': postalCode.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (sb != null && sb.auth.currentUser != null) {
      // 1. Update businesses table legal_name and updated_at
      try {
        await sb
            .from('businesses')
            .update({
              'legal_name': legalEntityName.trim(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', businessId);
      } catch (e) {
        debugPrint('[BusinessProfileRepository] businesses update error: $e');
      }

      // 2. Upsert into business_profile_settings (authoritative settings table)
      await sb.from('business_profile_settings').upsert(
        profileData,
        onConflict: 'business_id',
      );

      // 3. Re-resolve authoritative business in CurrentBusinessService
      await CurrentBusinessService.instance.resolveCurrentBusinessId(forceRefresh: true);
    }

    _inMemoryProfiles[businessId] = {
      ..._inMemoryProfiles[businessId] ?? {},
      ...profileData,
    };
  }

  /// Uploads a company logo file to Supabase Storage bucket 'product-media'.
  Future<String> uploadLogo({
    required String businessId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$businessId/company/logo_${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      final ext = fileName.split('.').last.toLowerCase();
      String contentType = 'image/png';
      if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'svg') {
        contentType = 'image/svg+xml';
      }

      await sb.storage.from('product-media').uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = sb.storage.from('product-media').getPublicUrl(storagePath);
      await AppPreferencesService.instance.setCompanyLogoUrl(businessId, publicUrl);

      // Invalidate business service so UI listeners refresh
      await CurrentBusinessService.instance.resolveCurrentBusinessId(forceRefresh: true);

      return publicUrl;
    }

    // In-memory / offline mock fallback
    final mockUrl = 'mock_logo_${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
    await AppPreferencesService.instance.setCompanyLogoUrl(businessId, mockUrl);
    return mockUrl;
  }
}
