import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_data.dart';

/// Small artificial latency so loading/skeleton states are exercised the same
/// way they will be against a real API.
const _latency = Duration(milliseconds: 220);

Future<T> _serve<T>(T value) => Future.delayed(_latency, () => value);

class MockPropertyRepository implements PropertyRepository {
  @override
  Future<List<Property>> featured() => _serve(MockData.allProperties);

  @override
  Future<List<Property>> search({
    String query = '',
    String? category,
    int? tabIndex,
    String? sort,
  }) {
    var results = MockData.allProperties;

    if (category != null && category != 'All') {
      results = results.where((p) => p.category == category).toList();
    }

    if (tabIndex == 0) {
      results = results.where((p) => p.listingType == ListingType.forSale).toList();
    } else if (tabIndex == 1) {
      results = results.where((p) => p.listingType == ListingType.forRent).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.community.toLowerCase().contains(q) ||
              p.city.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    if (sort != null) {
      switch (sort) {
        case 'Price: Low to High':
          results.sort((a, b) => _parsePrice(a).compareTo(_parsePrice(b)));
        case 'Price: High to Low':
          results.sort((a, b) => _parsePrice(b).compareTo(_parsePrice(a)));
        case 'Largest Area':
          results.sort((a, b) => _parseArea(b).compareTo(_parseArea(a)));
        // 'Newest' — default order (no re-sort)
      }
    }

    return _serve(results);
  }

  static double _parsePrice(Property p) {
    final digits = p.priceLabel.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }

  static double _parseArea(Property p) {
    final digits = p.areaSqft.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }

  @override
  Future<Property> byId(String id) => _serve(
        MockData.allProperties.firstWhere(
          (p) => p.id == id,
          orElse: () => MockData.luxuryVilla,
        ),
      );

  @override
  Future<List<FloorPlan>> floorPlans(String propertyId) =>
      _serve(MockData.floorPlans);

  @override
  Future<int> totalCount() => _serve(1248);
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> all() => _serve(MockData.notifications);

  @override
  Future<int> unreadCount() =>
      _serve(MockData.notifications.where((n) => n.unread).length);
}

class MockSupportRepository implements SupportRepository {
  @override
  Future<List<SupportTicket>> recentTickets() => _serve(MockData.recentTickets);

  @override
  Future<SupportTicket> ticket(String id) => _serve(MockData.detailedTicket);

  @override
  Future<List<FaqItem>> faqs() => _serve(MockData.faqs);

  @override
  Future<List<SupportCategory>> categories() => _serve(MockData.supportCategories);
}

class MockMaintenanceRepository implements MaintenanceRepository {
  @override
  Future<List<WorkOrder>> todaySchedule() => _serve(MockData.todaySchedule);

  @override
  Future<List<WorkOrder>> assigned() => _serve(MockData.assignedOrders);

  @override
  Future<List<ApprovalRequest>> pendingApprovals() => _serve(MockData.approvals);

  @override
  Future<List<ActivityEntry>> recentActivity() =>
      _serve(MockData.maintenanceActivity);

  @override
  Future<Map<String, int>> areaWorkload() => _serve(MockData.areaWorkload);
}

class MockTenantRepository implements TenantRepository {
  @override
  Future<LeaseInfo> lease() => _serve(MockData.lease);

  @override
  Future<List<Announcement>> announcements() => _serve(MockData.announcements);
}

class MockOwnerRepository implements OwnerRepository {
  @override
  Future<List<double>> incomeSeries() => _serve(MockData.incomeSeries);

  @override
  Future<List<Inquiry>> inquiries() => _serve(MockData.inquiries);

  @override
  Future<List<PaymentRecord>> recentPayments() => _serve(MockData.recentPayments);

  @override
  Future<List<PropertyPerformance>> performance() => _serve(MockData.performance);
}

class MockAdminRepository implements AdminRepository {
  @override
  Future<List<double>> revenueSeries() => _serve(MockData.revenueSeries);

  @override
  Future<List<PlanSlice>> planBreakdown() => _serve(MockData.planBreakdown);

  @override
  Future<List<ActivityEntry>> platformActivity() =>
      _serve(MockData.platformActivity);

  @override
  Future<List<CommunityRevenue>> topCommunities() => _serve(MockData.topCommunities);
}

class MockPlanRepository implements PlanRepository {
  @override
  Future<List<SubscriptionPlan>> plans() => _serve(MockData.plans);
}

class MockContentRepository implements ContentRepository {
  @override
  Future<List<LegalSection>> privacySections() => _serve(MockData.privacySections);

  @override
  Future<List<LegalSection>> termsSections() => _serve(MockData.termsSections);

  @override
  Future<List<OfficeArea>> offices() => _serve(MockData.offices);
}
