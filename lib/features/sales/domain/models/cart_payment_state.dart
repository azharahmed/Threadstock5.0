enum PaymentMode {
  single,
  split,
}

class PaymentAllocation {
  final String method; // 'cash', 'card', 'upi', 'bank_transfer', 'other'
  final int amountMinor; // in paise
  final String? reference;

  const PaymentAllocation({
    required this.method,
    required this.amountMinor,
    this.reference,
  });

  String get group => method.toLowerCase() == 'cash' ? 'Cash' : 'Online';

  double get amount => amountMinor / 100.0;

  String get displayName {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'other':
        return 'Other';
      default:
        return method.toUpperCase();
    }
  }

  PaymentAllocation copyWith({
    String? method,
    int? amountMinor,
    String? reference,
  }) {
    return PaymentAllocation(
      method: method ?? this.method,
      amountMinor: amountMinor ?? this.amountMinor,
      reference: reference ?? this.reference,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_method': method,
    'amount_minor': amountMinor,
    if (reference != null && reference!.isNotEmpty) 'reference_number': reference,
  };

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) => PaymentAllocation(
    method: json['payment_method'] as String? ?? json['method'] as String? ?? 'cash',
    amountMinor: (json['amount_minor'] as num?)?.toInt() ??
        (json['amountMinor'] as num?)?.toInt() ??
        0,
    reference: json['reference_number'] as String? ?? json['reference'] as String?,
  );
}

class CartPaymentState {
  final PaymentMode mode;
  final String singleMethod; // default 'cash', or 'card', 'upi', etc.
  final String? singleReference;
  final List<PaymentAllocation> allocations;
  final bool isConfirmed;
  final int? confirmedTotalMinor;

  const CartPaymentState({
    this.mode = PaymentMode.single,
    this.singleMethod = 'cash',
    this.singleReference,
    this.allocations = const [],
    this.isConfirmed = false,
    this.confirmedTotalMinor,
  });

  int get totalAllocatedMinor {
    if (mode == PaymentMode.single) {
      return 0;
    }
    return allocations.fold(0, (sum, a) => sum + a.amountMinor);
  }

  double get totalAllocated => totalAllocatedMinor / 100.0;

  /// Whether the split is valid and fully allocated to match targetTotalMinor
  bool isValidForTotal(int targetTotalMinor) {
    if (mode != PaymentMode.split) return true;
    return isConfirmed &&
        totalAllocatedMinor == targetTotalMinor &&
        allocations.isNotEmpty &&
        allocations.every((a) => a.amountMinor > 0);
  }

  /// Whether the cart total changed after split was confirmed
  bool isStale(int currentTotalMinor) {
    if (mode != PaymentMode.split || !isConfirmed) return false;
    return totalAllocatedMinor != currentTotalMinor;
  }

  /// Calculates remaining amount needed to reach targetTotalMinor
  int remainingFor(int targetTotalMinor) => targetTotalMinor - totalAllocatedMinor;

  CartPaymentState copyWith({
    PaymentMode? mode,
    String? singleMethod,
    String? singleReference,
    List<PaymentAllocation>? allocations,
    bool? isConfirmed,
    int? confirmedTotalMinor,
  }) {
    return CartPaymentState(
      mode: mode ?? this.mode,
      singleMethod: singleMethod ?? this.singleMethod,
      singleReference: singleReference ?? this.singleReference,
      allocations: allocations ?? this.allocations,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      confirmedTotalMinor: confirmedTotalMinor ?? this.confirmedTotalMinor,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'single_method': singleMethod,
    if (singleReference != null) 'single_reference': singleReference,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'is_confirmed': isConfirmed,
    if (confirmedTotalMinor != null) 'confirmed_total_minor': confirmedTotalMinor,
  };

  factory CartPaymentState.fromJson(Map<String, dynamic> json) {
    return CartPaymentState(
      mode: json['mode'] == 'split' ? PaymentMode.split : PaymentMode.single,
      singleMethod: json['single_method'] as String? ?? 'cash',
      singleReference: json['single_reference'] as String?,
      allocations: (json['allocations'] as List<dynamic>?)
              ?.map((a) => PaymentAllocation.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList() ??
          const [],
      isConfirmed: json['is_confirmed'] == true,
      confirmedTotalMinor: (json['confirmed_total_minor'] as num?)?.toInt(),
    );
  }
}
