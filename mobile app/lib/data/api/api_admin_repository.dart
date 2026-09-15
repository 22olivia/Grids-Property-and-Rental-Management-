import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import '../mock/mock_data.dart';
import 'api_client.dart';

/// Admin API — maps GPMS /dashboard, /admin/search endpoints.
/// Falls back to mock data when the backend returns empty or unavailable results.
class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<double>> revenueSeries() async {
    try {
      final json = await _client.get('/dashboard');
      final monthly = json['monthly_revenue'] as List?;
      if (monthly != null && monthly.isNotEmpty) {
        return monthly.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}
    return MockData.revenueSeries;
  }

  @override
  Future<List<PlanSlice>> planBreakdown() async {
    try {
      final json = await _client.get('/admin/plans');
      final list = json['plans'] as List?;
      if (list != null && list.isNotEmpty) {
          final colors = MockData.planBreakdown.map((s) => s.color).toList();
        return list.asMap().entries.map((entry) {
          final e = entry.value;
          return PlanSlice(
            name: e['name'] as String? ?? '',
            count: (e['count'] as num?)?.toInt() ?? 0,
            percent: (e['percent'] as num?)?.toInt() ?? 0,
            color: colors[entry.key % colors.length],
          );
        }).toList();
      }
    } catch (_) {}
    return MockData.planBreakdown;
  }

  @override
  Future<List<ActivityEntry>> platformActivity() async {
    try {
      final json = await _client.get('/admin/activity');
      final list = json['activity'] as List?;
      if (list != null && list.isNotEmpty) {
        const fallback = MockData.platformActivity;
        return list.asMap().entries.map((entry) {
          final e = entry.value;
          final fb = fallback[entry.key % fallback.length];
          return ActivityEntry(
            title: e['title'] as String? ?? fb.title,
            time: e['time'] as String? ?? fb.time,
            icon: fb.icon,
            tint: fb.tint,
          );
        }).toList();
      }
    } catch (_) {}
    return MockData.platformActivity;
  }

  @override
  Future<List<CommunityRevenue>> topCommunities() async {
    try {
      final json = await _client.get('/admin/communities');
      final list = json['communities'] as List?;
      if (list != null && list.isNotEmpty) {
        return list
            .map((e) => CommunityRevenue(
                  name: e['name'] as String? ?? '',
                  revenue: e['revenue'] as String? ?? '',
                  value: (e['value'] as num?)?.toDouble() ?? 0.0,
                ))
            .toList();
      }
    } catch (_) {}
    return MockData.topCommunities;
  }
}
