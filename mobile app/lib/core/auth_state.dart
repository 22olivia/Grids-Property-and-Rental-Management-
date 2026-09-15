import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/api_auth_repository.dart';

/// Central auth state — persists the Sanctum token across app restarts.
class AuthState {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? _token;
  ApiUser? _user;

  String? get token => _token;
  ApiUser? get user => _user;
  bool get isLoggedIn => _token != null;

  /// Initialise from local storage on app start.
  Future<void> init(ApiClient client) async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      client.setToken(_token);
      try {
        final user = await ApiAuthRepository(client).me();
        _user = user;
      } catch (_) {
        // Token expired or invalid — clear it.
        _token = null;
        _user = null;
        client.setToken(null);
        await prefs.remove('auth_token');
      }
    }
  }

  /// Store token and user after login.
  Future<void> login(ApiClient client, AuthResult result) async {
    _token = result.token;
    _user = result.user;
    client.setToken(result.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', result.token);
  }

  /// Clear token and user on logout.
  Future<void> logout(ApiClient client) async {
    try {
      await ApiAuthRepository(client).logout();
    } catch (_) {
      // Ignore logout errors.
    }
    _token = null;
    _user = null;
    client.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
