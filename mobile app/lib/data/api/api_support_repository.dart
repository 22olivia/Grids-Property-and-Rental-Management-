import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

/// Support API — maps GPMS support/tickets endpoints.
class ApiSupportRepository implements SupportRepository {
  ApiSupportRepository(this._client);

  final ApiClient _client;

  Future<List<SupportTicket>> recentTickets() async {
    try {
      final json = await _client.get('/support/tickets', query: {'per_page': '20'});
      final items = json['data'] as List? ?? [];
      return items.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// GET /support/tickets/{id} — throws ApiException on failure (404,
  /// network, etc.) since there's no sensible single-ticket mock fallback;
  /// callers should wrap this in their own try/catch and show a retry/error
  /// state.
  Future<SupportTicket> ticket(String id) async {
    final json = await _client.get('/support/tickets/$id');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return _fromApi(data);
  }

  Future<List<FaqItem>> faqs() async {
    // GPMS doesn't have a dedicated FAQ endpoint; return empty for now.
    return [];
  }

  Future<List<SupportCategory>> categories() async {
    // Static categories — same as mock data.
    return const [];
  }

  SupportTicket _fromApi(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      title: json['subject'] as String? ?? json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      category: json['category'] as String? ?? 'General',
      priority: json['priority'] as String? ?? 'Medium',
      createdAt: json['created_at'] as String? ?? '',
      description: json['description'] as String? ?? '',
      messages: (json['messages'] as List?)
              ?.map((m) => TicketMessage(
                    author: m['sender_name'] as String? ?? m['author'] as String? ?? '',
                    role: m['sender_role'] as String? ?? 'user',
                    body: m['body'] as String? ?? m['message'] as String? ?? '',
                    timestamp: m['created_at'] as String? ?? '',
                    fromAgent: (m['sender_role'] as String?) == 'agent',
                  ))
              .toList() ??
          [],
    );
  }
}
