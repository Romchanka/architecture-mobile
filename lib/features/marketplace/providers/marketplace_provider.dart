import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/marketplace_models.dart';

// Companies
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final res = await api.get('/marketplace/companies');
  return (res.data as List).map((e) => Company.fromJson(e)).toList();
});

// Complexes by company
final complexesProvider = FutureProvider.family<List<Complex>, int>((ref, companyId) async {
  final res = await api.get('/marketplace/complexes', queryParameters: {'companyId': companyId});
  return (res.data as List).map((e) => Complex.fromJson(e)).toList();
});

// Apartments by company (with optional filters)
class ApartmentFilter {
  final int companyId;
  final int? complexId;
  final int? rooms;
  final double? minPrice;
  final double? maxPrice;

  ApartmentFilter({required this.companyId, this.complexId, this.rooms, this.minPrice, this.maxPrice});

  @override
  bool operator ==(Object other) =>
      other is ApartmentFilter && companyId == other.companyId && complexId == other.complexId &&
          rooms == other.rooms && minPrice == other.minPrice && maxPrice == other.maxPrice;

  @override
  int get hashCode => Object.hash(companyId, complexId, rooms, minPrice, maxPrice);
}

final apartmentsProvider = FutureProvider.family<List<Apartment>, ApartmentFilter>((ref, filter) async {
  final params = <String, dynamic>{
    'companyId': filter.companyId,
    'size': 100,
  };
  if (filter.complexId != null) params['complexId'] = filter.complexId;
  if (filter.rooms != null) params['rooms'] = filter.rooms;
  if (filter.minPrice != null) params['minPrice'] = filter.minPrice;
  if (filter.maxPrice != null) params['maxPrice'] = filter.maxPrice;

  final res = await api.get('/marketplace/apartments', queryParameters: params);
  final data = res.data;
  List items = data is Map ? (data['content'] ?? []) : data;
  return items.map((e) => Apartment.fromJson(e)).toList();
});

// Single apartment detail
class ApartmentDetailParams {
  final int id;
  final int companyId;
  ApartmentDetailParams(this.id, this.companyId);

  @override
  bool operator ==(Object other) => other is ApartmentDetailParams && id == other.id && companyId == other.companyId;
  @override
  int get hashCode => Object.hash(id, companyId);
}

final apartmentDetailProvider = FutureProvider.family<Apartment, ApartmentDetailParams>((ref, p) async {
  final res = await api.get('/marketplace/apartments/${p.id}', queryParameters: {'companyId': p.companyId});
  return Apartment.fromJson(res.data);
});

// Bookings
final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  try {
    final res = await api.get('/profile/bookings');
    final data = res.data;
    // Supports both paginated (content) and plain list response
    final list = data is Map ? (data['content'] ?? []) : (data is List ? data : []);
    return (list as List).map((e) => Booking.fromJson(e)).toList();
  } catch (_) {
    // 403 для консультантов — у них нет профиля покупателя
    return [];
  }
});

// Book apartment
Future<void> bookApartment(int companyId, int apartmentId) async {
  await api.post('/marketplace/book', queryParameters: {
    'companyId': companyId,
    'apartmentId': apartmentId,
  });
}
