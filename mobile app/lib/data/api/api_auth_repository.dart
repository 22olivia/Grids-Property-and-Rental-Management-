import 'api_client.dart';

/// Auth API — login, logout, me, forgot/reset/change password.
class ApiAuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  /// POST /login — returns { token, user }
  Future<AuthResult> login(String email, String password) async {
    final json = await _client.post('/login', body: {
      'email': email,
      'password': password,
    });
    final token = json['token'] as String?;
    if (token == null) throw ApiException(statusCode: 401, message: 'No token returned');
    _client.setToken(token);
    final user = _parseUser(json['user'] as Map<String, dynamic>? ?? {});
    return AuthResult(token: token, user: user);
  }

  /// POST /logout
  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } finally {
      _client.setToken(null);
    }
  }

  /// GET /me — returns current user (GPMS wraps it as { user: {...} }).
  Future<ApiUser> me() async {
    final json = await _client.get('/me');
    return _parseUser(json['user'] as Map<String, dynamic>? ?? json);
  }

  /// POST /forgot-password
  Future<void> forgotPassword(String email) async {
    await _client.post('/forgot-password', body: {'email': email});
  }

  /// POST /reset-password
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post('/reset-password', body: {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  /// POST /change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _client.post('/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }

  /// GET /me — same endpoint as [me]; GPMS has no separate GET /profile
  /// route (only PUT /profile for updates), so this is kept as an alias
  /// for callers that expect a getProfile() method.
  Future<ApiUser> getProfile() => me();

  ApiUser _parseUser(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'visitor',
      organizationId: json['organization_id']?.toString(),
    );
  }
}

class AuthResult {
  final String token;
  final ApiUser user;

  AuthResult({required this.token, required this.user});
}

class ApiUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? organizationId;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.organizationId,
  });
}
