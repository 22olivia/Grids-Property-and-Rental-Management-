import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Notification API — maps GPMS /admin/notifications endpoint.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> all() async {
    try {
      final json = await _client.get('/admin/notifications', query: {'per_page': '50'});
      final items = json['data'] as List? ?? [];
      return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadCount() async {
    try {
      final json = await _client.get('/admin/notifications/unread-count');
      return json['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  AppNotification _fromApi(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String? ?? '';
    return AppNotification(
      title: json['title'] as String? ?? '',
      subtitle: json['body'] as String? ?? json['message'] as String? ?? '',
      time: createdAt,
      category: _parseCategory(json['type'] as String?),
      day: createdAt.isNotEmpty ? createdAt.split('T').first : '',
      unread: json['read_at'] == null,
      badge: json['badge'] as String?,
    );
  }

  NotificationCategory _parseCategory(String? type) {
    return switch (type) {
      'payment' || 'invoice' => NotificationCategory.payments,
      'property' || 'lease' => NotificationCategory.property,
      'maintenance' || 'ticket' => NotificationCategory.support,
      _ => NotificationCategory.management,
    };
  }
}
