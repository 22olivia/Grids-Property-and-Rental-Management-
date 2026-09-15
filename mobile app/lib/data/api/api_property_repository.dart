import '../../data/models/models.dart';
import '../mock/mock_repositories.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Property API.
///
/// IMPORTANT — domain mismatch with the GPMS backend:
/// GPMS's `/properties` endpoint returns *buildings* (address, unit counts —
/// no price, no bedrooms, no photos). The rentable listings this screen
/// actually needs — price, bedrooms/bathrooms, photos, amenities — live on
/// `RentalUnit`, exposed via:
///   - `GET /listings`            — public, no auth, but a reduced field set
///     (no images/amenities/featured flag; GPMS has no media-upload concept).
///   - `GET /rental-units` (+ id) — authenticated, full fields incl.
///     images/amenities, but requires a signed-in user.
/// There is also no "for sale" concept in GPMS — it's rental-only, so
/// `listingType` is always mapped to [ListingType.forRent].
///
/// This repository prefers `/rental-units` when a session token is present
/// (richer data) and falls back to the public `/listings` endpoint
/// otherwise. Every method also falls back to mock data on any failure so a
/// backend gap never crashes a screen — same pattern as the rest of the
/// Api*Repository classes.
class ApiPropertyRepository implements PropertyRepository {
  ApiPropertyRepository(this._client);

  final ApiClient _client;
  final _mock = MockPropertyRepository();

  bool get _authenticated => _client.token != null;

  @override
  Future<List<Property>> featured() async {
    try {
      final json = _authenticated
          ? await _client.get('/rental-units', query: {'per_page': '20', 'listed_only': 'true'})
          : await _client.get('/listings');
      final items = (json['data'] as List? ?? []);
      final mapped = items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
      if (mapped.isEmpty) return _mock.featured();
      return mapped;
    } catch (_) {
      return _mock.featured();
    }
  }

  @override
  Future<List<Property>> search({
    String query = '',
    String? category,
    int? tabIndex,
    String? sort,
  }) async {
    try {
      Map<String, dynamic> json;
      if (_authenticated) {
        final params = <String, String>{'per_page': '20', 'listed_only': 'true'};
        json = await _client.get('/rental-units', query: params);
      } else {
        // The public /listings endpoint has no query params — filter client-side.
        json = await _client.get('/listings');
      }
      var items = (json['data'] as List? ?? [])
          .map((e) => _fromApi(e as Map<String, dynamic>))
          .toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        items = items
            .where((p) =>
                p.title.toLowerCase().contains(q) ||
                p.community.toLowerCase().contains(q) ||
                p.city.toLowerCase().contains(q))
            .toList();
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        items = items.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
      }
      if (items.isEmpty) {
        return _mock.search(query: query, category: category, tabIndex: tabIndex, sort: sort);
      }
      return items;
    } catch (_) {
      return _mock.search(query: query, category: category, tabIndex: tabIndex, sort: sort);
    }
  }

  @override
  Future<Property> byId(String id) async {
    try {
      if (_authenticated) {
        final json = await _client.get('/rental-units/$id');
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return _fromApi(data);
      }
      // No public single-listing endpoint — scan the public list instead.
      final json = await _client.get('/listings');
      final items = (json['data'] as List? ?? []);
      final match = items.cast<Map<String, dynamic>>().firstWhere(
            (e) => e['id']?.toString() == id,
            orElse: () => {},
          );
      if (match.isEmpty) return _mock.byId(id);
      return _fromApi(match);
    } catch (_) {
      return _mock.byId(id);
    }
  }

  /// GPMS has no dedicated floor-plans endpoint for a rental unit.
  @override
  Future<List<FloorPlan>> floorPlans(String propertyId) async {
    return [];
  }

  @override
  Future<int> totalCount() async {
    try {
      final json = _authenticated
          ? await _client.get('/rental-units', query: {'per_page': '1'})
          : await _client.get('/listings');
      if (json.containsKey('total')) return json['total'] as int? ?? 0;
      return (json['data'] as List? ?? []).length;
    } catch (_) {
      return _mock.totalCount();
    }
  }

  /// Maps either a `/listings` item or a `/rental-units` (RentalUnit) item
  /// to the app's Property model. Field names are identical where both
  /// endpoints provide the field; richer fields (images, amenities) are
  /// simply absent on the public /listings payload and default gracefully.
  Property _fromApi(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final images = json['images'] as List?;
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['listing_title'] as String? ??
          json['unit_number'] as String? ??
          property?['name'] as String? ??
          '',
      community: property?['name'] as String? ?? property?['address_line1'] as String? ?? '',
      city: property?['city'] as String? ?? '',
      priceLabel: _formatPrice(json['monthly_rent']),
      // GPMS is rental-only — there is no "for sale" concept in this backend.
      listingType: ListingType.forRent,
      category: json['unit_type'] as String? ?? property?['type'] as String? ?? 'apartment',
      imageUrl: images != null && images.isNotEmpty ? images.first.toString() : '',
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      areaSqft: json['square_feet']?.toString() ?? json['area']?.toString() ?? '0',
      features: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      agency: property?['name'] as String?,
      featured: json['is_listed'] as bool? ?? false,
      description:
          json['listing_description'] as String? ?? json['description'] as String? ?? '',
      photoCount: images?.length ?? 0,
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Price on request';
    return 'AED $price';
  }
}
