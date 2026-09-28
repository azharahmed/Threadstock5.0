class StockCount {
  final String id;
  final String businessId;
  final String locationId;
  final String countNumber;
  final String countType; // 'full', 'cycle', 'zone'
  final String status; // 'draft', 'in_progress', 'submitted', 'in_reconciliation', 'completed', 'cancelled'
  final String? notes;
  final String? startedBy;
  final DateTime? startedAt;
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? completedBy;
  final DateTime? completedAt;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? locationName;

  const StockCount({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.countNumber,
    required this.countType,
    required this.status,
    this.notes,
    this.startedBy,
    this.startedAt,
    this.submittedBy,
    this.submittedAt,
    this.completedBy,
    this.completedAt,
    this.cancelledBy,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.locationName,
  });

  factory StockCount.fromJson(Map<String, dynamic> json) {
    String? locName;
    if (json['stock_locations'] is Map) {
      locName = (json['stock_locations'] as Map<String, dynamic>)['name'] as String?;
    }

    return StockCount(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      locationId: json['location_id'] as String,
      countNumber: json['count_number'] as String,
      countType: json['count_type'] as String? ?? 'full',
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      startedBy: json['started_by'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      submittedBy: json['submitted_by'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      locationName: locName,
    );
  }

  bool get isInProgress => status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
