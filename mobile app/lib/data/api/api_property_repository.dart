import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Property API — maps GPMS /properties endpoint to the app's Property model.
class ApiPropertyRepository implements PropertyRepository {
  ApiPropertyRepository(this._client);

  final ApiClient _client;

  /// GET /properties — returns paginated properties.
  Future<List<Property>> featured() async {
    final json = await _client.get('/properties', query: {'per_page': '20'});
    final items = json['data'] as List? ?? [];
    return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
  }

  /// GET /properties with query/search params.
  Future<List<Property>> search({
    String query = '',
    String? category,
    int? tabIndex,
    String? sort,
  }) async {
    final params = <String, String>{'per_page': '20'};
    if (query.isNotEmpty) params['search'] = query;
    if (category != null && category.isNotEmpty) params['type'] = category;
    if (sort != null && sort != 'Newest') params['sort'] = sort;
    final json = await _client.get('/properties', query: params);
    final items = json['data'] as List? ?? [];
    return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
  }

  /// GET /properties/{id}
  Future<Property> byId(String id) async {
    final json = await _client.get('/properties/$id');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return _fromApi(data);
  }

  /// Floor plans come from the property detail or building floors.
  Future<List<FloorPlan>> floorPlans(String propertyId) async {
    // The GPMS backend doesn't have a dedicated floor-plans endpoint.
    // Try /properties/{id}/floors or return empty.
    try {
      final json = await _client.get('/properties/$propertyId/floors');
      final items = json['data'] as List? ?? [];
      return items.map((e) => _floorPlanFromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> totalCount() async {
    final json = await _client.get('/properties', query: {'per_page': '1'});
    return json['total'] as int? ?? 0;
  }

  /// Map a GPMS property JSON to the app's Property model.
  Property _fromApi(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      community: json['community'] as String? ?? json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      priceLabel: _formatPrice(json['rent_amount'] ?? json['price']),
      listingType: (json['status'] as String?) == 'for_sale'
          ? ListingType.forSale
          : ListingType.forRent,
      category: json['type'] as String? ?? 'apartment',
      imageUrl: (json['media'] as List?)?.isNotEmpty == true
          ? (json['media'] as List).first['url'] as String? ?? ''
          : '',
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      areaSqft: json['area']?.toString() ?? json['size']?.toString() ?? '0',
      features: (json['amenities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      agency: json['organization']?['name'] as String?,
      featured: json['is_featured'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      photoCount: json['media_count'] as int? ??
          (json['media'] as List?)?.length ??
          0,
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Price on request';
    if (price is String) return 'AED $price';
    return 'AED ${price.toString()}';
  }

  FloorPlan _floorPlanFromApi(Map<String, dynamic> json) {
    return FloorPlan(
      name: json['name'] as String? ?? 'Floor ${json['floor_number'] ?? ''}',
      areaSqft: json['area']?.toString() ?? '0',
      rooms: (json['units'] as List?)
              ?.map((u) => RoomSpec(
                    u['name'] as String? ?? u['unit_number'] as String? ?? '',
                    u['area']?.toString() ?? '',
                  ))
              .toList() ??
          [],
    );
  }
}
