import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Notification API — maps GPMS /notifications endpoint (notification centre).
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> all() async {
    try {
      final json = await _client.get('/notifications', query: {'per_page': '50'});
      final items = json['data'] as List? ?? [];
      return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadCount() async {
    try {
      final json = await _client.get('/notifications/unread-count');
      return json['unread_count'] as int? ?? 0;
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
      category: _parseCategory(json['category'] as String?),
      day: createdAt.isNotEmpty ? createdAt.split('T').first : '',
      unread: json['read_at'] == null,
      badge: json['badge'] as String?,
    );
  }

  NotificationCategory _parseCategory(String? category) {
    return switch (category) {
      'payment' || 'invoice' || 'payments' => NotificationCategory.payments,
      'property' || 'lease' || 'unit' => NotificationCategory.property,
      'maintenance' || 'ticket' || 'support' => NotificationCategory.support,
      _ => NotificationCategory.management,
    };
  }
}
