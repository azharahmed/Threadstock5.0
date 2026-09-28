// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../../../core/business/current_business_service.dart';
import '../../../../core/config/app_preferences_service.dart';
import '../../../../core/navigation/navigation_guard.dart';
import '../../../../core/reference/country_currency_reference.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../app/router/app_router.dart';
import '../../../inventory/data/brand_repository.dart';
import '../../../inventory/data/category_repository.dart';
import '../../../inventory/data/location_repository.dart';
import '../../../inventory/domain/models/stock_location.dart';
import '../../../inventory/data/product_media_repository.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/data/supplier_repository.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../inventory/presentation/providers/brand_provider.dart';
import '../../data/onboarding_repository.dart';
import '../../domain/models/onboarding_progress.dart';
import '../widgets/google_location_map_view.dart';
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
  bool _isCheckingCompletion = false;
  bool _redirectScheduled = false;

  void _redirectToOverview({required String source}) {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    if (!mounted) return;
    NavigationGuard.safePushReplacementNamed(
      context,
      AppRoutes.overview,
      source: source,
    );
  }

  void _hydrateFields(OnboardingProgress progress) {
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

  Future<void> _verifyServerOnboardingStatus() async {
    final sb = CurrentBusinessService.instance.client ??
        (() {
          try {
            return Supabase.instance.client;
          } catch (_) {
            return null;
          }
        })();

    if (sb == null || sb.auth.currentUser == null) {
      return;
    }

    try {
      final bizId = await CurrentBusinessService.instance.resolveCurrentBusinessId();
      if (bizId != null && bizId.isNotEmpty) {
        final progress = await _repository.loadProgressForBusiness(bizId);
        if (progress.isOnboardingCompleted) {
          _redirectToOverview(
            source: 'OnboardingPage._verifyServerOnboardingStatus.completed',
          );
          return;
        }

        // Existing products guard: if products already exist, complete onboarding and route to Dashboard
        try {
          final products = await sb
              .from('products')
              .select('id')
              .eq('business_id', bizId)
              .limit(1);
          if ((products as List).isNotEmpty) {
            await _repository.markStepComplete(6);
            _redirectToOverview(
              source: 'OnboardingPage._verifyServerOnboardingStatus.hasProducts',
            );
            return;
          }
        } catch (e) {
          debugPrint('[OnboardingPage] Notice checking existing products: $e');
        }

        if (mounted) {
          setState(() {
            _isCheckingCompletion = false;
            _hydrateFields(progress);
            if (widget.initialStep == null ||
                (widget.enforceStepPrerequisites &&
                    !progress.isStepAccessible(widget.initialStep!))) {
              _currentStep = (progress.firstIncompleteStep - 1).clamp(0, 6);
            }
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[OnboardingPage] Error checking server onboarding status: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingCompletion = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    CurrentBusinessService.instance.addListener(_onCurrentBusinessChanged);
    _repository = widget.repository ?? OnboardingRepository.instance;
    final progress = _repository.currentProgress;

    // Completed onboarding guard: never reopen onboarding for a completed business
    if (progress.isOnboardingCompleted) {
      _currentStep = 6;
      _isCheckingCompletion = true;
      _redirectToOverview(
        source: 'OnboardingPage.initState.alreadyComplete',
      );
      return;
    }

    if (widget.initialStep == null) {
      _currentStep = (progress.firstIncompleteStep - 1).clamp(0, 6);
    } else if (widget.enforceStepPrerequisites) {
      if (widget.initialStep! == 0) {
        _currentStep = 0;
      } else if (progress.isStepAccessible(widget.initialStep!)) {
        _currentStep = widget.initialStep!;
      } else {
        _currentStep = (progress.firstIncompleteStep - 1).clamp(0, 6);
      }
    } else {
      _currentStep = widget.initialStep!;
    }

    _hydrateFields(progress);

    final sb = CurrentBusinessService.instance.client ??
        (() {
          try {
            return Supabase.instance.client;
          } catch (_) {
            return null;
          }
        })();

    if (sb != null && sb.auth.currentUser != null) {
      _isCheckingCompletion = true;
      _verifyServerOnboardingStatus();
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

  /// Authoritative current business / workspace display name across all onboarding pages.
  /// Before Business is saved: Setting up: Your Workspace
  /// After saving Business successfully: Setting up: [Business Name]
  String get _currentBusinessDisplayName {
    final progress = _repository.currentProgress;
    final activeBizName = CurrentBusinessService.instance.currentBusiness?.legalName;
    if (activeBizName != null && activeBizName.trim().isNotEmpty) {
      return activeBizName.trim();
    }
    final progressName = progress.businessName;
    if (progressName != null && progressName.trim().isNotEmpty) {
      return progressName.trim();
    }
    return 'Your Workspace';
  }

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
  bool _isSavingLocationStep = false;
  String? _locationSaveError;

  // Google Places Autocomplete & Details
  List<PlacePrediction> _namePredictions = [];
  bool _isSearchingName = false;
  String? _nameSearchNotice;
  Timer? _nameDebounceTimer;

  List<PlacePrediction> _streetPredictions = [];
  bool _isSearchingStreet = false;
  String? _streetSearchNotice;
  Timer? _streetDebounceTimer;

  String? _locationPlacesSessionToken;
  String? _googlePlaceId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _formattedAddress;
  String? _stateRegion;
  bool _isGoogleVerified = false;

  void _onLocationNameChanged(String val) {
    setState(() {
      _locationNameError = null;
      _nameSearchNotice = null;
    });
    _nameDebounceTimer?.cancel();
    final query = val.trim();
    if (query.length < 2) {
      _locationPlacesSessionToken = null;
      if (_namePredictions.isNotEmpty || _nameSearchNotice != null) {
        setState(() {
          _namePredictions = [];
          _nameSearchNotice = null;
        });
      }
      return;
    }

    _locationPlacesSessionToken ??= PlacesSessionToken.generate();

    _nameDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearchingName = true);
      final result = await GooglePlacesService.instance.searchPlacesWithResult(
        query: query,
        countryCode: _selectedCountryCode,
        sessionToken: _locationPlacesSessionToken,
      );
      if (mounted) {
        setState(() {
          _namePredictions = result.predictions;
          _isSearchingName = false;
          if (result.isZeroResults) {
            _nameSearchNotice =
                'No matching locations found. Try another search or enter the address manually.';
          } else if (result.isUnavailable) {
            _nameSearchNotice =
                'Location search is temporarily unavailable. You can enter the address manually.';
          } else {
            _nameSearchNotice = null;
          }
        });
      }
    });
  }

  Future<void> _selectNamePrediction(PlacePrediction prediction) async {
    final title = prediction.mainText.isNotEmpty
        ? prediction.mainText
        : prediction.description;
    setState(() {
      _locationNameController.text = title;
      _namePredictions = [];
      _nameSearchNotice = null;
    });
    if (prediction.placeId.isNotEmpty) {
      final details = await GooglePlacesService.instance.getPlaceDetails(
        prediction.placeId,
        sessionToken: _locationPlacesSessionToken,
      );
      _locationPlacesSessionToken = null; // Session ends on selection
      if (details != null && mounted) {
        setState(() {
          if (details.streetAddress.isNotEmpty) {
            _streetController.text = details.streetAddress;
          } else if (details.formattedAddress.isNotEmpty) {
            _streetController.text = details.formattedAddress;
          }
          if (details.city.isNotEmpty) {
            _cityController.text = details.city;
          }
          if (details.postalCode.isNotEmpty) {
            _postalController.text = details.postalCode;
          }
          _googlePlaceId = details.placeId;
          _selectedLatitude = details.latitude;
          _selectedLongitude = details.longitude;
          _formattedAddress = details.formattedAddress;
          _stateRegion = details.state;
          _isGoogleVerified = true;

          _locationNameError = null;
          _streetError = null;
          _cityError = null;
          _postalError = null;
        });
      }
    }
  }

  void _onStreetAddressChanged(String val) {
    setState(() {
      _streetError = null;
      _streetSearchNotice = null;
    });
    _streetDebounceTimer?.cancel();
    final query = val.trim();
    if (query.length < 2) {
      _locationPlacesSessionToken = null;
      if (_streetPredictions.isNotEmpty || _streetSearchNotice != null) {
        setState(() {
          _streetPredictions = [];
          _streetSearchNotice = null;
        });
      }
      return;
    }

    _locationPlacesSessionToken ??= PlacesSessionToken.generate();

    _streetDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearchingStreet = true);
      final result = await GooglePlacesService.instance.searchPlacesWithResult(
        query: query,
        countryCode: _selectedCountryCode,
        sessionToken: _locationPlacesSessionToken,
        types: 'address',
      );
      if (mounted) {
        setState(() {
          _streetPredictions = result.predictions;
          _isSearchingStreet = false;
          if (result.isZeroResults) {
            _streetSearchNotice =
                'No matching locations found. Try another search or enter the address manually.';
          } else if (result.isUnavailable) {
            _streetSearchNotice =
                'Location search is temporarily unavailable. You can enter the address manually.';
          } else {
            _streetSearchNotice = null;
          }
        });
      }
    });
  }

  Future<void> _selectStreetPrediction(PlacePrediction prediction) async {
    final addressText = prediction.mainText.isNotEmpty
        ? prediction.mainText
        : prediction.description;
    setState(() {
      _streetController.text = addressText;
      _streetPredictions = [];
      _streetSearchNotice = null;
    });
    if (prediction.placeId.isNotEmpty) {
      final details = await GooglePlacesService.instance.getPlaceDetails(
        prediction.placeId,
        sessionToken: _locationPlacesSessionToken,
      );
      _locationPlacesSessionToken = null; // Session ends on selection
      if (details != null && mounted) {
        setState(() {
          if (details.streetAddress.isNotEmpty) {
            _streetController.text = details.streetAddress;
          }
          if (details.city.isNotEmpty) {
            _cityController.text = details.city;
          }
          if (details.postalCode.isNotEmpty) {
            _postalController.text = details.postalCode;
          }
          _googlePlaceId = details.placeId;
          _selectedLatitude = details.latitude;
          _selectedLongitude = details.longitude;
          _formattedAddress = details.formattedAddress;
          _stateRegion = details.state;
          _isGoogleVerified = true;

          _streetError = null;
          _cityError = null;
          _postalError = null;
        });
      }
    }
  }

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
      'google_place_id': _googlePlaceId ?? '',
      'latitude': _selectedLatitude?.toString() ?? '',
      'longitude': _selectedLongitude?.toString() ?? '',
      'formatted_address': _formattedAddress ?? '',
      'is_verified': _isGoogleVerified ? 'true' : 'false',
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
      _locationPlacesSessionToken = null;
      _googlePlaceId = null;
      _selectedLatitude = null;
      _selectedLongitude = null;
      _formattedAddress = null;
      _stateRegion = null;
      _isGoogleVerified = false;
      _namePredictions = [];
      _streetPredictions = [];
      _nameSearchNotice = null;
      _streetSearchNotice = null;
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
        _googlePlaceId = loc['google_place_id']?.trim().isNotEmpty == true
            ? loc['google_place_id']
            : null;
        _selectedLatitude = loc['latitude']?.trim().isNotEmpty == true
            ? double.tryParse(loc['latitude']!)
            : null;
        _selectedLongitude = loc['longitude']?.trim().isNotEmpty == true
            ? double.tryParse(loc['longitude']!)
            : null;
        _formattedAddress = loc['formatted_address']?.trim().isNotEmpty == true
            ? loc['formatted_address']
            : null;
        _isGoogleVerified = loc['is_verified'] == 'true';
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
        _googlePlaceId = null;
        _selectedLatitude = null;
        _selectedLongitude = null;
        _formattedAddress = null;
        _stateRegion = null;
        _isGoogleVerified = false;
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
        'google_place_id': _googlePlaceId ?? '',
        'latitude': _selectedLatitude?.toString() ?? '',
        'longitude': _selectedLongitude?.toString() ?? '',
        'formatted_address': _formattedAddress ?? '',
        'is_verified': _isGoogleVerified ? 'true' : 'false',
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

    setState(() {
      _isSavingLocationStep = true;
      _locationSaveError = null;
    });

    try {
      final locRepo = widget.locationRepository ?? LocationRepository();
      final bizId = await CurrentBusinessService.instance.resolveCurrentBusinessId();

      StockLocation? firstPersisted;
      for (final loc in _configuredLocations) {
        try {
          final created = await locRepo.createLocation(
            name: loc['name'] ?? 'Primary Location',
            locationType: loc['type'] ?? 'retail_store',
            streetAddress: loc['street'],
            city: loc['city'],
            postalCode: loc['postal'],
            countryCode: loc['countryCode'] ?? _selectedCountryCode,
            businessId: bizId,
            googlePlaceId: loc['google_place_id']?.trim().isNotEmpty == true
                ? loc['google_place_id']
                : null,
            latitude: loc['latitude']?.trim().isNotEmpty == true
                ? double.tryParse(loc['latitude']!)
                : null,
            longitude: loc['longitude']?.trim().isNotEmpty == true
                ? double.tryParse(loc['longitude']!)
                : null,
            formattedAddress: loc['formatted_address']?.trim().isNotEmpty == true
                ? loc['formatted_address']
                : null,
          );
          firstPersisted ??= created;
        } on StateError catch (_) {
          final all = await locRepo.getLocations(
            businessId: bizId,
            onlyActive: false,
          );
          final existing = all.firstWhere(
            (l) => l.name.trim().toLowerCase() == (loc['name'] ?? '').trim().toLowerCase(),
            orElse: () => all.first,
          );
          firstPersisted ??= existing;
        }
      }

      if (firstPersisted != null) {
        CurrentBusinessService.instance.setCurrentLocationId(firstPersisted.id);
      }

      await _repository.markStepComplete(
        2,
        data: {'configuredLocations': _configuredLocations},
      );

      if (mounted) {
        setState(() {
          _isSavingLocationStep = false;
          _currentStep = 3;
        });
      }
    } catch (e) {
      debugPrint('[OnboardingPage] Error saving location: $e');
      if (mounted) {
        setState(() {
          _isSavingLocationStep = false;
          _locationSaveError = 'Could not save location. Please check details and try again.';
        });
      }
    }
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

  bool _isSavingCommerce = false;
  String? _commerceSaveError;

  Future<void> _saveCommerceAndContinue() async {
    if (_isSavingCommerce) return;
    if (!_validateCommerceStep()) return;

    setState(() {
      _isSavingCommerce = true;
      _commerceSaveError = null;
    });

    try {
      // 1. await the database upsert & 2. await onboarding step update
      await _repository.markStepComplete(
        3,
        data: {
          'selectedSalesChannels': _selectedSalesChannels,
          'paymentTerms': _paymentTerms,
          'taxSystem': _resolvedTaxSystemLabel,
        },
      );

      // 3. Invalidate/refresh the onboarding progress provider with authoritative persisted milestones
      final bizId = CurrentBusinessService.instance.currentBusinessId ??
          _repository.currentProgress.businessId;
      if (bizId != null && bizId.isNotEmpty) {
        await _repository.loadProgressForBusiness(bizId);
      }

      // 4. Rebuild the stepper/progress with refreshed persisted state
      // 5. Navigate to Inventory only after refreshed state is available
      if (mounted) {
        setState(() {
          _isSavingCommerce = false;
          _hydrateFields(_repository.currentProgress);
          _currentStep = 4;
        });
      }
    } catch (e) {
      debugPrint('[OnboardingPage] Error saving commerce profile: $e');
      if (mounted) {
        setState(() {
          _isSavingCommerce = false;
          _commerceSaveError =
              'Could not save commerce profile. Please check details and try again.';
        });
      }
    }
  }

  // Step 4: Inventory ingestion option — null until the user explicitly chooses.
  InventoryStartMethod? _inventoryStartMethod;
  String? _inventorySelectionError;
  bool _isInitializingCatalog = false;
  bool _isSkippingToDashboard = false;

  String _inventoryMethodToString(InventoryStartMethod method) {
    switch (method) {
      case InventoryStartMethod.manual:
        return 'manual';
      case InventoryStartMethod.fileImport:
        return 'file_import';
      case InventoryStartMethod.shopify:
        return 'shopify';
    }
  }

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
    if (_isInitializingCatalog || _isSkippingToDashboard) {
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
                await _repository.markStepComplete(
                  4,
                  data: {
                    'inventoryStartMethod': _inventoryMethodToString(method),
                    'inventorySetupStatus': 'completed',
                  },
                );
                if (mounted) {
                  setState(() {});
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
              'inventoryStartMethod': _inventoryMethodToString(method),
              'inventorySetupStatus': 'completed',
            },
          );
        }
        if (mounted) {
          setState(() {});
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

  Future<void> _skipAndGoToDashboard() async {
    if (_isSkippingToDashboard || _isInitializingCatalog) {
      return;
    }

    // MANDATORY REQUIREMENT: Business and Location cannot be bypassed by Skip
    if (!_repository.currentProgress.isLocationCompleted) {
      if (mounted) {
        setState(() {
          _isSkippingToDashboard = false;
          _currentStep = 2; // Route to mandatory Location step
          _inventorySelectionError =
              'At least one location must be configured before accessing the dashboard.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please configure at least one location before proceeding to the dashboard.',
            ),
            backgroundColor: Color(0xFFC5A059),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSkippingToDashboard = true;
      _inventorySelectionError = null;
    });

    try {
      final bizId = _repository.currentProgress.businessId ??
          CurrentBusinessService.instance.currentBusinessId;
      final methodStr = _inventoryStartMethod != null
          ? _inventoryMethodToString(_inventoryStartMethod!)
          : null;

      // 1. Persist completion
      final completeProgress = await _repository.skipToDashboard(
        businessId: bizId,
        inventoryStartMethod: methodStr,
      );

      // 2. Verify success
      if (!completeProgress.isOnboardingCompleted) {
        throw Exception('Failed to record onboarding completion.');
      }

      // 3. Update/invalidate onboarding provider & business preferences
      if (bizId != null && bizId.isNotEmpty) {
        await AppPreferencesService.instance.setCurrentBusinessId(bizId);
        CurrentBusinessService.instance.setCurrentBusinessId(bizId);
        try {
          await AuthorizationService.instance
              .refreshAuthorization(businessId: bizId);
        } catch (e) {
          debugPrint('[OnboardingPage] Notice refreshing authorization: $e');
        }
      }

      // 4. Clear local onboarding state
      // (Atomic inside skipToDashboard)

      if (!mounted) return;

      // 5. Route-replace directly to Overview/Dashboard
      await NavigationGuard.safePushNamedAndRemoveUntil(
        context,
        AppRoutes.overview,
        (route) => false,
        source: 'OnboardingPage._skipAndGoToDashboard',
      );
    } catch (e, st) {
      debugPrint('[OnboardingPage] Skip & Go to Dashboard failed: $e\n$st');
      if (mounted) {
        final isLocationMissing = e is StateError && e.message.contains('location');
        setState(() {
          _inventorySelectionError = isLocationMissing
              ? 'At least one location must be configured before accessing the dashboard.'
              : 'Unable to complete onboarding. Please check your connection and try again.';
          _isSkippingToDashboard = false;
          if (isLocationMissing) {
            _currentStep = 2;
          }
        });
      }
    } finally {
      if (mounted && _isSkippingToDashboard) {
        setState(() {
          _isSkippingToDashboard = false;
        });
      }
    }
  }

  // Step 5: Team members (starts with 0 demo members)
  final List<Map<String, String>> _savedTeamInvites = [];

  static const List<String> _stepLabels = [
    'Login',
    'Business',
    'Location',
    'Commerce',
    'Inventory',
    'Team',
  ];

  @override
  void dispose() {
    CurrentBusinessService.instance.removeListener(_onCurrentBusinessChanged);
    _nameDebounceTimer?.cancel();
    _streetDebounceTimer?.cancel();
    _businessNameController.dispose();
    _locationNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _onCurrentBusinessChanged() {
    if (mounted) {
      setState(() {});
    }
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
      final currentBizId = CurrentBusinessService.instance.currentBusinessId ??
          CurrentBusinessService.instance.currentBusiness?.id;
      final onboardingBizId = _repository.currentProgress.businessId;
      final targetBizId = currentBizId ?? onboardingBizId;

      String errorCode = 'UNKNOWN';
      String errorMsg = e.toString();
      String? errorDetails;
      String? errorHint;

      if (e is PostgrestException) {
        errorCode = e.code ?? 'POSTGREST_ERROR';
        errorMsg = e.message;
        errorDetails = e.details?.toString();
        errorHint = e.hint?.toString();
      } else if (e is AuthException) {
        errorCode = e.statusCode ?? 'AUTH_ERROR';
        errorMsg = e.message;
      }

      debugPrint(
        '==========================================================\n'
        'Business update failed\n'
        'operation: update_business\n'
        'business_id: ${targetBizId ?? "unknown"}\n'
        'postgres_code: $errorCode\n'
        'message: $errorMsg\n'
        'details: ${errorDetails ?? "none"}\n'
        'hint: ${errorHint ?? "none"}\n'
        '==========================================================',
      );

      String userFacingError =
          "We couldn't save your business setup.\nPlease try again.";

      if (errorMsg.contains('Anonymous Sign-Ins are disabled')) {
        userFacingError =
            'Anonymous Sign-Ins are disabled in your Supabase project. '
            'Please sign in with a registered account or check project authentication settings.';
      } else if (sb != null && !authUserPresent) {
        userFacingError =
            "We couldn't establish an authenticated session.\n"
            "Please sign in to your account, then try again.";
      } else if (errorMsg.contains('record not found or not owned') ||
                 errorMsg.contains('Business ID mismatch')) {
        userFacingError =
            'Workspace authorization failed. Please reload the workspace or re-authenticate.';
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
    final completeProgress = await _repository.markStepComplete(6);
    if (!mounted) return;
    final bizId = completeProgress.businessId ??
        CurrentBusinessService.instance.currentBusinessId;
    if (bizId != null && bizId.isNotEmpty) {
      await AppPreferencesService.instance.setCurrentBusinessId(bizId);
      CurrentBusinessService.instance.setCurrentBusinessId(bizId);
      await CurrentBusinessService.instance
          .resolveCurrentBusinessId(forceRefresh: true);
      await _repository.loadProgressForBusiness(bizId);
      try {
        await AuthorizationService.instance
            .refreshAuthorization(businessId: bizId);
      } catch (e) {
        debugPrint('[OnboardingPage] Notice refreshing authorization: $e');
      }
    }
    if (!mounted) return;
    // Navigate to the explicit overview route so the router knows it is a
    // post-onboarding destination. Navigating to '/' can ambiguously resolve
    // via the default case before the router has a chance to read the updated
    // progress. Using AppRoutes.overview is unambiguous.
    await NavigationGuard.safePushNamedAndRemoveUntil(
      context,
      AppRoutes.overview,
      (route) => false,
      source: 'OnboardingPage._finishOnboarding',
    );
  }

  /// Checks if the user has entered unsaved edits on the current onboarding step.
  bool get _hasUnsavedEdits {
    final progress = _repository.currentProgress;
    switch (_currentStep) {
      case 1:
        final nameChanged = _businessNameController.text.trim().isNotEmpty &&
            _businessNameController.text.trim() != (progress.businessName ?? '');
        final typeChanged = _selectedIndustry != null &&
            _selectedIndustry != progress.businessType;
        final countryChanged = _selectedCountryCode != null &&
            _selectedCountryCode != progress.countryCode;
        return nameChanged || typeChanged || countryChanged;
      case 2:
        return _locationNameController.text.trim().isNotEmpty ||
            _streetController.text.trim().isNotEmpty ||
            _cityController.text.trim().isNotEmpty;
      case 3:
        return _selectedSalesChannels.isNotEmpty &&
            _selectedSalesChannels != progress.selectedSalesChannels;
      case 4:
        return _inventoryStartMethod != null &&
            (_inventoryMethodToString(_inventoryStartMethod!) != progress.inventoryStartMethod);
      default:
        return false;
    }
  }

  /// Prompts for confirmation if unsaved edits exist, then purges local session and routes to Login.
  Future<void> _handleSignOut() async {
    if (_hasUnsavedEdits) {
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFFAF7F2),
          title: Text(
            'Sign out?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          content: Text(
            'Unsaved changes on this page will be lost.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF5E574E),
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A7268),
                ),
              ),
            ),
            ElevatedButton(
              key: const ValueKey('confirm_sign_out_button'),
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                'Sign out',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldSignOut != true) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    try {
      await AuthService.instance.signOut();
    } catch (e) {
      debugPrint('[OnboardingPage] Error signing out: $e');
    }

    if (!mounted) return;
    await NavigationGuard.safePushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
      source: 'OnboardingPage._handleSignOut',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingCompletion || _repository.currentProgress.isOnboardingCompleted) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

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
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 36,
                    vertical: isMobile ? 8 : 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: isMobile ? 50 : 145,
                            maxWidth: isMobile ? 120 : 340,
                          ),
                          child: Image.asset(
                            'Assets/logo.png',
                            height: isMobile ? 50 : 145,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 4 : 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.help_outline_rounded,
                                        size: 15,
                                        color: Color(0xFF1E1C1A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isMobile ? 'Support' : 'ThreadStock Support',
                                        style: GoogleFonts.inter(
                                          fontSize: isMobile ? 11.5 : 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1E1C1A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '|',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFD6CABD),
                                  ),
                                ),
                              ),
                              InkWell(
                                key: const ValueKey('onboarding_sign_out_button'),
                                onTap: _handleSignOut,
                                borderRadius: BorderRadius.circular(20),
                                hoverColor: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.logout_rounded,
                                        size: 14,
                                        color: Color(0xFF7A7268),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Sign out',
                                        style: GoogleFonts.inter(
                                          fontSize: isMobile ? 12 : 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7A7268),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Subtle Workspace / Business indicator across all onboarding pages
                          Container(
                            key: const ValueKey('onboarding_workspace_badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EFE6).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDFD4C5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.business_outlined,
                                  size: 12,
                                  color: Color(0xFFBA8A55),
                                ),
                                const SizedBox(width: 5),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isMobile ? 130 : 240,
                                  ),
                                  child: Text(
                                    'Setting up: $_currentBusinessDisplayName',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 10.5 : 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF5E574E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center Content Area (Biased slightly upward for luxury spacing)
                Expanded(
                  child: Align(
                    alignment: const Alignment(0.0, -0.28),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 12 : 20,
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

                // Bottom Steps Navigation Bar (Clearly separated vertical zone)
                Container(
                  padding: EdgeInsets.only(
                    top: isMobile ? 14 : 22,
                    bottom: isMobile ? 18 : 30,
                    left: isMobile ? 12 : 24,
                    right: isMobile ? 12 : 24,
                  ),
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
  Widget _buildCompactProgressBar(
    int percentage,
    int completedCount, {
    bool isMobile = false,
  }) {
    final trackWidth = isMobile ? 90.0 : 130.0;
    final spacing = isMobile ? 8.0 : 14.0;
    final fontSize = isMobile ? 11.5 : 12.5;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$percentage% completed',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5E574E),
            ),
          ),
          SizedBox(width: spacing),
          // Progress track & bar (thin 2.5px height, rounded ends)
          Container(
            width: trackWidth,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5DACD),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (percentage / 100.0).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBA8A55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          const Text(
            '|',
            style: TextStyle(
              color: Color(0xFFD6CABD),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(width: spacing),
          Text(
            '$completedCount of 6 completed',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5E574E),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 0: WELCOME / BUSINESS (Exact matching design)
  // ==========================================
  Widget _buildStep0Welcome() {
    final progress = _repository.currentProgress;
    final activeBizId = CurrentBusinessService.instance.currentBusinessId ??
        progress.businessId;
    final hasBusiness = activeBizId != null && activeBizId.isNotEmpty;
    final hasIncompleteBusiness = hasBusiness && !progress.isOnboardingCompleted;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    final percentage = progress.progressPercentage;
    final completedCount = progress.completedMilestoneCount;

    return Column(
      key: const ValueKey('step_0_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pill: ThreadStock OS V2.0
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECE1).withValues(alpha: 0.85),
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
        SizedBox(height: isMobile ? 18 : 24),

        // Welcome to ThreadStock (Main editorial serif — Cormorant Garamond)
        Text(
          'Welcome to ThreadStock',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: isMobile ? 40 : 60,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF161412),
            letterSpacing: -0.5,
            height: 1.05,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),

        // AI Inventory & Commerce OS for Fashion (Gold subtitle — Inter SemiBold)
        Text(
          'AI Inventory & Commerce OS for Fashion',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 17 : 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFBA8A55),
          ),
        ),
        SizedBox(height: isMobile ? 14 : 18),

        // Subtext description (UI / body sans-serif — Inter)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'You’re in! Let’s set up your workspace.\n'
            'ThreadStock will help you configure your business,\n'
            'set up locations, commerce, inventory and team settings\n'
            'in a few simple steps.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 14 : 15.5,
              height: 1.6,
              color: const Color(0xFF5E574E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 18 : 24),

        // Compact Progress Line
        _buildCompactProgressBar(
          percentage,
          completedCount,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 24 : 32),

        // Conditional CTA Button: Set Up My Business OR Continue Setup
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: ValueKey(
              hasIncompleteBusiness
                  ? 'btn_continue_setup'
                  : 'btn_setup_business',
            ),
            onPressed: () {
              if (hasIncompleteBusiness) {
                final targetViewStep =
                    (progress.firstIncompleteStep - 1).clamp(0, 5);
                _goToStep(targetViewStep);
              } else {
                _nextStep();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    hasIncompleteBusiness
                        ? 'Continue Setup'
                        : 'Set Up My Business',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13.5 : 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 1: BUSINESS PROFILE (Canonical Step 1 of 5)
  // ==========================================
  Widget _buildStep1Business() {
    final progress = _repository.currentProgress;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return ConstrainedBox(
      key: const ValueKey('step_1_business'),
      constraints: const BoxConstraints(maxWidth: 540),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 36,
          vertical: isMobile ? 24 : 34,
        ),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STEP 2 OF 6 — BUSINESS',
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
                fontSize: isMobile ? 28 : 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Provide your legal and operational details to configure your workspace.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF615B52),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactProgressBar(
              progress.progressPercentage,
              progress.completedMilestoneCount,
              isMobile: isMobile,
            ),
            const SizedBox(height: 22),

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
                  hint: 'e.g. Acme Sartoria',
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
    final progress = _repository.currentProgress;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

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
              padding: EdgeInsets.all(isMobile ? 20 : 36),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 3 OF 6 — LOCATION',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: const Color(0xFFBA8A55),
                        ),
                      ),
                      if (_selectedCountryCode != null &&
                          _selectedCountryCode!.isNotEmpty)
                        Flexible(
                          child: Container(
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
                                Flexible(
                                  child: Text(
                                    '${CountryCurrencyReference.countryNameFor(_selectedCountryCode)} (${_selectedCountryCode!})',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3B362F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      fontSize: isMobile ? 28 : 34,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF161412),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set up your warehouse, boutique, or fulfillment center.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF615B52),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCompactProgressBar(
                    progress.progressPercentage,
                    progress.completedMilestoneCount,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildFormField(
                          label: 'LOCATION NAME *',
                          errorText: _locationNameError,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _locationNameController,
                                onChanged: _onLocationNameChanged,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Enter location name',
                                  suffixIcon: _isSearchingName
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFFBA8A55),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.search_rounded,
                                          size: 18,
                                          color: Color(0xFF9E9589),
                                        ),
                                ),
                              ),
                              if (_namePredictions.isNotEmpty ||
                                  _nameSearchNotice != null ||
                                  _isSearchingName)
                                _buildPredictionsDropdown(
                                  predictions: _namePredictions,
                                  isSearching: _isSearchingName,
                                  notice: _nameSearchNotice,
                                  onSelect: _selectNamePrediction,
                                ),
                            ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _streetController,
                          onChanged: _onStreetAddressChanged,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Enter street address',
                            suffixIcon: _isSearchingStreet
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFBA8A55),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: Color(0xFF9E9589),
                                  ),
                          ),
                        ),
                        if (_streetPredictions.isNotEmpty ||
                            _streetSearchNotice != null ||
                            _isSearchingStreet)
                          _buildPredictionsDropdown(
                            predictions: _streetPredictions,
                            isSearching: _isSearchingStreet,
                            notice: _streetSearchNotice,
                            onSelect: _selectStreetPrediction,
                          ),
                      ],
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
                  // Real Google Maps View + Coordinates & Verified / Manual Summary
                  GoogleLocationMapView(
                    latitude: _selectedLatitude,
                    longitude: _selectedLongitude,
                    placeName: _locationNameController.text.trim(),
                    formattedAddress: _formattedAddress,
                    streetAddress: _streetController.text.trim(),
                    city: _cityController.text.trim(),
                    postalCode: _postalController.text.trim(),
                    state: _stateRegion,
                    country: CountryCurrencyReference.countryNameFor(
                      _selectedCountryCode,
                    ),
                    isVerified: _isGoogleVerified,
                    interactive: true,
                    onCoordinatesChanged: (newLatLng) {
                      setState(() {
                        _selectedLatitude = newLatLng.latitude;
                        _selectedLongitude = newLatLng.longitude;
                      });
                    },
                  ),

                  if (_locationSaveError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFA39E)),
                      ),
                      child: Text(
                        _locationSaveError!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCF1322),
                        ),
                      ),
                    ),
                  ],

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
                          onPressed: _isSavingLocationStep
                              ? null
                              : _saveAndContinueStep1,
                          iconAlignment: IconAlignment.end,
                          icon: _isSavingLocationStep
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _isSavingLocationStep
                                ? 'Saving Location...'
                                : 'Save & Continue',
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

  Widget _buildPredictionsDropdown({
    required List<PlacePrediction> predictions,
    required ValueChanged<PlacePrediction> onSelect,
    bool isSearching = false,
    String? notice,
  }) {
    if (!isSearching && notice == null && predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCCFBE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: isSearching && predictions.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFBA8A55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Searching...',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ],
              ),
            )
          : notice != null && predictions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF5E574E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: predictions.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFFF2ECE1),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final pred = predictions[index];
                    return InkWell(
                      onTap: () => onSelect(pred),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFFBA8A55),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pred.mainText.isNotEmpty
                                        ? pred.mainText
                                        : pred.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E1C1A),
                                    ),
                                  ),
                                  if (pred.secondaryText.isNotEmpty)
                                    Text(
                                      pred.secondaryText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF7A7268),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // ==========================================
  // STEP 3: COMMERCE (Channel Architecture)
  // ==========================================
  Widget _buildStep3Commerce() {
    final progress = _repository.currentProgress;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return ConstrainedBox(
      key: const ValueKey('step_3_commerce'),
      constraints: const BoxConstraints(maxWidth: 760),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 4 OF 6 — COMMERCE',
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
                fontSize: isMobile ? 28 : 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select the primary sales and fulfillment channels for your operations.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF615B52),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactProgressBar(
              progress.progressPercentage,
              progress.completedMilestoneCount,
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
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
            if (_commerceSaveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _commerceSaveError!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC84030),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Action Row
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  key: const ValueKey('commerce_continue_button'),
                  onPressed: _isSavingCommerce ? null : _saveCommerceAndContinue,
                  iconAlignment: IconAlignment.end,
                  icon: _isSavingCommerce
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
                    _isSavingCommerce ? 'Saving...' : 'Continue to Inventory',
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
    final progress = _repository.currentProgress;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return ConstrainedBox(
      key: const ValueKey('step_4_inventory'),
      constraints: const BoxConstraints(maxWidth: 880),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 5 OF 6 — INVENTORY',
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
                fontSize: isMobile ? 28 : 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how your initial catalog and stock units are brought into ThreadStock.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF615B52),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactProgressBar(
              progress.progressPercentage,
              progress.completedMilestoneCount,
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),

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
                              !_isInitializingCatalog &&
                              !_isSkippingToDashboard)
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
                      onPressed: (!_isSkippingToDashboard &&
                              !_isInitializingCatalog)
                          ? _skipAndGoToDashboard
                          : null,
                      iconAlignment: IconAlignment.end,
                      icon: _isSkippingToDashboard
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
                        _isSkippingToDashboard
                            ? 'Completing…'
                            : 'Skip & Go to Dashboard',
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
    final progress = _repository.currentProgress;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return TeamOnboardingView(
      key: const ValueKey('step_5_team'),
      progressBar: _buildCompactProgressBar(
        progress.progressPercentage,
        progress.completedMilestoneCount,
        isMobile: isMobile,
      ),
      businessName: _currentBusinessDisplayName,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return ConstrainedBox(
      key: const ValueKey('step_6_ready'),
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 44),
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
            const SizedBox(height: 16),

            // Title: Your workspace is ready (Editorial Serif: Cormorant Garamond)
            Text(
              'Your workspace is ready',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isMobile ? 30 : 38,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Here is a summary of your setup.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B6358),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactProgressBar(100, 6, isMobile: isMobile),
            const SizedBox(height: 22),

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_stepLabels.length * 2 - 1, (index) {
          // Milestone for current form step:
          // On Welcome screen (_currentStep == 0):
          // User has completed Login, but has NOT started Business setup yet.
          // No form step is active/current on the Welcome screen.
          // On Form steps (_currentStep >= 1):
          // Form step 1 is Business (milestone 2), form step 2 is Location (milestone 3), etc.
          final int? activeMilestone;
          if (_currentStep == 0) {
            activeMilestone = null;
          } else {
            activeMilestone = _currentStep + 1;
          }

          if (index.isOdd) {
            // Connector line between step (index ~/ 2) and step (index ~/ 2 + 1)
            final leftStepNumber = (index ~/ 2) + 1;
            final rightStepNumber = leftStepNumber + 1;

            final leftCompleted = progress.isMilestoneCompleted(leftStepNumber);
            final rightCompleted = progress.isMilestoneCompleted(rightStepNumber);
            final rightActive = !rightCompleted &&
                activeMilestone != null &&
                rightStepNumber == activeMilestone;

            // Rules:
            // completed -> completed: gold
            // completed -> active: gold
            // active -> upcoming: muted/light
            // upcoming -> upcoming: muted/light
            final isConnectorActive =
                leftCompleted && (rightCompleted || rightActive);

            return Container(
              key: ValueKey('stepper_connector_${leftStepNumber}_$rightStepNumber'),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 22,
              height: 1.5,
              decoration: BoxDecoration(
                color: isConnectorActive
                    ? const Color(0xFFBA8A55)
                    : const Color(0xFFD6CABD),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }

          final stepIdx = index ~/ 2;
          final stepNumber = stepIdx + 1; // 1 to 6
          final isCompleted = progress.isMilestoneCompleted(stepNumber);

          final isActive = !isCompleted && activeMilestone != null && stepNumber == activeMilestone;
          final isLocked = stepNumber > (progress.completedMilestoneCount + 1);

          VoidCallback? onTap;
          if (!isLocked) {
            if (stepNumber == 1) {
              onTap = () => _goToStep(0);
            } else {
              onTap = () => _goToStep(stepNumber - 1);
            }
          }

          return _buildStepBadge(
            stepNumber: stepNumber,
            label: _stepLabels[stepIdx],
            isActive: isActive,
            isCompleted: isCompleted,
            isLocked: isLocked,
            onTap: onTap,
          );
        }),
      ),
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
    Color borderColor =
        isLocked ? const Color(0xFFE5DACD) : const Color(0xFFD6CABD);
    Widget circleContent;

    if (isCompleted) {
      // Completed step: champagne-gold filled circle with white check
      circleBg = const Color(0xFFBA8A55);
      borderColor = const Color(0xFFBA8A55);
      circleContent = const Icon(
        Icons.check_rounded,
        size: 12,
        color: Colors.white,
      );
    } else if (isActive) {
      // Current step: gold filled circle with white number, stronger label
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
    } else {
      // Upcoming steps: very light border, muted gray text
      circleBg = Colors.transparent;
      borderColor =
          isLocked ? const Color(0xFFE5DACD) : const Color(0xFFD6CABD);
      circleContent = Text(
        '$stepNumber',
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isLocked ? const Color(0xFFA59B8E) : const Color(0xFF6E665C),
        ),
      );
    }

    final Color labelColor;
    final FontWeight labelWeight;
    if (isActive) {
      labelColor = const Color(0xFF1E1C1A);
      labelWeight = FontWeight.w600;
    } else if (isCompleted) {
      labelColor = const Color(0xFF2E2A25);
      labelWeight = FontWeight.w500;
    } else {
      labelColor = isLocked ? const Color(0xFFA59B8E) : const Color(0xFF6E665C);
      labelWeight = FontWeight.w400;
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
                      fontWeight: labelWeight,
                      color: labelColor,
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
  InputDecoration _inputDecoration({
    required String hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
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
