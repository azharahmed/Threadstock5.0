// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/business/current_business_service.dart';
import '../../../../core/reference/country_currency_reference.dart';
import '../../../inventory/data/brand_repository.dart';
import '../../../inventory/data/category_repository.dart';
import '../../../inventory/data/location_repository.dart';
import '../../../inventory/data/product_media_repository.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/data/supplier_repository.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../inventory/presentation/providers/brand_provider.dart';
import '../../data/onboarding_repository.dart';
import '../widgets/team_onboarding_view.dart';

enum LocationRange { one, twoToFive, sixToTwenty, twentyPlus }

enum CurrencySelectionMode { none, automatic, userSelected }

/// How the merchant chooses to start inventory during onboarding Step 4.
enum InventoryStartMethod { manual, fileImport, shopify }

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.initialStep,
    this.initialSelectedCountry,
    this.initialSelectedCurrency,
    this.repository,
    this.enforceStepPrerequisites = false,
    this.brandRepository,
    this.brandProvider,
    this.categoryRepository,
    this.mediaRepository,
    this.productRepository,
    this.supplierRepository,
    this.locationRepository,
  });

  final int? initialStep;
  final String? initialSelectedCountry;
  final String? initialSelectedCurrency;
  final OnboardingRepository? repository;
  final bool enforceStepPrerequisites;
  final BrandRepository? brandRepository;
  final BrandProvider? brandProvider;
  final CategoryRepository? categoryRepository;
  final ProductMediaRepository? mediaRepository;
  final ProductRepository? productRepository;
  final SupplierRepository? supplierRepository;
  final LocationRepository? locationRepository;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Current active step:
  // 0: Welcome (/onboarding/welcome)
  // 1: Business Profile (/onboarding/business) - STEP 1 OF 5
  // 2: Location Nodes (/onboarding/location) - STEP 2 OF 5
  // 3: Commerce Channels (/onboarding/commerce) - STEP 3 OF 5
  // 4: Inventory Ingestion (/onboarding/inventory) - STEP 4 OF 5
  // 5: Team Setup (/onboarding/team) - STEP 5 OF 5
  // 6: Ready / Complete (/onboarding/complete)
  late int _currentStep;
  late OnboardingRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? OnboardingRepository.instance;
    final progress = _repository.currentProgress;

    if (widget.initialStep == null) {
      _currentStep = progress.firstIncompleteStep;
    } else if (widget.enforceStepPrerequisites) {
      if (widget.initialStep! == 0) {
        _currentStep = 0;
      } else if (progress.isStepAccessible(widget.initialStep!)) {
        _currentStep = widget.initialStep!;
      } else {
        _currentStep = progress.firstIncompleteStep;
      }
    } else {
      _currentStep = widget.initialStep!;
    }

    // Hydrate fields from persisted progress if available
    if (progress.businessName != null && progress.businessName!.isNotEmpty) {
      _businessNameController.text = progress.businessName!;
    }
    _selectedIndustry = progress.businessType;
    _selectedCountryCode = _normalizeCountryCode(
      widget.initialSelectedCountry ?? progress.countryCode,
    );
    _selectedCurrencyCode = _normalizeCurrencyCode(
      widget.initialSelectedCurrency ?? progress.currencyCode,
    );
    if (progress.locationRange != null) {
      _selectedLocationRange = _parseLocationRange(progress.locationRange);
    }
    if (progress.configuredLocations.isNotEmpty &&
        _configuredLocations.isEmpty) {
      for (final loc in progress.configuredLocations) {
        _configuredLocations.add(
          loc.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        );
      }
    }
    if (progress.hasIncompatibleLocations(_selectedCountryCode)) {
      _locationReviewRequired = true;
      _locationReviewMessage =
          'Country changed. Please review your location details.';
    }
    if (progress.selectedSalesChannels.isNotEmpty &&
        _selectedSalesChannels.isEmpty) {
      _selectedSalesChannels.addAll(progress.selectedSalesChannels);
    }
    if (progress.paymentTerms != null) {
      _paymentTerms = progress.paymentTerms;
    }
    if (progress.inventoryStartMethod != null) {
      if (progress.inventoryStartMethod == 'manual') {
        _inventoryStartMethod = InventoryStartMethod.manual;
      } else if (progress.inventoryStartMethod == 'file_import') {
        _inventoryStartMethod = InventoryStartMethod.fileImport;
      } else if (progress.inventoryStartMethod == 'shopify') {
        _inventoryStartMethod = InventoryStartMethod.shopify;
      }
    }
    if (progress.savedTeamInvites.isNotEmpty && _savedTeamInvites.isEmpty) {
      for (final inv in progress.savedTeamInvites) {
        _savedTeamInvites.add(
          inv.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        );
      }
    }

    if (_selectedCountryCode != null && _selectedCurrencyCode == null) {
      _selectedCurrencyCode =
          CountryCurrencyReference.primaryCurrencyForCountry(
            _selectedCountryCode,
          );
      _currencySelectionMode = CurrencySelectionMode.automatic;
    }
    if (_selectedCountryCode != null &&
        _selectedCurrencyCode != null &&
        _currencySelectionMode == CurrencySelectionMode.none) {
      _currencySelectionMode = CurrencySelectionMode.userSelected;
    }
  }

  LocationRange? _parseLocationRange(String? label) {
    if (label == null) return null;
    final clean = label.replaceAll(' ', '');
    switch (clean) {
      case '1':
        return LocationRange.one;
      case '2-5':
        return LocationRange.twoToFive;
      case '6-20':
        return LocationRange.sixToTwenty;
      case '20+':
        return LocationRange.twentyPlus;
      default:
        return null;
    }
  }

  // Step 1: Business Profile controllers & state
  final TextEditingController _businessNameController = TextEditingController();
  String? _selectedIndustry;
  String? _selectedCountryCode;
  String? _selectedCurrencyCode;
  CurrencySelectionMode _currencySelectionMode = CurrencySelectionMode.none;
  String? _currencySuggestion;
  LocationRange? _selectedLocationRange;

  String? _businessNameError;
  String? _industryError;
  String? _countryError;
  String? _currencyError;
  String? _locationRangeError;
  bool _isSavingBusinessStep = false;
  String? _step1ErrorMessage;

  // Step 2: Location controllers & state
  final TextEditingController _locationNameController = TextEditingController();
  String? _selectedLocationType;
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  bool _useCorporateRules = false;

  String? _locationNameError;
  String? _locationTypeError;
  String? _streetError;
  String? _cityError;
  String? _postalError;
  bool _locationReviewRequired = false;
  String? _locationReviewMessage;

  // Multiple configured locations list
  final List<Map<String, String>> _configuredLocations = [];
  int? _editingLocationIndex;

  List<String> get _availableLocations {
    final list = <String>[];
    for (final loc in _configuredLocations) {
      final name = loc['name'];
      if (name != null &&
          name.trim().isNotEmpty &&
          !list.contains(name.trim())) {
        list.add(name.trim());
      }
    }
    return list;
  }

  String? _normalizeCountryCode(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    final value = rawValue.trim();
    if (value.length == 2) {
      return value.toUpperCase();
    }
    final match = RegExp(r'\(([A-Z]{2})\)$').firstMatch(value);
    if (match != null) {
      return match.group(1);
    }
    final country = CountryCurrencyReference.supportedCountries.firstWhere(
      (entry) => entry.countryName.toLowerCase() == value.toLowerCase(),
      orElse: () => const CountryCurrencyProfile(
        countryCode: '',
        countryName: '',
        primaryCurrencyCode: '',
      ),
    );
    return country.countryCode.isEmpty ? null : country.countryCode;
  }

  String? _normalizeCurrencyCode(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    final value = rawValue.trim();
    final normalized = value.toUpperCase();
    if (CountryCurrencyReference.supportedCurrencies.contains(normalized)) {
      return normalized;
    }
    final match = RegExp(r'([A-Z]{3})').firstMatch(value);
    return match?.group(1);
  }

  void _handleCountryChanged(String? countryCode) {
    final normalizedCountryCode = _normalizeCountryCode(countryCode);
    final defaultCurrency = CountryCurrencyReference.primaryCurrencyForCountry(
      normalizedCountryCode,
    );

    setState(() {
      _selectedCountryCode = normalizedCountryCode;
      _countryError = null;

      if (normalizedCountryCode == null) {
        _selectedCurrencyCode = null;
        _currencySelectionMode = CurrencySelectionMode.none;
        _currencySuggestion = null;
        return;
      }

      if (_selectedCurrencyCode == null) {
        _selectedCurrencyCode = defaultCurrency;
        _currencySelectionMode = CurrencySelectionMode.automatic;
        _currencySuggestion = null;
        return;
      }

      if (_currencySelectionMode == CurrencySelectionMode.automatic) {
        _selectedCurrencyCode = defaultCurrency;
        _currencySelectionMode = CurrencySelectionMode.automatic;
        _currencySuggestion = null;
        return;
      }

      if (defaultCurrency != null && _selectedCurrencyCode != defaultCurrency) {
        _currencySuggestion =
            'Suggested: ${CountryCurrencyReference.currencyLabel(defaultCurrency)} is the standard currency for ${CountryCurrencyReference.countryNameFor(normalizedCountryCode)}.';
      } else {
        _currencySuggestion = null;
      }
    });
  }

  void _handleCurrencyChanged(String? currencyCode) {
    final normalizedCurrencyCode = _normalizeCurrencyCode(currencyCode);

    setState(() {
      _selectedCurrencyCode = normalizedCurrencyCode;
      _currencySelectionMode = CurrencySelectionMode.userSelected;
      _currencySuggestion = null;
      _currencyError = null;
    });
  }

  bool _validateLocationStep() {
    final name = _locationNameController.text.trim();
    final type = _selectedLocationType?.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final postal = _postalController.text.trim();

    final postalValidation = CountryCurrencyReference.validatePostalCode(
      _selectedCountryCode,
      postal,
    );

    setState(() {
      _locationNameError = name.isEmpty ? 'Enter a location name.' : null;
      _locationTypeError = (type == null || type.isEmpty)
          ? 'Select a location type.'
          : null;
      _streetError = street.isEmpty ? 'Enter a street address.' : null;
      _cityError = city.isEmpty ? 'Enter a city.' : null;
      _postalError = postalValidation;
    });

    return name.isNotEmpty &&
        type != null &&
        type.isNotEmpty &&
        street.isNotEmpty &&
        city.isNotEmpty &&
        postalValidation == null;
  }

  void _addOrUpdateLocation() {
    if (!_validateLocationStep()) {
      return;
    }

    final name = _locationNameController.text.trim();
    final type = _selectedLocationType?.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final postal = _postalController.text.trim();

    final newLoc = {
      'name': name,
      'type': type ?? '',
      'street': street,
      'city': city,
      'postal': postal,
      'countryCode': _selectedCountryCode ?? '',
      'useCorporateRules': _useCorporateRules ? 'true' : 'false',
      'currencyCode': _useCorporateRules ? (_selectedCurrencyCode ?? '') : '',
      'taxSystem': _useCorporateRules
          ? CountryCurrencyReference.taxSystemLabelForCountry(
              _selectedCountryCode,
            )
          : '',
    };

    setState(() {
      if (_editingLocationIndex != null &&
          _editingLocationIndex! < _configuredLocations.length) {
        _configuredLocations[_editingLocationIndex!] = newLoc;
        _editingLocationIndex = null;
      } else {
        _configuredLocations.add(newLoc);
      }
      _locationNameController.clear();
      _streetController.clear();
      _cityController.clear();
      _postalController.clear();
      _selectedLocationType = null;
      _useCorporateRules = false;
      _locationNameError = null;
      _locationTypeError = null;
      _streetError = null;
      _cityError = null;
      _postalError = null;

      // Re-evaluate if any remaining locations require review
      bool hasInvalid = false;
      for (final loc in _configuredLocations) {
        if (!CountryCurrencyReference.isValidPostalCode(
          _selectedCountryCode,
          loc['postal'],
        )) {
          hasInvalid = true;
          break;
        }
      }
      if (!hasInvalid) {
        _locationReviewRequired = false;
        _locationReviewMessage = null;
      }
    });
  }

  void _editLocation(int index) {
    if (index >= 0 && index < _configuredLocations.length) {
      final loc = _configuredLocations[index];
      setState(() {
        _editingLocationIndex = index;
        _locationNameController.text = loc['name'] ?? '';
        _selectedLocationType = loc['type']?.trim().isNotEmpty == true
            ? loc['type']
            : null;
        _streetController.text = loc['street'] ?? '';
        _cityController.text = loc['city'] ?? '';
        _postalController.text = loc['postal'] ?? '';
        _useCorporateRules = loc['useCorporateRules'] == 'true';
        _locationNameError = null;
        _locationTypeError = null;
        _streetError = null;
        _cityError = null;
        _postalError = null;
      });
    }
  }

  void _removeLocation(int index) {
    setState(() {
      if (_editingLocationIndex == index) {
        _editingLocationIndex = null;
        _locationNameController.clear();
        _streetController.clear();
        _cityController.clear();
        _postalController.clear();
      } else if (_editingLocationIndex != null &&
          _editingLocationIndex! > index) {
        _editingLocationIndex = _editingLocationIndex! - 1;
      }
      _configuredLocations.removeAt(index);

      // Re-evaluate if any remaining locations require review
      bool hasInvalid = false;
      for (final loc in _configuredLocations) {
        if (!CountryCurrencyReference.isValidPostalCode(
          _selectedCountryCode,
          loc['postal'],
        )) {
          hasInvalid = true;
          break;
        }
      }
      if (!hasInvalid) {
        _locationReviewRequired = false;
        _locationReviewMessage = null;
      }
    });
  }

  Future<void> _saveAndContinueStep1() async {
    final hasActiveFormEntry =
        _locationNameController.text.trim().isNotEmpty ||
        _streetController.text.trim().isNotEmpty ||
        _cityController.text.trim().isNotEmpty ||
        _postalController.text.trim().isNotEmpty ||
        _selectedLocationType != null;

    if (_configuredLocations.isEmpty || hasActiveFormEntry) {
      if (!_validateLocationStep()) {
        return;
      }

      final loc = {
        'name': _locationNameController.text.trim(),
        'type': _selectedLocationType ?? '',
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'postal': _postalController.text.trim(),
        'countryCode': _selectedCountryCode ?? '',
        'useCorporateRules': _useCorporateRules ? 'true' : 'false',
        'currencyCode': _useCorporateRules ? (_selectedCurrencyCode ?? '') : '',
        'taxSystem': _useCorporateRules
            ? CountryCurrencyReference.taxSystemLabelForCountry(
                _selectedCountryCode,
              )
            : '',
      };

      if (_editingLocationIndex != null &&
          _editingLocationIndex! < _configuredLocations.length) {
        _configuredLocations[_editingLocationIndex!] = loc;
      } else {
        _configuredLocations.add(loc);
      }
      _editingLocationIndex = null;
    }

    // Validate that all configured locations match the current country
    for (int i = 0; i < _configuredLocations.length; i++) {
      final loc = _configuredLocations[i];
      final postal = loc['postal'] ?? '';
      final err = CountryCurrencyReference.validatePostalCode(
        _selectedCountryCode,
        postal,
      );
      if (err != null) {
        setState(() {
          _locationReviewRequired = true;
          _locationReviewMessage =
              'Location "${loc['name']}" has an invalid postal code for ${CountryCurrencyReference.countryNameFor(_selectedCountryCode)} ($postal). Please edit and update it.';
        });
        return;
      }
    }

    _locationReviewRequired = false;
    _locationReviewMessage = null;

    await _repository.markStepComplete(
      2,
      data: {'configuredLocations': _configuredLocations},
    );

    setState(() {
      _currentStep = 3;
    });
  }

  // Step 3: Commerce sales channels
  final Set<int> _selectedSalesChannels = {};
  String? _paymentTerms;
  String? _salesChannelsError;
  String? _paymentTermsError;

  String get _resolvedTaxSystemLabel {
    return CountryCurrencyReference.taxSystemLabelForCountry(
      _selectedCountryCode,
    );
  }

  bool _validateCommerceStep() {
    final hasSalesChannels = _selectedSalesChannels.isNotEmpty;
    final hasPaymentTerms =
        _paymentTerms != null && _paymentTerms!.trim().isNotEmpty;

    setState(() {
      _salesChannelsError = hasSalesChannels
          ? null
          : 'Select at least one sales channel.';
      _paymentTermsError = hasPaymentTerms
          ? null
          : 'Select your preferred payment terms.';
    });

    return hasSalesChannels && hasPaymentTerms;
  }

  // Step 4: Inventory ingestion option — null until the user explicitly chooses.
  InventoryStartMethod? _inventoryStartMethod;
  String? _inventorySelectionError;
  bool _isInitializingCatalog = false;

  bool _validateInventoryStep() {
    final hasSelection = _inventoryStartMethod != null;
    setState(() {
      _inventorySelectionError = hasSelection
          ? null
          : 'Select how you would like to start your inventory.';
    });
    return hasSelection;
  }

  Future<void> _handleInventoryContinue() async {
    if (_isInitializingCatalog) {
      return;
    }
    if (!_validateInventoryStep()) {
      return;
    }

    final method = _inventoryStartMethod!;
    if (method == InventoryStartMethod.shopify) {
      setState(() {
        _inventorySelectionError =
            'SHOPIFY INTEGRATION NOT IMPLEMENTED. Shopify connection requires OAuth/backend infrastructure. Please choose Create Manually or Upload CSV / Excel.';
      });
      return;
    }

    setState(() {
      _isInitializingCatalog = true;
      _inventorySelectionError = null;
    });

    try {
      if (!mounted) {
        return;
      }
      bool setupCompleted = false;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFFF7F3EC),
            body: InventoryPage(
              initialMode: method == InventoryStartMethod.manual
                  ? InventoryPageMode.createProduct
                  : InventoryPageMode.uploadFile,
              brandRepository: widget.brandRepository,
              brandProvider: widget.brandProvider,
              categoryRepository: widget.categoryRepository,
              mediaRepository: widget.mediaRepository,
              productRepository: widget.productRepository,
              supplierRepository: widget.supplierRepository,
              locationRepository: widget.locationRepository,
              onCatalogSetupCompleted: () async {
                if (setupCompleted) return;
                setupCompleted = true;
                if (method == InventoryStartMethod.manual) {
                  await _repository.markStepComplete(
                    4,
                    data: {
                      'inventoryStartMethod': 'manual',
                      'inventorySetupStatus': 'completed',
                    },
                  );
                  if (mounted) {
                    setState(() {
                      _currentStep = 5;
                    });
                  }
                }
              },
              onBackFromUpload: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      );

      if (setupCompleted) {
        if (!_repository.currentProgress.isInventoryCompleted) {
          await _repository.markStepComplete(
            4,
            data: {
              'inventoryStartMethod': method == InventoryStartMethod.manual
                  ? 'manual'
                  : 'file_import',
              'inventorySetupStatus': 'completed',
            },
          );
        }
        if (mounted && method == InventoryStartMethod.manual) {
          setState(() {
            _currentStep = 5;
          });
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Initialize Catalog Setup failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _inventorySelectionError =
            'Unable to open catalog setup. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializingCatalog = false);
      }
    }
  }

  Future<void> _continueFromInventoryStep() async {
    if (!_repository.currentProgress.isInventoryCompleted) {
      setState(() {
        _inventorySelectionError =
            'Please complete catalog setup (publish a product or import a file) before continuing to Team.';
      });
      return;
    }
    if (mounted) {
      setState(() {
        _currentStep = 5;
      });
    }
  }

  // Step 5: Team members (starts with 0 demo members)
  final List<Map<String, String>> _savedTeamInvites = [];

  static const List<String> _stepLabels = [
    'Business',
    'Location',
    'Commerce',
    'Inventory',
    'Team',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _locationNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step == 0) {
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    if (step >= 1 && step <= 6) {
      if (!_repository.currentProgress.isStepAccessible(step)) {
        // Locked step: do nothing, do not navigate
        return;
      }
      setState(() {
        _currentStep = step;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 6) {
      final next = _currentStep + 1;
      if (_repository.currentProgress.isStepAccessible(next)) {
        setState(() {
          _currentStep = next;
        });
      }
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateStep1Business() {
    final businessName = _businessNameController.text.trim();
    final businessTypeIsValid =
        _selectedIndustry != null && _selectedIndustry!.trim().isNotEmpty;
    final countryIsValid =
        _selectedCountryCode != null && _selectedCountryCode!.trim().isNotEmpty;
    final currencyIsValid =
        _selectedCurrencyCode != null &&
        _selectedCurrencyCode!.trim().isNotEmpty;
    final locationsIsValid = _selectedLocationRange != null;

    setState(() {
      _businessNameError = businessName.isEmpty
          ? 'Enter your legal business name.'
          : null;
      _industryError = businessTypeIsValid
          ? null
          : 'Select your business type.';
      _countryError = countryIsValid ? null : 'Select your country.';
      _currencyError = currencyIsValid ? null : 'Select your primary currency.';
      _locationRangeError = locationsIsValid
          ? null
          : 'Select the number of active locations.';
    });

    return businessName.isNotEmpty &&
        businessTypeIsValid &&
        countryIsValid &&
        currencyIsValid &&
        locationsIsValid;
  }

  Future<void> _continueFromBusinessStep() async {
    if (_isSavingBusinessStep) return;

    if (!_validateStep1Business()) {
      return;
    }

    setState(() {
      _isSavingBusinessStep = true;
      _step1ErrorMessage = null;
    });

    try {
      final priorCountry = _repository.currentProgress.countryCode;
      final priorCurrency = _repository.currentProgress.currencyCode;

      final dbLocationRange = _selectedLocationRange != null
          ? _locationRangeDbValue(_selectedLocationRange!)
          : '1';

      await _repository.markStepComplete(
        1,
        data: {
          'businessName': _businessNameController.text.trim(),
          'businessType': _selectedIndustry,
          'countryCode': _selectedCountryCode,
          'currencyCode': _selectedCurrencyCode,
          'locationRange': dbLocationRange,
        },
      );

      final countryChanged =
          priorCountry != null && priorCountry != _selectedCountryCode;
      final currencyChanged =
          priorCurrency != null && priorCurrency != _selectedCurrencyCode;

      if (countryChanged) {
        await _repository.invalidateFrom(2);
        _locationReviewRequired = true;
        _locationReviewMessage =
            'Country changed. Please review your location details.';
      } else if (currencyChanged) {
        await _repository.invalidateFrom(3);
      }

      if (!mounted) return;
      setState(() {
        _isSavingBusinessStep = false;
        _currentStep = 2;
      });
    } catch (e) {
      if (!mounted) return;

      final sb =
          CurrentBusinessService.instance.client ??
          (() {
            try {
              return Supabase.instance.client;
            } catch (_) {
              return null;
            }
          })();

      final authUserPresent = sb?.auth.currentUser != null;
      final currentBizPresent =
          CurrentBusinessService.instance.currentBusinessId != null;

      String errorCode = 'UNKNOWN';
      String errorMsg = e.toString();
      if (e is PostgrestException) {
        errorCode = e.code ?? 'POSTGREST_ERROR';
        errorMsg = e.message;
      } else if (e is AuthException) {
        errorCode = e.statusCode ?? 'AUTH_ERROR';
        errorMsg = e.message;
      }

      debugPrint(
        '==========================================================\n'
        '[Step1Business] Save failed:\n'
        '  operation: createOrUpdateBusiness (Step 1)\n'
        '  error_code: $errorCode\n'
        '  message: $errorMsg\n'
        '  auth user present: ${authUserPresent ? "YES" : "NO"}\n'
        '  current business present: ${currentBizPresent ? "YES" : "NO"}\n'
        '==========================================================',
      );

      String userFacingError =
          "We couldn't save your business setup.\nPlease try again.";

      if (errorMsg.contains('Anonymous Sign-Ins are disabled')) {
        userFacingError =
            'Anonymous Sign-Ins are disabled in your Supabase project. '
            'Please sign in with a registered account or check project authentication settings.';
      } else if (!authUserPresent) {
        userFacingError =
            "We couldn't establish an authenticated session.\n"
            "Please sign in to your account, then try again.";
      }

      setState(() {
        _isSavingBusinessStep = false;
        _step1ErrorMessage = userFacingError;
      });
    }
  }

  String _locationRangeDbValue(LocationRange range) {
    switch (range) {
      case LocationRange.one:
        return '1';
      case LocationRange.twoToFive:
        return '2-5';
      case LocationRange.sixToTwenty:
        return '6-20';
      case LocationRange.twentyPlus:
        return '20+';
    }
  }

  String _locationRangeLabel(LocationRange range) {
    switch (range) {
      case LocationRange.one:
        return '1';
      case LocationRange.twoToFive:
        return '2 - 5';
      case LocationRange.sixToTwenty:
        return '6 - 20';
      case LocationRange.twentyPlus:
        return '20+';
    }
  }

  Future<void> _finishOnboarding() async {
    await _repository.markStepComplete(6);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('Assets/OnBoardBG/BG.png', fit: BoxFit.cover),
          ),

          // Main Scaffold Layout
          SafeArea(
            child: Column(
              children: [
                // Top Header: ThreadStock logo only on the left, support link on the right
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 145,
                          maxWidth: 340,
                        ),
                        child: Image.asset(
                          'Assets/logo.png',
                          height: 145,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),

                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline_rounded,
                                size: 18,
                                color: Color(0xFF1E1C1A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ThreadStock Support',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Content Area (Expands to fill available space)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (currentChild, previousChildren) {
                          return currentChild ?? const SizedBox.shrink();
                        },
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                ),

                // Bottom Steps Navigation Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 12),
                  child: _buildBottomStepBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Active view router
  Widget _buildCurrentView() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Welcome();
      case 1:
        return _buildStep1Business();
      case 2:
        return _buildStep2Location();
      case 3:
        return _buildStep3Commerce();
      case 4:
        return _buildStep4Inventory();
      case 5:
        return _buildStep5Team();
      case 6:
      default:
        return _buildStep6Ready();
    }
  }

  // ==========================================
  // STEP 0: WELCOME / BUSINESS (Exact matching design)
  // ==========================================
  Widget _buildStep0Welcome() {
    return Column(
      key: const ValueKey('step_0_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pill: ThreadStock OS V2.0
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECE1).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6C5B0), width: 1.0),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bubble_chart_outlined,
                size: 14,
                color: Color(0xFFB58B55),
              ),
              SizedBox(width: 6),
              Text(
                'THREADSTOCK OS V2.0',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Color(0xFFB58B55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Welcome to ThreadStock (Main editorial serif — Cormorant Garamond)
        Text(
          'Welcome to ThreadStock',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 60,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF161412),
            letterSpacing: -0.5,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),

        // AI Inventory & Commerce OS for Fashion (Gold subtitle — Inter SemiBold)
        Text(
          'AI Inventory & Commerce OS for Fashion',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFBA8A55),
          ),
        ),
        const SizedBox(height: 18),

        // Subtext description (UI / body sans-serif — Inter)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Set up your workspace parameters in a few steps. ThreadStock coordinates your point of sale, supplier logs, multibranch transfers, and design attributes seamlessly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              height: 1.6,
              color: const Color(0xFF5E574E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons Row: [Set Up My Business] [Explore Demo Workspace]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Black Primary Button: Set Up My Business
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Set Up My Business',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Outlined Secondary Button: Continue Setup
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _finishOnboarding,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF7F2).withOpacity(0.55),
                  foregroundColor: const Color(0xFF1E1C1A),
                  side: const BorderSide(color: Color(0xFFD8CDBC), width: 1.2),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue Setup',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 1: BUSINESS PROFILE (Canonical Step 1 of 5)
  // ==========================================
  Widget _buildStep1Business() {
    return ConstrainedBox(
      key: const ValueKey('step_1_business'),
      constraints: const BoxConstraints(maxWidth: 540),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 34),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STEP 1 OF 5 — PROFILE',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: const Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your business',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),

            // Field 1: Legal Business Name
            _buildFormField(
              label: 'LEGAL BUSINESS NAME *',
              child: TextFormField(
                controller: _businessNameController,
                onChanged: (_) {
                  if (_businessNameError != null) {
                    setState(() {
                      _businessNameError = null;
                    });
                  }
                },
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E1C1A),
                ),
                decoration: _inputDecoration(
                  hint: 'ThreadStock',
                  errorText: _businessNameError,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 2: Industry / Business Type
            _buildFormField(
              label: 'INDUSTRY / BUSINESS TYPE *',
              child: DropdownButtonFormField<String>(
                value: _selectedIndustry,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF7A7268),
                  size: 20,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                hint: Text(
                  'Select business type',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9E9589).withOpacity(0.5),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                decoration: _inputDecoration(
                  hint: 'Select business type',
                  errorText: _industryError,
                ).copyWith(prefixIcon: null),
                items: const [
                  DropdownMenuItem(
                    value: 'Boutique & Designer Wear',
                    child: Text('Boutique & Designer Wear'),
                  ),
                  DropdownMenuItem(
                    value: 'Couture & Bespoke Studio',
                    child: Text('Couture & Bespoke Studio'),
                  ),
                  DropdownMenuItem(
                    value: 'Luxury Ready-to-Wear',
                    child: Text('Luxury Ready-to-Wear'),
                  ),
                  DropdownMenuItem(
                    value: 'Footwear & Leather Goods',
                    child: Text('Footwear & Leather Goods'),
                  ),
                  DropdownMenuItem(
                    value: 'Jewelry & High Accessories',
                    child: Text('Jewelry & High Accessories'),
                  ),
                  DropdownMenuItem(
                    value: 'Multi-brand Fashion / Department',
                    child: Text('Multi-brand Fashion / Department'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedIndustry = val;
                    _industryError = null;
                  });
                },
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 3 & 4: Country & Primary Currency
            Row(
              children: [
                // COUNTRY
                Expanded(
                  child: _buildFormField(
                    label: 'COUNTRY *',
                    errorText: _countryError,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF7A7268),
                        size: 20,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      hint: Text(
                        'Select country',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9E9589).withOpacity(0.5),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      decoration: _inputDecoration(
                        hint: 'Select country',
                        errorText: _countryError,
                      ),
                      items: CountryCurrencyReference.countryDropdownItems(),
                      onChanged: _handleCountryChanged,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // PRIMARY CURRENCY
                Expanded(
                  child: _buildFormField(
                    label: 'PRIMARY CURRENCY *',
                    errorText: _currencyError,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrencyCode,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF7A7268),
                        size: 20,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      hint: Text(
                        'Select currency',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9E9589).withOpacity(0.5),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      decoration: _inputDecoration(
                        hint: 'Select currency',
                        errorText: _currencyError,
                      ),
                      items: CountryCurrencyReference.currencyDropdownItems(),
                      onChanged: _handleCurrencyChanged,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_currencySuggestion != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2EA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4D7C3), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _currencySuggestion!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5E574E),
                        ),
                      ),
                    ),
                    if (_selectedCountryCode != null)
                      TextButton(
                        onPressed: () {
                          final defaultCurrency =
                              CountryCurrencyReference.primaryCurrencyForCountry(
                                _selectedCountryCode,
                              );
                          setState(() {
                            _selectedCurrencyCode = defaultCurrency;
                            _currencySelectionMode =
                                CurrencySelectionMode.automatic;
                            _currencySuggestion = null;
                            _currencyError = null;
                          });
                        },
                        child: Text(
                          'Use ${CountryCurrencyReference.currencyLabel(CountryCurrencyReference.primaryCurrencyForCountry(_selectedCountryCode))}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Field 5: Number of active operational locations
            _buildFormField(
              label: 'NUMBER OF ACTIVE OPERATIONAL LOCATIONS *',
              errorText: _locationRangeError,
              child: Row(
                children: [
                  for (final range in [
                    LocationRange.one,
                    LocationRange.twoToFive,
                    LocationRange.sixToTwenty,
                    LocationRange.twentyPlus,
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: range != LocationRange.twentyPlus ? 8 : 0,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLocationRange = range;
                              _locationRangeError = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 44,
                            decoration: BoxDecoration(
                              color: _selectedLocationRange == range
                                  ? const Color(0xFFFBF7EE)
                                  : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedLocationRange == range
                                    ? const Color(0xFFBA8A55)
                                    : const Color(0xFFDCCFBE),
                                width: _selectedLocationRange == range
                                    ? 1.5
                                    : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _locationRangeLabel(range),
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: _selectedLocationRange == range
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _selectedLocationRange == range
                                    ? const Color(0xFF1E1C1A)
                                    : const Color(0xFF5E574E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            if (_step1ErrorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFA39E)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFCF1322),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _step1ErrorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCF1322),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Continue to Locations Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSavingBusinessStep
                    ? null
                    : _continueFromBusinessStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF1E1C1A,
                  ).withOpacity(0.6),
                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSavingBusinessStep
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Saving Business...',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Continue to Locations',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: LOCATION (Nodes)
  // ==========================================
  Widget _buildStep2Location() {
    return ConstrainedBox(
      key: const ValueKey('step_2_location'),
      constraints: const BoxConstraints(maxWidth: 1040),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Form Card
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 2 OF 5 — NODES',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: const Color(0xFFBA8A55),
                        ),
                      ),
                      if (_selectedCountryCode != null &&
                          _selectedCountryCode!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE3D5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.public_rounded,
                                size: 13,
                                color: Color(0xFF6B6358),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${CountryCurrencyReference.countryNameFor(_selectedCountryCode)} (${_selectedCountryCode!})',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3B362F),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _editingLocationIndex != null
                        ? 'Edit location'
                        : (_configuredLocations.isEmpty
                              ? 'Create your first location'
                              : 'Add another location'),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF161412),
                    ),
                  ),
                  if (_locationReviewRequired) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFC2410C),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationReviewMessage ??
                                  'Country changed. Please review your location details.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9A3412),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Configured Locations Chips (if any)
                  if (_configuredLocations.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONFIGURED LOCATIONS (${_configuredLocations.length})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF7A7268),
                          ),
                        ),
                        if (_editingLocationIndex != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _editingLocationIndex = null;
                                _locationNameController.clear();
                                _streetController.clear();
                                _cityController.clear();
                                _postalController.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Cancel Edit',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9E3A3A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_configuredLocations.length, (
                        idx,
                      ) {
                        final loc = _configuredLocations[idx];
                        final isEditing = _editingLocationIndex == idx;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isEditing
                                ? const Color(0xFFF9F1E5)
                                : const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isEditing
                                  ? const Color(0xFFBA8A55)
                                  : const Color(0xFFE5DACD),
                              width: isEditing ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                loc['type'] == 'Warehouse'
                                    ? Icons.warehouse_outlined
                                    : Icons.storefront_outlined,
                                size: 15,
                                color: const Color(0xFFBA8A55),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  loc['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE3D5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  loc['type'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B6358),
                                  ),
                                ),
                              ),
                              if (!CountryCurrencyReference.isValidPostalCode(
                                _selectedCountryCode,
                                loc['postal'],
                              )) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Needs review',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _editLocation(idx),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: Color(0xFF7A7268),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _removeLocation(idx),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: Color(0xFF9E3A3A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE5DACD), height: 1),
                    const SizedBox(height: 18),
                  ],

                  // Location Name & Type
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildFormField(
                          label: 'LOCATION NAME *',
                          errorText: _locationNameError,
                          child: TextField(
                            controller: _locationNameController,
                            onChanged: (_) =>
                                setState(() => _locationNameError = null),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Enter location name',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _buildFormField(
                          label: 'TYPE *',
                          errorText: _locationTypeError,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _inputContainerBox(),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLocationType,
                                hint: Text(
                                  'Select location type',
                                  style: GoogleFonts.inter(
                                    color: const Color(
                                      0xFF9E9589,
                                    ).withOpacity(0.5),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                ),
                                items:
                                    [
                                      'Flagship Store',
                                      'Retail Store',
                                      'Warehouse',
                                      'Stockroom',
                                      'Showroom',
                                      'Office',
                                      'Other',
                                    ].map((value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedLocationType = val;
                                    _locationTypeError = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Street Address
                  _buildFormField(
                    label: 'STREET ADDRESS *',
                    errorText: _streetError,
                    child: TextField(
                      controller: _streetController,
                      onChanged: (_) => setState(() => _streetError = null),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Enter street address',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // City & Postal Code
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildFormField(
                          label: 'CITY *',
                          errorText: _cityError,
                          child: TextField(
                            controller: _cityController,
                            onChanged: (_) => setState(() => _cityError = null),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: _inputDecoration(hint: 'Enter city'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _buildFormField(
                          label:
                              CountryCurrencyReference.postalCodeLabelForCountry(
                                _selectedCountryCode,
                              ),
                          errorText: _postalError,
                          child: TextField(
                            controller: _postalController,
                            onChanged: (_) =>
                                setState(() => _postalError = null),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: _inputDecoration(
                              hint:
                                  CountryCurrencyReference.postalCodeHintForCountry(
                                    _selectedCountryCode,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Checkbox: Use main corporate currency
                  InkWell(
                    onTap: () => setState(
                      () => _useCorporateRules = !_useCorporateRules,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _useCorporateRules
                                ? const Color(0xFFBA8A55)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFBA8A55),
                              width: 1.5,
                            ),
                          ),
                          child: _useCorporateRules
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use main corporate currency and tax rules for this node',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3B362F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Inherits ${_selectedCurrencyCode ?? 'AUD'} currency and $_resolvedTaxSystemLabel from ${CountryCurrencyReference.countryNameFor(_selectedCountryCode)} business profile.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7268),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bottom Action Row
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: _addOrUpdateLocation,
                        icon: Icon(
                          _editingLocationIndex != null
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 18,
                          color: const Color(0xFFBA8A55),
                        ),
                        label: Text(
                          _editingLocationIndex != null
                              ? 'Update location'
                              : 'Add another location',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _saveAndContinueStep1,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Save & Continue',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1C1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Right Info Card: UNDERSTANDING LOCATIONS
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'UNDERSTANDING LOCATIONS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ThreadStock uses locations to represent the places where your inventory is stored, sold, or moved. You can add stores, warehouses, showrooms, or other operational locations as your business grows.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.5,
                      color: const Color(0xFF5E574E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE5DACD), height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'GOOD TO KNOW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _BulletItem(
                    text: 'You can add more locations anytime.',
                  ),
                  const SizedBox(height: 11),
                  const _BulletItem(
                    text:
                        'Each location can have its own inventory and stock levels.',
                  ),
                  const SizedBox(height: 11),
                  const _BulletItem(
                    text: 'Products can be transferred between locations.',
                  ),
                  const SizedBox(height: 11),
                  const _BulletItem(
                    text:
                        'Currency and tax settings can be inherited from your main business settings.',
                  ),
                  const SizedBox(height: 11),
                  const _BulletItem(
                    text:
                        'You can control which team members have access to each location.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F3EA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5DACD)),
                    ),
                    child: Text(
                      'This will work for small shops, multi-store brands, warehouses, and larger businesses without assuming a specific setup.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.45,
                        color: const Color(0xFF6B6358),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: COMMERCE (Channel Architecture)
  // ==========================================
  Widget _buildStep3Commerce() {
    return ConstrainedBox(
      key: const ValueKey('step_3_commerce'),
      constraints: const BoxConstraints(maxWidth: 760),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 3 OF 5 — CHANNEL ARCHITECTURE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: const Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure how you sell',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SELECT YOUR SALES CHANNELS',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: const Color(0xFF5E574E),
              ),
            ),
            const SizedBox(height: 14),

            // 2x2 Grid of Channels
            Row(
              children: [
                Expanded(
                  child: _buildChannelOption(
                    index: 0,
                    title: 'In-Store Retail & Showrooms',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildChannelOption(
                    index: 1,
                    title: 'Wholesale & Brand Orders',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildChannelOption(
                    index: 2,
                    title: 'Online Store (Shopify/Custom)',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildChannelOption(
                    index: 3,
                    title: 'Social Commerce (Instagram)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sales channel validation message
            if (_salesChannelsError != null) ...[
              Text(
                _salesChannelsError!,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB42318),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Payment Terms & Tax System
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'PREFERRED PAYMENT TERMS',
                    errorText: _paymentTermsError,
                    child: DropdownButtonFormField<String>(
                      value: _paymentTerms,
                      isExpanded: true,
                      hint: Text(
                        'Select payment terms',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9E9589).withOpacity(0.5),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Select payment terms',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Immediate / Paid (Standard Retail)',
                          child: Text('Immediate / Paid (Standard Retail)'),
                        ),
                        DropdownMenuItem(
                          value: 'Net 30 (Wholesale)',
                          child: Text('Net 30 (Wholesale)'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _paymentTerms = val;
                          _paymentTermsError = null;
                        });
                      },
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: 'TAX INTELLIGENCE',
                    child: TextFormField(
                      readOnly: true,
                      initialValue: _resolvedTaxSystemLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: _inputDecoration(
                        hint: _resolvedTaxSystemLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ThreadStock keeps applicable tax rules updated using authoritative tax sources and product classifications.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E574E),
              ),
            ),
            const SizedBox(height: 28),

            // Action Row
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_validateCommerceStep()) {
                      await _repository.markStepComplete(
                        3,
                        data: {
                          'selectedSalesChannels': _selectedSalesChannels,
                          'paymentTerms': _paymentTerms,
                        },
                      );
                      setState(() {
                        _currentStep = 4;
                      });
                    }
                  },
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    'Continue to Inventory',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1C1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption({required int index, required String title}) {
    final isSelected = _selectedSalesChannels.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSalesChannels.remove(index);
          } else {
            _selectedSalesChannels.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBA8A55)
                : const Color(0xFFE2D6C6),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFBA8A55)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBA8A55)
                      : const Color(0xFFBA8A55),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF24201C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 4: INVENTORY INGESTION
  // ==========================================
  Widget _buildStep4Inventory() {
    return ConstrainedBox(
      key: const ValueKey('step_4_inventory'),
      constraints: const BoxConstraints(maxWidth: 880),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 4 OF 5 — INVENTORY INGESTION',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: const Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to start?',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 28),

            if (_inventorySelectionError != null) ...[
              Text(
                _inventorySelectionError!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB42318),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3 Option Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildIngestionCard(
                    method: InventoryStartMethod.manual,
                    icon: Icons.article_outlined,
                    title: 'Create Manually',
                    desc:
                        'Perfect if you want to input products one by one, customize attributes, or setting up a bespoke lineup.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIngestionCard(
                    method: InventoryStartMethod.fileImport,
                    icon: Icons.cloud_upload_outlined,
                    title: 'Upload CSV / Excel',
                    desc:
                        'Import inventory logs from existing templates or wholesale sheets. ThreadStock handles size-matrix mapping.',
                    badge: 'MOST POPULAR',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIngestionCard(
                    method: InventoryStartMethod.shopify,
                    icon: Icons.share_outlined,
                    title: 'Connect Shopify',
                    desc:
                        'Import directly from your existing Shopify, Wix, or custom commerce catalog instantly with safe sync.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ThreadStock AI Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F3EA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8DCCF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'ThreadStock AI: ',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                          TextSpan(
                            text:
                                'During manual or CSV uploads, ThreadStock AI suggests mappings for SKU, barcode, color, size, fabric, category, cost, retail price, and quantity. You review and confirm before import — uncertain values are never invented.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF5A534A),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      style: GoogleFonts.inter(fontSize: 13, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 14,
              children: [
                OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E1C1A),
                    side: const BorderSide(
                      color: Color(0xFFD5C7B5),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    'Previous Step',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          (_inventoryStartMethod != null &&
                              !_isInitializingCatalog)
                          ? _handleInventoryContinue
                          : null,
                      iconAlignment: IconAlignment.end,
                      icon: _isInitializingCatalog
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        _isInitializingCatalog
                            ? 'Opening…'
                            : 'Initialize Catalog Setup',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF382F26),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE8E1D7),
                        disabledForegroundColor: const Color(0xFFA3998E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          _repository.currentProgress.isInventoryCompleted
                          ? _continueFromInventoryStep
                          : null,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        'Continue to Team',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1C1A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE8E1D7),
                        disabledForegroundColor: const Color(0xFFA3998E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngestionCard({
    required InventoryStartMethod method,
    required IconData icon,
    required String title,
    required String desc,
    String? badge,
  }) {
    final isSelected = _inventoryStartMethod == method;
    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: InkWell(
        onTap: () => setState(() {
          _inventoryStartMethod = method;
          _inventorySelectionError = null;
        }),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFBA8A55)
                  : const Color(0xFFE5DACD),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFBA8A55).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EFE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFFBA8A55), size: 22),
                  ),
                  if (badge != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA8A55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF6B6358),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 5: TEAM (Invite Team)
  // ==========================================
  Widget _buildStep5Team() {
    return TeamOnboardingView(
      key: const ValueKey('step_5_team'),
      businessName: _businessNameController.text.trim().isNotEmpty
          ? _businessNameController.text.trim()
          : null,
      coreNode: _configuredLocations.isNotEmpty
          ? _configuredLocations.first['name']
          : (_locationNameController.text.trim().isNotEmpty
                ? _locationNameController.text.trim()
                : null),
      currency: _selectedCurrencyCode != null
          ? CountryCurrencyReference.currencyLabel(_selectedCurrencyCode!)
          : null,
      taxMatrix: _resolvedTaxSystemLabel,
      availableLocations: _availableLocations,
      onBack: _previousStep,
      onSkip: () async {
        await _repository.markStepComplete(5);
        if (mounted) {
          setState(() {
            _currentStep = 6;
          });
        }
      },
      onContinue: (members) async {
        _savedTeamInvites.clear();
        for (final m in members) {
          final email = m.emailController.text.trim();
          if (email.isNotEmpty) {
            _savedTeamInvites.add({
              'email': email,
              'role': m.role ?? 'Store Associate',
              'location':
                  m.location ??
                  (_availableLocations.length == 1
                      ? _availableLocations.first
                      : 'All Locations'),
            });
          }
        }
        await _repository.markStepComplete(
          5,
          data: {'savedTeamInvites': _savedTeamInvites},
        );
        if (mounted) {
          setState(() {
            _currentStep = 6;
          });
        }
      },
      onOpenDashboard: _finishOnboarding,
    );
  }

  // ==========================================
  // STEP 6: WORKSPACE READY (Summary)
  // ==========================================
  Widget _buildStep6Ready() {
    return ConstrainedBox(
      key: const ValueKey('step_6_ready'),
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        padding: const EdgeInsets.all(44),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            // Pill: YOU'RE READY
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F1E5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCCFBD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'YOU\'RE READY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: const Color(0xFFBA8A55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title: Your workspace is ready (Editorial Serif: Cormorant Garamond)
            Text(
              'Your workspace is ready',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here is a summary of your setup.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B6358),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),

            // Checklist Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5DACD)),
              ),
              child: Column(
                children: [
                  _buildSummaryItem(
                    category: 'Business',
                    value: _businessNameController.text.trim().isNotEmpty
                        ? _businessNameController.text.trim()
                        : 'Not provided yet',
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    category: 'Location',
                    value: _configuredLocations.isEmpty
                        ? (_locationNameController.text.trim().isNotEmpty
                              ? _locationNameController.text.trim()
                              : 'Not configured yet')
                        : (_configuredLocations.length == 1
                              ? _configuredLocations.first['name']!
                              : '${_configuredLocations.first['name']} (+${_configuredLocations.length - 1} more)'),
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    category: 'Commerce',
                    value: 'In-store sales',
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    category: 'Inventory',
                    value: 'Starting with import',
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    category: 'Team',
                    value: _savedTeamInvites.isEmpty
                        ? 'Solo setup (no team invited)'
                        : '${_savedTeamInvites.length} ${_savedTeamInvites.length == 1 ? 'member' : 'members'} invited',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Open ThreadStock Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _finishOnboarding,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  'Open ThreadStock',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Review Setup link
            TextButton(
              onPressed: () => _goToStep(0),
              child: Text(
                'Review Setup',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5E574E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String category, required String value}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF275E43),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Text(
          category,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1C1A),
          ),
        ),
        Text(
          ' — ',
          style: GoogleFonts.inter(
            color: const Color(0xFF8A8275),
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4A443C),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM STEP BAR (Linked with lines & badges - no background box)
  // ==========================================
  Widget _buildBottomStepBar() {
    final progress = _repository.currentProgress;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_stepLabels.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Divider line between steps
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 26,
            height: 1.0,
            color: const Color(0xFFD6CABD),
          );
        }

        final stepIdx = index ~/ 2;
        final stepNumber = stepIdx + 1;
        final isActive = _currentStep > 0 && _currentStep == stepNumber;
        final isCompleted = progress.isStepCompleted(stepNumber);
        final isLocked = !progress.isStepAccessible(stepNumber);

        return _buildStepBadge(
          stepNumber: stepNumber,
          label: _stepLabels[stepIdx],
          isActive: isActive,
          isCompleted: isCompleted,
          isLocked: isLocked,
          onTap: isLocked ? null : () => _goToStep(stepNumber),
        );
      }),
    );
  }

  Widget _buildStepBadge({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required bool isLocked,
    required VoidCallback? onTap,
  }) {
    // Circle background and border
    Color circleBg = Colors.transparent;
    Color borderColor = isLocked
        ? const Color(0xFFE5DACD)
        : const Color(0xFFD6CABD);
    Widget circleContent;

    if (isActive) {
      // Active step: Camel/Gold filled circle with white number
      circleBg = const Color(0xFFBA8A55);
      borderColor = const Color(0xFFBA8A55);
      circleContent = Text(
        '$stepNumber',
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    } else if (isCompleted && !isLocked) {
      // Completed step: Emerald Green circle with checkmark
      circleBg = const Color(0xFF275E43);
      borderColor = const Color(0xFF275E43);
      circleContent = const Icon(
        Icons.check_rounded,
        size: 12,
        color: Colors.white,
      );
    } else {
      // Locked or upcoming step: subtle circle with step number
      circleContent = Text(
        '$stepNumber',
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isLocked ? const Color(0xFFA59B8E) : const Color(0xFF6E665C),
        ),
      );
    }

    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: isLocked ? Colors.transparent : null,
        splashColor: isLocked ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Center(child: circleContent),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF1E1C1A)
                          : (isCompleted
                                ? const Color(0xFF2E2A25)
                                : (isLocked
                                      ? const Color(0xFFA59B8E)
                                      : const Color(0xFF6E665C))),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Common Card Box Decoration
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFAF7F2).withOpacity(0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE8DFD3), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A231A).withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Common Input Decorator
  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9E9589).withOpacity(0.5),
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
      errorText: errorText,
      errorStyle: GoogleFonts.inter(
        color: const Color(0xFFB42318),
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCCFBE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA8A55), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    );
  }

  BoxDecoration _inputContainerBox() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDCCFBE)),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: const Color(0xFF5E574E),
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (errorText != null && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB42318),
            ),
          ),
        ],
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFBA8A55),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFF5E574E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
