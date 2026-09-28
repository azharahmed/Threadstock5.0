enum CustomerInputType {
  phone,
  email,
  name,
  empty,
}

class CustomerInputClassification {
  final CustomerInputType type;
  final String rawInput;
  final String? detectedPhone;
  final String? detectedEmail;
  final String? detectedName;
  final String? detectedIsd;
  final String normalizedE164;

  const CustomerInputClassification({
    required this.type,
    required this.rawInput,
    this.detectedPhone,
    this.detectedEmail,
    this.detectedName,
    this.detectedIsd,
    this.normalizedE164 = '',
  });

  @override
  String toString() {
    return 'CustomerInputClassification(type: $type, raw: "$rawInput", phone: $detectedPhone, email: $detectedEmail, name: $detectedName, isd: $detectedIsd, e164: $normalizedE164)';
  }
}

/// Intelligent classifier for customer search inputs and auto-fill mapping.
class CustomerInputClassifier {
  static const List<Map<String, String>> isdCodes = [
    {'code': 'IN', 'name': 'India', 'isd': '+91'},
    {'code': 'US', 'name': 'United States', 'isd': '+1'},
    {'code': 'GB', 'name': 'United Kingdom', 'isd': '+44'},
    {'code': 'AE', 'name': 'UAE', 'isd': '+971'},
    {'code': 'JP', 'name': 'Japan', 'isd': '+81'},
    {'code': 'AU', 'name': 'Australia', 'isd': '+61'},
    {'code': 'CA', 'name': 'Canada', 'isd': '+1'},
    {'code': 'FR', 'name': 'France', 'isd': '+33'},
    {'code': 'IT', 'name': 'Italy', 'isd': '+39'},
    {'code': 'SG', 'name': 'Singapore', 'isd': '+65'},
  ];

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _hasLettersRegExp = RegExp(r'[a-zA-Z]');

  /// Returns the default ISD dialing code for a country code (e.g. 'IN' -> '+91', 'AE' -> '+971').
  static String defaultIsdForCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) return '+91';
    final upper = countryCode.trim().toUpperCase();
    for (final item in isdCodes) {
      if (item['code'] == upper || item['name']?.toUpperCase() == upper) {
        return item['isd']!;
      }
    }
    if (upper == 'INDIA') return '+91';
    if (upper == 'UAE' || upper == 'UNITED ARAB EMIRATES') return '+971';
    if (upper == 'USA' || upper == 'UNITED STATES') return '+1';
    if (upper == 'UK' || upper == 'UNITED KINGDOM') return '+44';
    return '+91';
  }

  /// Extracts digits only from string.
  static String cleanDigits(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  /// Normalizes a phone number to E.164 format with leading '+'.
  static String normalizeToE164(String input, {String defaultIsd = '+91'}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // If starts with +, keep + and digits
    if (trimmed.startsWith('+')) {
      final digits = cleanDigits(trimmed);
      return digits.isEmpty ? '' : '+$digits';
    }

    final digits = cleanDigits(trimmed);
    if (digits.isEmpty) return '';

    final cleanIsd = defaultIsd.replaceAll(RegExp(r'[^\d]'), '');

    // Check if digits already begin with ISD code (e.g. 919986645729 or 971501234567)
    if (cleanIsd.isNotEmpty &&
        digits.startsWith(cleanIsd) &&
        digits.length > cleanIsd.length + 6) {
      return '+$digits';
    }

    return '+$cleanIsd$digits';
  }

  /// Classifies search input into Phone, Email, Name, or Empty.
  static CustomerInputClassification classify(
    String input, {
    String defaultIsd = '+91',
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return CustomerInputClassification(
        type: CustomerInputType.empty,
        rawInput: input,
      );
    }

    // 1. Check Email
    if (_emailRegExp.hasMatch(trimmed)) {
      return CustomerInputClassification(
        type: CustomerInputType.email,
        rawInput: input,
        detectedEmail: trimmed,
      );
    }

    final hasLetters = _hasLettersRegExp.hasMatch(trimmed);
    final digits = cleanDigits(trimmed);

    // 2. Check Phone
    // Treat as phone when primarily digits, spaces, +, -, (), and contains phone digits
    // or starts with '+'
    final isPhoneCharsOnly = RegExp(r'^[0-9+\s\-().]+$').hasMatch(trimmed);

    if (!hasLetters && (isPhoneCharsOnly || trimmed.startsWith('+'))) {
      if (digits.length >= 7 || trimmed.startsWith('+') || (digits.isNotEmpty && isPhoneCharsOnly)) {
        // Detect if explicit ISD prefix was typed (e.g. +91, +971, +1, etc.)
        String detectedIsd = defaultIsd;
        String localNumber = trimmed;

        if (trimmed.startsWith('+')) {
          // Sort ISD codes by length descending (+971 before +1, etc.)
          final sortedCodes = List<Map<String, String>>.from(isdCodes)
            ..sort((a, b) => b['isd']!.length.compareTo(a['isd']!.length));

          for (final c in sortedCodes) {
            final isd = c['isd']!;
            if (trimmed.startsWith(isd)) {
              detectedIsd = isd;
              final remainder = trimmed.substring(isd.length).trim();
              localNumber = remainder.replaceAll(RegExp(r'^[-\s]+'), '');
              break;
            }
          }
        } else {
          // If typed without '+', check if it starts with the numeric ISD code and is full international length
          final cleanIsd = defaultIsd.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanIsd.isNotEmpty &&
              digits.startsWith(cleanIsd) &&
              digits.length >= cleanIsd.length + 9) {
            detectedIsd = defaultIsd;
            localNumber = digits.substring(cleanIsd.length);
          }
        }

        final e164 = normalizeToE164(trimmed, defaultIsd: detectedIsd);

        return CustomerInputClassification(
          type: CustomerInputType.phone,
          rawInput: input,
          detectedPhone: localNumber.isNotEmpty ? localNumber : trimmed,
          detectedIsd: detectedIsd,
          normalizedE164: e164,
        );
      }
    }

    // 3. Name: Alphabetic or mixed name-like input
    if (hasLetters) {
      return CustomerInputClassification(
        type: CustomerInputType.name,
        rawInput: input,
        detectedName: trimmed,
      );
    }

    // Fallback if numbers < 7 digits without letters: treat as partial phone for searching
    if (digits.isNotEmpty) {
      return CustomerInputClassification(
        type: CustomerInputType.phone,
        rawInput: input,
        detectedPhone: trimmed,
        detectedIsd: defaultIsd,
        normalizedE164: normalizeToE164(trimmed, defaultIsd: defaultIsd),
      );
    }

    return CustomerInputClassification(
      type: CustomerInputType.name,
      rawInput: input,
      detectedName: trimmed,
    );
  }
}
