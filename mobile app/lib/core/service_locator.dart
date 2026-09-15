import '../data/api/api_client.dart';
import '../data/api/api_auth_repository.dart';
import '../data/api/api_property_repository.dart';
import '../data/api/api_notification_repository.dart';
import '../data/api/api_support_repository.dart';
import '../data/api/api_maintenance_repository.dart';
import '../data/api/api_tenant_repository.dart';
import '../data/api/api_owner_repository.dart';
import '../data/api/api_admin_repository.dart';
import '../data/api/api_content_repository.dart';
import '../data/api/api_plan_repository.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories/repositories.dart';
import 'auth_state.dart';

/// The single place where implementations are chosen.
///
/// When the backend is available, `Services.init()` is called at app start
/// with the base URL. All repositories switch to live API implementations.
/// When the backend is unreachable, falls back to in-memory mocks.
class Services {
  Services._();

  static late ApiClient _apiClient;
  static ApiAuthRepository? _authRepo;

  static PropertyRepository properties = MockPropertyRepository();
  static NotificationRepository notifications = MockNotificationRepository();
  static SupportRepository support = MockSupportRepository();
  static MaintenanceRepository maintenance = MockMaintenanceRepository();
  static TenantRepository tenant = MockTenantRepository();
  static OwnerRepository owner = MockOwnerRepository();
  static AdminRepository admin = MockAdminRepository();
  static PlanRepository plans = MockPlanRepository();
  static ContentRepository content = MockContentRepository();

  static bool get isMockMode => properties is MockPropertyRepository;

  /// Call once at app start. If the backend is reachable, switches all
  /// repositories to live implementations. If not, stays in mock mode.
  static Future<void> init(String baseUrl) async {
    _apiClient = ApiClient(baseUrl: baseUrl);
    _authRepo = ApiAuthRepository(_apiClient);

    // Try to restore saved token and validate it.
    await AuthState.instance.init(_apiClient);

    // If we have a valid token, switch to live mode.
    if (AuthState.instance.isLoggedIn) {
      _useLiveRepos();
    } else {
      // Even without auth, we can still use live repos for public endpoints.
      // But if the backend isn't reachable, stay in mock mode.
      // Uses /health rather than /properties — /properties is staff-only
      // (super_admin/owner/manager) in GPMS and would 403 for a tenant or
      // an unauthenticated visitor, which previously made the app look
      // "unreachable" and silently stay in mock mode for those users.
      try {
        await _apiClient.get('/health');
        _useLiveRepos();
      } catch (_) {
        // Backend unreachable — stay in mock mode.
      }
    }
  }

  static void _useLiveRepos() {
    properties = ApiPropertyRepository(_apiClient);
    notifications = ApiNotificationRepository(_apiClient);
    support = ApiSupportRepository(_apiClient);
    maintenance = ApiMaintenanceRepository(_apiClient);
    tenant = ApiTenantRepository(_apiClient);
    owner = ApiOwnerRepository(_apiClient);
    admin = ApiAdminRepository(_apiClient);
    content = ApiContentRepository(_apiClient);
    plans = ApiPlanRepository(_apiClient);
  }

  /// Access the auth repository for login/logout.
  static ApiAuthRepository? get auth => _authRepo;

  /// Access the underlying API client.
  static ApiClient get apiClient => _apiClient;
}
