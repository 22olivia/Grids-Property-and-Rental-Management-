import '../models/models.dart';

/// Data contracts for the whole app.
///
/// Screens depend ONLY on these interfaces. Today they are satisfied by the
/// in-memory implementations in `data/mock/`; when the RESIVYN backend exists,
/// add `api/` implementations of the same interfaces and swap them in
/// `core/service_locator.dart`. No screen code has to change.

abstract class PropertyRepository {
  Future<List<Property>> featured();
  Future<List<Property>> search({String query, String? category, int? tabIndex, String? sort});
  Future<Property> byId(String id);
  Future<List<FloorPlan>> floorPlans(String propertyId);
  Future<int> totalCount();
}

abstract class NotificationRepository {
  Future<List<AppNotification>> all();
  Future<int> unreadCount();
}

abstract class SupportRepository {
  Future<List<SupportTicket>> recentTickets();
  Future<SupportTicket> ticket(String id);
  Future<List<FaqItem>> faqs();
  Future<List<SupportCategory>> categories();
}

abstract class MaintenanceRepository {
  Future<List<WorkOrder>> todaySchedule();
  Future<List<WorkOrder>> assigned();
  Future<List<ApprovalRequest>> pendingApprovals();
  Future<List<ActivityEntry>> recentActivity();
  Future<Map<String, int>> areaWorkload();
}

abstract class TenantRepository {
  Future<LeaseInfo> lease();
  Future<List<Announcement>> announcements();
}

abstract class OwnerRepository {
  Future<List<double>> incomeSeries();
  Future<List<Inquiry>> inquiries();
  Future<List<PaymentRecord>> recentPayments();
  Future<List<PropertyPerformance>> performance();
}

abstract class AdminRepository {
  Future<List<double>> revenueSeries();
  Future<List<PlanSlice>> planBreakdown();
  Future<List<ActivityEntry>> platformActivity();
  Future<List<CommunityRevenue>> topCommunities();
}

abstract class PlanRepository {
  Future<List<SubscriptionPlan>> plans();
}

abstract class ContentRepository {
  Future<List<LegalSection>> privacySections();
  Future<List<LegalSection>> termsSections();
  Future<List<OfficeArea>> offices();
}
