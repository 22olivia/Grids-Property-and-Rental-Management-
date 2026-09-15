import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Owner API — maps GPMS /owners, /payments, /properties endpoints.
class ApiOwnerRepository implements OwnerRepository {
  ApiOwnerRepository(this._client);

  final ApiClient _client;

  Future<List<double>> incomeSeries() async {
    // Try dashboard endpoint for monthly income data.
    try {
      final json = await _client.get('/dashboard');
      final monthly = json['monthly_income'] as List?;
      if (monthly != null) {
        return monthly.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}
    return List.filled(12, 0.0);
  }

  Future<List<Inquiry>> inquiries() async {
    // GPMS doesn't have a dedicated inquiries endpoint for owners.
    return [];
  }

  Future<List<PaymentRecord>> recentPayments() async {
    try {
      final json = await _client.get('/payments', query: {'per_page': '10'});
      final items = json['data'] as List? ?? [];
      return items.map((e) => _paymentFromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PropertyPerformance>> performance() async {
    try {
      final json = await _client.get('/properties', query: {'per_page': '10'});
      final items = json['data'] as List? ?? [];
      return items.map((e) => _perfFromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  PaymentRecord _paymentFromApi(Map<String, dynamic> json) {
    return PaymentRecord(
      unit: json['unit_number'] as String? ?? json['unit'] as String? ?? '',
      amount: 'AED ${json['amount'] ?? 0}',
      date: json['payment_date'] as String? ?? json['created_at'] as String? ?? '',
    );
  }

  PropertyPerformance _perfFromApi(Map<String, dynamic> json) {
    return PropertyPerformance(
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      occupancy: json['occupancy_rate'] as int? ?? 0,
      rent: 'AED ${json['rent_amount'] ?? 0}',
    );
  }
}
