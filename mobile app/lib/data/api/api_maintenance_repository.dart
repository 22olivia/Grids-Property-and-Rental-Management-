import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Maintenance API — maps GPMS /maintenance-requests endpoint.
class ApiMaintenanceRepository implements MaintenanceRepository {
  ApiMaintenanceRepository(this._client);

  final ApiClient _client;

  Future<List<WorkOrder>> todaySchedule() async {
    try {
      final json = await _client.get('/maintenance-requests', query: {
        'per_page': '10',
        'status': 'in_progress',
      });
      final items = json['data'] as List? ?? [];
      return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WorkOrder>> assigned() async {
    try {
      final json = await _client.get('/maintenance-requests', query: {
        'per_page': '20',
        'status': 'pending',
      });
      final items = json['data'] as List? ?? [];
      return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalRequest>> pendingApprovals() async {
    // GPMS doesn't have a dedicated approvals endpoint; return empty.
    return [];
  }

  Future<List<ActivityEntry>> recentActivity() async {
    return [];
  }

  Future<Map<String, int>> areaWorkload() async {
    return {};
  }

  WorkOrder _fromApi(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id']?.toString() ?? '',
      title: json['subject'] as String? ?? json['title'] as String? ?? '',
      unit: json['unit'] as String? ?? json['unit_number'] as String? ?? '',
      time: json['created_at'] as String? ?? '',
      priority: _parsePriority(json['priority'] as String?),
      status: json['status'] as String? ?? 'Assigned',
    );
  }

  WorkPriority _parsePriority(String? p) {
    return switch (p?.toLowerCase()) {
      'high' || 'urgent' => WorkPriority.high,
      'low' => WorkPriority.low,
      _ => WorkPriority.medium,
    };
  }
}
