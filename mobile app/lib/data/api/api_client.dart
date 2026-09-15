import 'dart:convert';

import 'package:http/http.dart' as http;

/// GPMS API client — matched to the Laravel 13 + Sanctum backend.
///
/// - Base URL: GPMS_API_BASE_URL (default http://127.0.0.1:8000/api/v1)
/// - Auth: Bearer token via Authorization header
/// - Pagination: Laravel page-based (data, total, current_page, per_page)
/// - Money: decimal strings ("1500.00")
/// - Dates: UTC ISO-8601
/// - Errors: { message, errors: { field: [msg] } }
class ApiClient {
  ApiClient({required this.baseUrl, this.timeout = const Duration(seconds: 15)});

  final String baseUrl;
  final Duration timeout;

  String? _token;

  void setToken(String? token) => _token = token;

  String? get token => _token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$base$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Raw GET request — returns decoded JSON.
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final response = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(timeout);
    return _handleResponse(response);
  }

  /// Raw POST request — returns decoded JSON.
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .post(
          _uri(path),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  /// Raw PUT request — returns decoded JSON.
  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .put(
          _uri(path),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  /// Raw DELETE request — returns decoded JSON.
  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _headers)
        .timeout(timeout);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] as String? ?? 'Request failed',
      errors: (body['errors'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).cast<String>()),
          ) ??
          {},
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, List<String>> errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const {},
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Laravel paginator response shape.
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int currentPage;
  final int perPage;
  final int lastPage;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.perPage,
    required this.lastPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List? ?? [])
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }
}
