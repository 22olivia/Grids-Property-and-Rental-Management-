import '../../data/models/models.dart';
import '../repositories/repositories.dart';
import '../mock/mock_data.dart';
import 'api_client.dart';

/// Content API — static legal content and offices.
/// Falls back to mock data when the backend endpoints are unavailable.
class ApiContentRepository implements ContentRepository {
  ApiContentRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<LegalSection>> privacySections() async {
    try {
      final json = await _client.get('/content/privacy');
      final list = json['sections'] as List?;
      if (list != null && list.isNotEmpty) {
        return list
            .map((e) => LegalSection(
                  (e['index'] as num?)?.toInt() ?? 0,
                  e['title'] as String? ?? '',
                  e['body'] as String? ?? '',
                ))
            .toList();
      }
    } catch (_) {}
    return MockData.privacySections;
  }

  @override
  Future<List<LegalSection>> termsSections() async {
    try {
      final json = await _client.get('/content/terms');
      final list = json['sections'] as List?;
      if (list != null && list.isNotEmpty) {
        return list
            .map((e) => LegalSection(
                  (e['index'] as num?)?.toInt() ?? 0,
                  e['title'] as String? ?? '',
                  e['body'] as String? ?? '',
                ))
            .toList();
      }
    } catch (_) {}
    return MockData.termsSections;
  }

  @override
  Future<List<OfficeArea>> offices() async {
    try {
      final json = await _client.get('/content/offices');
      final list = json['offices'] as List?;
      if (list != null && list.isNotEmpty) {
        return list
            .map((e) => OfficeArea(
                  e['name'] as String? ?? '',
                  (e['branches'] as num?)?.toInt() ?? 0,
                ))
            .toList();
      }
    } catch (_) {}
    return MockData.offices;
  }
}
