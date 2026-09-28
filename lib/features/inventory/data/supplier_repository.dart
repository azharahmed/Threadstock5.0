import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/supplier.dart';

class SupplierRepository {
  final SupabaseClient? client;
  SupplierRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, List<Supplier>> _localFallbackSuppliersByBusiness =
      {};

  static String _generateUuid() {
    final random = math.Random();
    String hex(int len) =>
        List.generate(len, (_) => random.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  Future<String?> resolveCurrentBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    final sb = _resolvedClient;
    if (sb == null) return 'default_business';
    final user = sb.auth.currentUser;
    if (user == null) return 'default_business';

    try {
      final membership = await sb
          .from('memberships')
          .select('business_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      final businessId = membership?['business_id'] as String?;
      if (businessId != null && businessId.isNotEmpty) {
        return businessId;
      }

      final business = await sb
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .limit(1)
          .maybeSingle();

      return business?['id'] as String? ?? 'default_business';
    } catch (e) {
      debugPrint('Error resolving business_id: $e');
      return 'default_business';
    }
  }

  Future<List<Supplier>> getSuppliers({String? businessId}) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;

    if (sb == null || sb.auth.currentUser == null) {
      final existing = _localFallbackSuppliersByBusiness[resolvedBusinessId];
      if (existing != null) return List<Supplier>.from(existing);
      // No seeded mock suppliers. Fresh state returns empty list.
      return const [];
    }

    try {
      final response = await sb
          .from('suppliers')
          .select()
          .eq('business_id', resolvedBusinessId)
          .order('name', ascending: true);

      final remoteList = (response as List)
          .map((row) => Supplier.fromJson(row as Map<String, dynamic>))
          .toList();
      _localFallbackSuppliersByBusiness[resolvedBusinessId] = remoteList;
      return remoteList;
    } catch (e) {
      debugPrint('Error fetching suppliers from Supabase: $e');
      return List<Supplier>.from(
        _localFallbackSuppliersByBusiness[resolvedBusinessId] ?? const [],
      );
    }
  }

  Future<Supplier> createSupplier({
    required String name,
    String? businessId,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a supplier name.');
    }

    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;

    if (sb != null &&
        resolvedBusinessId != 'default_business' &&
        sb.auth.currentUser != null) {
      try {
        final inserted = await sb
            .from('suppliers')
            .insert({
              'business_id': resolvedBusinessId,
              'name': trimmedName,
              if (contactEmail != null && contactEmail.trim().isNotEmpty)
                'contact_email': contactEmail.trim(),
              if (contactPhone != null && contactPhone.trim().isNotEmpty)
                'contact_phone': contactPhone.trim(),
            })
            .select()
            .single();

        final supplier = Supplier.fromJson(inserted);
        final list = _localFallbackSuppliersByBusiness.putIfAbsent(
          resolvedBusinessId,
          () => [],
        );
        list.removeWhere((s) => s.id == supplier.id);
        list.add(supplier);
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return supplier;
      } on PostgrestException catch (pe) {
        final code = pe.code;
        final message = pe.message;
        final details = pe.details?.toString() ?? '';
        debugPrint(
          '[SupplierRepository.createSupplier] PostgrestException: code=$code, message=$message, details=$details',
        );
        if (code == '23505' ||
            message.toLowerCase().contains('unique') ||
            message.toLowerCase().contains('duplicate') ||
            details.toLowerCase().contains('already exists')) {
          throw StateError('A supplier with this name already exists.');
        }
        throw Exception("We couldn't save this supplier. Please try again.");
      } catch (e, st) {
        debugPrint(
          '[SupplierRepository.createSupplier] Unexpected error: $e\n$st',
        );
        if (e is StateError || e is ArgumentError) rethrow;
        throw Exception("We couldn't save this supplier. Please try again.");
      }
    }

    // In-memory fallback: generates genuine UUID format (never 'sup_...')
    final fallbackId = _generateUuid();
    final newSupplier = Supplier(
      id: fallbackId,
      businessId: resolvedBusinessId,
      name: trimmedName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final list = _localFallbackSuppliersByBusiness.putIfAbsent(
      resolvedBusinessId,
      () => [],
    );
    list.removeWhere((s) => s.id == newSupplier.id);
    list.add(newSupplier);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return newSupplier;
  }

  @visibleForTesting
  static void clearLocalState() {
    _localFallbackSuppliersByBusiness.clear();
  }
}
