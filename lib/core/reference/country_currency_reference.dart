import 'package:flutter/material.dart';

class CountryCurrencyProfile {
  const CountryCurrencyProfile({
    required this.countryCode,
    required this.countryName,
    required this.primaryCurrencyCode,
  });

  final String countryCode;
  final String countryName;
  final String primaryCurrencyCode;
}

class CountryCurrencyReference {
  static const List<String> supportedCurrencies = [
    'INR',
    'USD',
    'GBP',
    'AED',
    'JPY',
    'AUD',
    'CAD',
    'EUR',
    'SGD',
  ];

  static const List<CountryCurrencyProfile> supportedCountries = [
    CountryCurrencyProfile(
      countryCode: 'IN',
      countryName: 'India',
      primaryCurrencyCode: 'INR',
    ),
    CountryCurrencyProfile(
      countryCode: 'US',
      countryName: 'United States',
      primaryCurrencyCode: 'USD',
    ),
    CountryCurrencyProfile(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      primaryCurrencyCode: 'GBP',
    ),
    CountryCurrencyProfile(
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      primaryCurrencyCode: 'AED',
    ),
    CountryCurrencyProfile(
      countryCode: 'JP',
      countryName: 'Japan',
      primaryCurrencyCode: 'JPY',
    ),
    CountryCurrencyProfile(
      countryCode: 'AU',
      countryName: 'Australia',
      primaryCurrencyCode: 'AUD',
    ),
    CountryCurrencyProfile(
      countryCode: 'CA',
      countryName: 'Canada',
      primaryCurrencyCode: 'CAD',
    ),
    CountryCurrencyProfile(
      countryCode: 'FR',
      countryName: 'France',
      primaryCurrencyCode: 'EUR',
    ),
    CountryCurrencyProfile(
      countryCode: 'IT',
      countryName: 'Italy',
      primaryCurrencyCode: 'EUR',
    ),
    CountryCurrencyProfile(
      countryCode: 'SG',
      countryName: 'Singapore',
      primaryCurrencyCode: 'SGD',
    ),
  ];

  static final Map<String, CountryCurrencyProfile> _countryByCode = {
    for (final country in supportedCountries) country.countryCode: country,
  };

  static final Map<String, String> _currencyLabels = {
    'INR': 'INR (₹)',
    'USD': 'USD (\$)',
    'GBP': 'GBP (£)',
    'AED': 'AED (د.إ)',
    'JPY': 'JPY (¥)',
    'AUD': 'AUD (\$)',
    'CAD': 'CAD (\$)',
    'EUR': 'EUR (€)',
    'SGD': 'SGD (\$)',
  };

  static String? primaryCurrencyForCountry(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) {
      return null;
    }
    final normalized = countryCode.trim().toUpperCase();
    return _countryByCode[normalized]?.primaryCurrencyCode;
  }

  static String countryNameFor(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) {
      return '';
    }
    final normalized = countryCode.trim().toUpperCase();
    return _countryByCode[normalized]?.countryName ?? '';
  }

  static String currencyLabel(String? currencyCode) {
    final normalized = (currencyCode ?? '').trim().toUpperCase();
    return _currencyLabels[normalized] ?? normalized;
  }

  static List<DropdownMenuItem<String>> countryDropdownItems() {
    return supportedCountries
        .map(
          (country) => DropdownMenuItem<String>(
            value: country.countryCode,
            child: Text('${country.countryName} (${country.countryCode})'),
          ),
        )
        .toList();
  }

  static List<DropdownMenuItem<String>> currencyDropdownItems() {
    return supportedCurrencies
        .map(
          (currencyCode) => DropdownMenuItem<String>(
            value: currencyCode,
            child: Text(currencyLabel(currencyCode)),
          ),
        )
        .toList();
  }

  static String taxSystemLabelForCountry(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) {
      return 'Standard Tax System';
    }
    final normalized = countryCode.trim().toUpperCase();
    switch (normalized) {
      case 'AU':
        return 'Australia — GST (10%)';
      case 'IN':
        return 'India — GST';
      case 'US':
        return 'United States — Sales Tax';
      case 'GB':
        return 'United Kingdom — VAT';
      case 'CA':
        return 'Canada — GST/HST';
      case 'AE':
        return 'United Arab Emirates — VAT (5%)';
      case 'JP':
        return 'Japan — Consumption Tax';
      case 'FR':
        return 'France — VAT';
      case 'IT':
        return 'Italy — VAT';
      case 'SG':
        return 'Singapore — GST (9%)';
      default:
        return 'Standard Tax System';
    }
  }

  static String postalCodeLabelForCountry(String? countryCode) {
    final normalized = (countryCode ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'US':
        return 'ZIP CODE *';
      case 'IN':
        return 'PIN CODE *';
      case 'AU':
      case 'GB':
        return 'POSTCODE *';
      default:
        return 'POSTAL CODE *';
    }
  }

  static String postalCodeHintForCountry(String? countryCode) {
    return 'Enter postal code';
  }

  static String? validatePostalCode(String? countryCode, String? postalCode) {
    if (postalCode == null || postalCode.trim().isEmpty) {
      final normalized = (countryCode ?? '').trim().toUpperCase();
      switch (normalized) {
        case 'US':
          return 'Enter a ZIP code.';
        case 'IN':
          return 'Enter a PIN code.';
        case 'AU':
        case 'GB':
          return 'Enter a postcode.';
        default:
          return 'Enter a postal code.';
      }
    }

    final trimmed = postalCode.trim();
    final normalized = (countryCode ?? '').trim().toUpperCase();

    switch (normalized) {
      case 'AU':
        if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
          return 'Enter a valid 4-digit Australian postcode (e.g. 2000).';
        }
        return null;

      case 'IN':
        if (!RegExp(r'^[1-9]\d{5}$').hasMatch(trimmed)) {
          return 'Enter a valid 6-digit Indian PIN code (e.g. 110001).';
        }
        return null;

      case 'US':
        if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(trimmed)) {
          return 'Enter a valid 5-digit US ZIP code (e.g. 90210).';
        }
        return null;

      case 'GB':
        if (!RegExp(
          r'^[A-Z]{1,2}[0-9][A-Z0-9]?\s?[0-9][A-Z]{2}$',
          caseSensitive: false,
        ).hasMatch(trimmed)) {
          return 'Enter a valid UK postcode (e.g. SW1A 1AA).';
        }
        return null;

      case 'CA':
        if (!RegExp(
          r'^[A-CEGHJ-NPR-TVXY][0-9][A-CEGHJ-NPR-TV-Z]\s?[0-9][A-CEGHJ-NPR-TV-Z][0-9]$',
          caseSensitive: false,
        ).hasMatch(trimmed)) {
          return 'Enter a valid Canadian postal code (e.g. K1A 0B1).';
        }
        return null;

      case 'JP':
        if (!RegExp(r'^\d{3}-?\d{4}$').hasMatch(trimmed)) {
          return 'Enter a valid 7-digit Japanese postal code (e.g. 100-0001).';
        }
        return null;

      case 'FR':
      case 'IT':
        if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) {
          return 'Enter a valid 5-digit postal code.';
        }
        return null;

      case 'SG':
        if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
          return 'Enter a valid 6-digit Singapore postal code (e.g. 238801).';
        }
        return null;

      case 'AE':
        // UAE does not use standard postal codes; accepts optional 00000 or up to 10 alphanumeric
        if (!RegExp(r'^[A-Za-z0-9\s-]{0,10}$').hasMatch(trimmed)) {
          return 'Enter a valid postal code or leave 00000.';
        }
        return null;

      default:
        if (trimmed.length < 2 || trimmed.length > 12) {
          return 'Enter a valid postal code.';
        }
        return null;
    }
  }

  static bool isValidPostalCode(String? countryCode, String? postalCode) {
    return validatePostalCode(countryCode, postalCode) == null;
  }
}
