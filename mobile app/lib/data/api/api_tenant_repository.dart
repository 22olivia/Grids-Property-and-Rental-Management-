import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Tenant API — maps GPMS /tenants, /leases endpoints.
class ApiTenantRepository implements TenantRepository {
  ApiTenantRepository(this._client);

  final ApiClient _client;

  Future<LeaseInfo> lease() async {
    try {
      final json = await _client.get('/leases', query: {'per_page': '1'});
      final items = json['data'] as List? ?? [];
      if (items.isEmpty) return _emptyLease();
      return _fromApi(items.first as Map<String, dynamic>);
    } catch (_) {
      return _emptyLease();
    }
  }

  Future<List<Announcement>> announcements() async {
    // GPMS doesn't have a dedicated announcements endpoint.
    return [];
  }

  LeaseInfo _fromApi(Map<String, dynamic> json) {
    return LeaseInfo(
      property: json['property_name'] as String? ?? json['property'] as String? ?? '',
      unit: json['unit_number'] as String? ?? json['unit'] as String? ?? '',
      period: '${json['start_date'] ?? ''} – ${json['end_date'] ?? ''}',
      rentAmount: _formatMoney(json['rent_amount']),
      dueDate: json['due_date'] as String? ?? '',
      daysRemaining: json['days_remaining'] as int? ?? 0,
      serviceCharge: _formatMoney(json['service_charge']),
    );
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return 'AED 0';
    return 'AED $amount';
  }

  LeaseInfo _emptyLease() => const LeaseInfo(
        property: '',
        unit: '',
        period: '',
        rentAmount: '',
        dueDate: '',
        daysRemaining: 0,
        serviceCharge: '',
      );
}
