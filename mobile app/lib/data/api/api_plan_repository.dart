import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import '../mock/mock_data.dart';
import 'api_client.dart';

/// Plans API — subscription plans.
/// Falls back to mock data when the backend endpoint is unavailable.
class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<SubscriptionPlan>> plans() async {
    try {
      final json = await _client.get('/plans');
      final list = json['plans'] as List?;
      if (list != null && list.isNotEmpty) {
        return list
            .map((e) => SubscriptionPlan(
                  name: e['name'] as String? ?? '',
                  tagline: e['tagline'] as String? ?? '',
                  monthlyPrice: (e['monthly_price'] as num?)?.toInt() ?? 0,
                  yearlyPrice: (e['yearly_price'] as num?)?.toInt() ?? 0,
                  features: (e['features'] as List?)
                          ?.map((f) => PlanFeature(
                                f['label'] as String? ?? '',
                                f['included'] as bool? ?? false,
                              ))
                          .toList() ??
                      [],
                  recommended: e['recommended'] as bool? ?? false,
                ))
            .toList();
      }
    } catch (_) {}
    return MockData.plans;
  }
}
