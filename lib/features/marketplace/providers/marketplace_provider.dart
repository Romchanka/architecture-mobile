import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/marketplace_models.dart';

/// Combined init data — companies + complexes in one request
class MarketplaceInitData {
  final List<Company> companies;
  final Map<int, List<Complex>> complexesByCompany;

  MarketplaceInitData({required this.companies, required this.complexesByCompany});
}

final marketplaceInitProvider = FutureProvider<MarketplaceInitData>((ref) async {
  ref.keepAlive();
  final res = await api.get('/marketplace/init');
  final data = res.data as Map<String, dynamic>;

  final companies = (data['companies'] as List)
      .map((e) => Company.fromJson(e as Map<String, dynamic>))
      .toList();

  final complexesMap = <int, List<Complex>>{};
  final rawMap = data['complexesByCompany'] as Map<String, dynamic>;
  rawMap.forEach((key, value) {
    complexesMap[int.parse(key)] = (value as List)
        .map((e) => Complex.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  return MarketplaceInitData(companies: companies, complexesByCompany: complexesMap);
});

// Backwards-compatible: companies derived from init
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final init = await ref.watch(marketplaceInitProvider.future);
  return init.companies;
});

// Backwards-compatible: complexes derived from init
final complexesProvider = FutureProvider.family<List<Complex>, int>((ref, companyId) async {
  final init = await ref.watch(marketplaceInitProvider.future);
  return init.complexesByCompany[companyId] ?? [];
});

// Buildings by company
final buildingsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, companyId) async {
  ref.keepAlive();
  final res = await api.get('/marketplace/buildings', queryParameters: {'companyId': companyId});
  return (res.data as List).cast<Map<String, dynamic>>();
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
  ref.keepAlive();

  final baseParams = <String, dynamic>{
    'companyId': filter.companyId,
    'status': 'ALL',
    'size': 1000, // load all apartments in one request (Beles has 606)
  };
  if (filter.complexId != null) baseParams['complexId'] = filter.complexId;
  if (filter.rooms != null) baseParams['rooms'] = filter.rooms;
  if (filter.minPrice != null) baseParams['minPrice'] = filter.minPrice;
  if (filter.maxPrice != null) baseParams['maxPrice'] = filter.maxPrice;

  // Auto-paginate: fetch all pages until we have everything
  final List<Apartment> allApartments = [];
  int page = 0;
  int totalPages = 1;

  while (page < totalPages) {
    final params = {...baseParams, 'page': page};
    final res = await api.get('/marketplace/apartments', queryParameters: params);
    final data = res.data;
    if (data is Map) {
      final List items = data['content'] ?? [];
      allApartments.addAll(items.map((e) => Apartment.fromJson(e)));
      totalPages = data['totalPages'] ?? 1;
    } else if (data is List) {
      allApartments.addAll((data).map((e) => Apartment.fromJson(e)));
      break; // non-paginated response
    }
    page++;
  }

  return allApartments;
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
  await api.post('/marketplace/companies/$companyId/apartments/$apartmentId/book');
}

// Book parking space
Future<void> bookParkingSpace(int companyId, int parkingSpaceId) async {
  await api.post('/marketplace/companies/$companyId/parking-spaces/$parkingSpaceId/book');
}

final parkingSpacesProvider = FutureProvider.family<List<ParkingSpace>, int>((ref, companyId) async {
  ref.keepAlive();
  int page = 0;
  int totalPages = 1;
  List<ParkingSpace> allSpaces = [];
  
  while (page < totalPages) {
    try {
      final res = await api.get('/marketplace/parking-spaces', queryParameters: {
        'companyId': companyId,
        'page': page,
      });
      final data = res.data;
      if (data is Map) {
        final List items = data['content'] ?? [];
        allSpaces.addAll(items.map((e) => ParkingSpace.fromJson(e)));
        totalPages = data['totalPages'] ?? 1;
      } else if (data is List) {
        allSpaces.addAll(data.map((e) => ParkingSpace.fromJson(e)));
      }
    } catch (e) {
      break;
    }
    page++;
  }
  return allSpaces;
});

// Active stories
final activeStoriesProvider = FutureProvider.autoDispose<List<Story>>((ref) async {
  try {
    final res = await api.get('/stories/active');
    final data = res.data;
    if (data is List) {
      return data.map((e) => Story.fromJson(e)).toList();
    }
  } catch (e) {
    // Ignore errors for stories
  }
  return [];
});
