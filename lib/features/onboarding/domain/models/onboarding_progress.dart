import '../../../../core/reference/country_currency_reference.dart';

class OnboardingProgress {
  final bool isBusinessCompleted;
  final bool isLocationCompleted;
  final bool isCommerceCompleted;
  final bool isInventoryCompleted;
  final bool isTeamCompleted;
  final bool isOnboardingCompleted;

  // Step 1: Business Profile
  final String? businessId;
  final String? businessName;
  final String? businessType;
  final String? countryCode;
  final String? currencyCode;
  final String? locationRange;

  // Step 2: Locations
  final List<Map<String, dynamic>> configuredLocations;

  // Step 3: Commerce
  final Set<int> selectedSalesChannels;
  final String? paymentTerms;

  // Step 4: Inventory
  final String? inventoryStartMethod;
  final String? inventorySetupStatus;

  // Step 5: Team
  final List<Map<String, dynamic>> savedTeamInvites;

  const OnboardingProgress({
    this.isBusinessCompleted = false,
    this.isLocationCompleted = false,
    this.isCommerceCompleted = false,
    this.isInventoryCompleted = false,
    this.isTeamCompleted = false,
    this.isOnboardingCompleted = false,
    this.businessId,
    this.businessName,
    this.businessType,
    this.countryCode,
    this.currencyCode,
    this.locationRange,
    this.configuredLocations = const [],
    this.selectedSalesChannels = const {},
    this.paymentTerms,
    this.inventoryStartMethod,
    this.inventorySetupStatus,
    this.savedTeamInvites = const [],
  });

  bool get isInventorySkipped => inventorySetupStatus == 'skipped';
  bool get isTeamSkipped => false;

  /// Total milestones in the onboarding journey:
  /// 1. Login
  /// 2. Business
  /// 3. Location
  /// 4. Commerce
  /// 5. Inventory
  /// 6. Team
  static const int totalMilestones = 6;

  /// Returns the number of completed onboarding milestones (1..6).
  /// Milestone 1 (Login) is completed for authenticated users.
  int get completedMilestoneCount {
    if (isOnboardingCompleted) return 6;
    int count = 1; // Milestone 1: Login is completed for authenticated session
    if (isBusinessCompleted) {
      count = 2;
    } else {
      return count;
    }
    if (isLocationCompleted) {
      count = 3;
    } else {
      return count;
    }
    if (isCommerceCompleted) {
      count = 4;
    } else {
      return count;
    }
    if (isInventoryCompleted) {
      count = 5;
    } else {
      return count;
    }
    if (isTeamCompleted) {
      count = 6;
    }
    return count;
  }

  /// Rounded display percentages per spec:
  /// 1 / 6 = 17% (Login complete only)
  /// 2 / 6 = 33% (Business complete)
  /// 3 / 6 = 50% (Location complete)
  /// 4 / 6 = 67% (Commerce complete)
  /// 5 / 6 = 83% (Inventory complete)
  /// 6 / 6 = 100% (Team complete / Onboarding complete)
  int get progressPercentage {
    switch (completedMilestoneCount) {
      case 1:
        return 17;
      case 2:
        return 33;
      case 3:
        return 50;
      case 4:
        return 67;
      case 5:
        return 83;
      case 6:
        return 100;
      default:
        return 17;
    }
  }

  /// Number of remaining steps out of 6 milestones (e.g. 5, 4, 3, 2, 1, 0)
  int get remainingStepsCount {
    final remaining = totalMilestones - completedMilestoneCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Check whether a 6-milestone step (1..6) is completed:
  /// 1 = Login (always true for authenticated user)
  /// 2 = Business (isBusinessCompleted)
  /// 3 = Location (isLocationCompleted)
  /// 4 = Commerce (isCommerceCompleted)
  /// 5 = Inventory (isInventoryCompleted)
  /// 6 = Team (isTeamCompleted || isOnboardingCompleted)
  bool isMilestoneCompleted(int milestoneNumber) {
    if (isOnboardingCompleted) return true;
    switch (milestoneNumber) {
      case 1:
        return true; // Login is completed
      case 2:
        return isBusinessCompleted;
      case 3:
        return isBusinessCompleted && isLocationCompleted;
      case 4:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted;
      case 5:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted &&
            isInventoryCompleted;
      case 6:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted &&
            isInventoryCompleted &&
            isTeamCompleted;
      default:
        return false;
    }
  }

  /// The first milestone step (2..6) that has not yet been marked completed.
  /// 1 = Login (completed upon auth)
  /// 2 = Business
  /// 3 = Location
  /// 4 = Commerce
  /// 5 = Inventory
  /// 6 = Team
  /// 7 = Fully completed onboarding
  int get firstIncompleteStep {
    if (!isBusinessCompleted) return 2;
    if (!isLocationCompleted) return 3;
    if (!isCommerceCompleted) return 4;
    if (!isInventoryCompleted) return 5;
    if (!isTeamCompleted) return 6;
    if (!isOnboardingCompleted) return 6;
    return 7;
  }

  /// Check whether a step can be accessed.
  /// Sequential progression requires all prerequisite steps to be completed.
  /// - Step <= 2 (Welcome / Business): always accessible.
  /// - Step 3 (Location milestone): requires Business completed.
  /// - Step 4 (Commerce milestone): requires Location completed.
  /// - Step 5 (Inventory milestone): requires Commerce completed.
  /// - Step 6 (Team milestone): requires Inventory completed.
  /// - Once onboarding is complete: all steps are accessible for review.
  bool isStepAccessible(int step) {
    if (step <= 1) return true;
    if (isOnboardingCompleted) return true;
    if (step == 2) return isBusinessCompleted;
    if (step == 3) return isBusinessCompleted && isLocationCompleted;
    if (step == 4) {
      return isBusinessCompleted &&
          isLocationCompleted &&
          isCommerceCompleted;
    }
    if (step == 5) {
      return isBusinessCompleted &&
          isLocationCompleted &&
          isCommerceCompleted &&
          (isInventoryCompleted || isInventorySkipped);
    }
    if (step == 6) {
      return isBusinessCompleted &&
          isLocationCompleted &&
          isCommerceCompleted &&
          (isInventoryCompleted || isInventorySkipped) &&
          (isTeamCompleted || isTeamSkipped);
    }
    return false;
  }

  /// Check whether a step is marked complete.
  /// Sequential progression requires all prerequisite steps to be completed.
  bool isStepCompleted(int step) {
    if (isOnboardingCompleted) return true;
    switch (step) {
      case 1:
        return isBusinessCompleted;
      case 2:
        return isBusinessCompleted && isLocationCompleted;
      case 3:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted;
      case 4:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted &&
            isInventoryCompleted;
      case 5:
        return isBusinessCompleted &&
            isLocationCompleted &&
            isCommerceCompleted &&
            isInventoryCompleted &&
            isTeamCompleted;
      case 6:
        return isOnboardingCompleted;
      default:
        return false;
    }
  }

  /// Returns true if any configured location has a country code different from the
  /// target country or has an invalid postal code for the target country.
  bool hasIncompatibleLocations(String? targetCountry) {
    if (targetCountry == null ||
        targetCountry.isEmpty ||
        configuredLocations.isEmpty) {
      return false;
    }
    final normalized = targetCountry.trim().toUpperCase();
    for (final loc in configuredLocations) {
      final locCountry = (loc['countryCode'] as String?)?.trim().toUpperCase();
      if (locCountry != null &&
          locCountry.isNotEmpty &&
          locCountry != normalized) {
        return true;
      }
      final postal = loc['postal'] as String?;
      if (postal != null &&
          !CountryCurrencyReference.isValidPostalCode(normalized, postal)) {
        return true;
      }
    }
    return false;
  }

  OnboardingProgress copyWith({
    bool? isBusinessCompleted,
    bool? isLocationCompleted,
    bool? isCommerceCompleted,
    bool? isInventoryCompleted,
    bool? isTeamCompleted,
    bool? isOnboardingCompleted,
    String? businessId,
    String? businessName,
    String? businessType,
    String? countryCode,
    String? currencyCode,
    String? locationRange,
    List<Map<String, dynamic>>? configuredLocations,
    Set<int>? selectedSalesChannels,
    String? paymentTerms,
    String? inventoryStartMethod,
    String? inventorySetupStatus,
    List<Map<String, dynamic>>? savedTeamInvites,
  }) {
    return OnboardingProgress(
      isBusinessCompleted: isBusinessCompleted ?? this.isBusinessCompleted,
      isLocationCompleted: isLocationCompleted ?? this.isLocationCompleted,
      isCommerceCompleted: isCommerceCompleted ?? this.isCommerceCompleted,
      isInventoryCompleted: isInventoryCompleted ?? this.isInventoryCompleted,
      isTeamCompleted: isTeamCompleted ?? this.isTeamCompleted,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      locationRange: locationRange ?? this.locationRange,
      configuredLocations: configuredLocations ?? this.configuredLocations,
      selectedSalesChannels:
          selectedSalesChannels ?? this.selectedSalesChannels,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      inventoryStartMethod: inventoryStartMethod ?? this.inventoryStartMethod,
      inventorySetupStatus: inventorySetupStatus ?? this.inventorySetupStatus,
      savedTeamInvites: savedTeamInvites ?? this.savedTeamInvites,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBusinessCompleted': isBusinessCompleted,
      'isLocationCompleted': isLocationCompleted,
      'isCommerceCompleted': isCommerceCompleted,
      'isInventoryCompleted': isInventoryCompleted,
      'isTeamCompleted': isTeamCompleted,
      'isOnboardingCompleted': isOnboardingCompleted,
      'businessId': businessId,
      'businessName': businessName,
      'businessType': businessType,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'locationRange': locationRange,
      'configuredLocations': configuredLocations,
      'selectedSalesChannels': selectedSalesChannels.toList(),
      'paymentTerms': paymentTerms,
      'inventoryStartMethod': inventoryStartMethod,
      'inventorySetupStatus': inventorySetupStatus,
      'savedTeamInvites': savedTeamInvites,
    };
  }

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final allComplete = json['isOnboardingCompleted'] as bool? ?? false;
    final rawBiz = json['isBusinessCompleted'] as bool? ?? false;
    final rawLoc = json['isLocationCompleted'] as bool? ?? false;
    final rawCom = json['isCommerceCompleted'] as bool? ?? false;
    final setupStatus = json['inventorySetupStatus'] as String?;
    final rawInv =
        (json['isInventoryCompleted'] as bool? ?? false) &&
        (allComplete || setupStatus == null || setupStatus == 'completed');
    final rawTeam = json['isTeamCompleted'] as bool? ?? false;

    // Enforce sequential progression: downstream steps cannot be complete if upstream steps are not.
    final bizComplete = allComplete || rawBiz;
    final locComplete = allComplete || (bizComplete && rawLoc);
    final comComplete = allComplete || (locComplete && rawCom);
    final invComplete = allComplete || (comComplete && rawInv);
    final teamComplete = allComplete || (invComplete && rawTeam);

    return OnboardingProgress(
      isBusinessCompleted: bizComplete,
      isLocationCompleted: locComplete,
      isCommerceCompleted: comComplete,
      isInventoryCompleted: invComplete,
      isTeamCompleted: teamComplete,
      isOnboardingCompleted: allComplete,
      businessId: json['businessId'] as String?,
      businessName: json['businessName'] as String?,
      businessType: json['businessType'] as String?,
      countryCode: json['countryCode'] as String?,
      currencyCode: json['currencyCode'] as String?,
      locationRange: json['locationRange'] as String?,
      configuredLocations:
          (json['configuredLocations'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      selectedSalesChannels:
          (json['selectedSalesChannels'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toSet() ??
          const {},
      paymentTerms: json['paymentTerms'] as String?,
      inventoryStartMethod: json['inventoryStartMethod'] as String?,
      inventorySetupStatus: setupStatus,
      savedTeamInvites:
          (json['savedTeamInvites'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}
