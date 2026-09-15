import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

enum UserRole { visitor, tenant, owner, maintainer, superAdmin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.visitor => 'Visitor',
        UserRole.tenant => 'Tenant',
        UserRole.owner => 'Owner',
        UserRole.maintainer => 'Maintainer',
        UserRole.superAdmin => 'Super Admin',
      };

  String get blurb => switch (this) {
        UserRole.visitor => 'Browse & discover',
        UserRole.tenant => 'Rent & live',
        UserRole.owner => 'Manage portfolio',
        UserRole.maintainer => 'Service & repair',
        UserRole.superAdmin => 'Platform control',
      };

  IconData get icon => switch (this) {
        UserRole.visitor => Icons.explore_outlined,
        UserRole.tenant => Icons.king_bed_outlined,
        UserRole.owner => Icons.business_center_outlined,
        UserRole.maintainer => Icons.handyman_outlined,
        UserRole.superAdmin => Icons.shield_outlined,
      };
}

// ---------------------------------------------------------------------------
// Property
// ---------------------------------------------------------------------------

enum ListingType { forSale, forRent }

extension ListingTypeX on ListingType {
  String get label =>
      this == ListingType.forSale ? 'FOR SALE' : 'FOR RENT';
}

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.community,
    required this.city,
    required this.priceLabel,
    required this.listingType,
    required this.category,
    required this.imageUrl,
    this.bedrooms,
    this.bathrooms,
    required this.areaSqft,
    this.features = const [],
    this.agency,
    this.featured = false,
    this.description = '',
    this.gallery = const [],
    this.photoCount = 24,
  });

  final String id;
  final String title;
  final String community;
  final String city;
  final String priceLabel;
  final ListingType listingType;
  final String category;
  final String imageUrl;
  final int? bedrooms;
  final int? bathrooms;
  final String areaSqft;
  final List<String> features;
  final String? agency;
  final bool featured;
  final String description;
  final List<GalleryItem> gallery;
  final int photoCount;

  String get location => '$community, $city';
}

class GalleryItem {
  const GalleryItem({
    required this.label,
    required this.url,
    this.isVideo = false,
    this.videoUrl,
  });
  final String label;
  final String url;
  final bool isVideo;

  /// The streamable video URL, used when [isVideo] is true.
  final String? videoUrl;
}

// ---------------------------------------------------------------------------
// Floor plans
// ---------------------------------------------------------------------------

class FloorPlan {
  const FloorPlan({
    required this.name,
    required this.areaSqft,
    required this.rooms,
  });
  final String name;
  final String areaSqft;
  final List<RoomSpec> rooms;
}

class RoomSpec {
  const RoomSpec(this.name, this.dimensions);
  final String name;
  final String dimensions;
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

enum NotificationCategory { property, management, payments, support }

extension NotificationCategoryX on NotificationCategory {
  String get label => switch (this) {
        NotificationCategory.property => 'Property',
        NotificationCategory.management => 'Management',
        NotificationCategory.payments => 'Payments',
        NotificationCategory.support => 'Support',
      };
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.category,
    required this.day,
    this.unread = false,
    this.thumbnailUrl,
    this.badge,
    this.badgeColor,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String time;
  final NotificationCategory category;

  /// "Today" / "Yesterday" grouping key.
  final String day;
  final bool unread;
  final String? thumbnailUrl;
  final String? badge;
  final Color? badgeColor;
  final IconData? icon;
}

// ---------------------------------------------------------------------------
// Support & tickets
// ---------------------------------------------------------------------------

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    this.priority = 'Medium',
    this.createdAt = '',
    this.description = '',
    this.messages = const [],
  });

  final String id;
  final String title;
  final String status;
  final String category;
  final String priority;
  final String createdAt;
  final String description;
  final List<TicketMessage> messages;
}

class TicketMessage {
  const TicketMessage({
    required this.author,
    required this.role,
    required this.body,
    required this.timestamp,
    required this.fromAgent,
  });

  final String author;
  final String role;
  final String body;
  final String timestamp;
  final bool fromAgent;
}

class FaqItem {
  const FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

class SupportCategory {
  const SupportCategory(this.title, this.subtitle, this.icon, this.tint);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
}

// ---------------------------------------------------------------------------
// Work orders (maintainer)
// ---------------------------------------------------------------------------

enum WorkPriority { high, medium, low }

extension WorkPriorityX on WorkPriority {
  String get label => switch (this) {
        WorkPriority.high => 'High',
        WorkPriority.medium => 'Medium',
        WorkPriority.low => 'Low',
      };
}

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.title,
    required this.unit,
    required this.time,
    required this.priority,
    this.status = 'Assigned',
  });

  final String id;
  final String title;
  final String unit;
  final String time;
  final WorkPriority priority;
  final String status;
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.amount,
    required this.unit,
  });
  final String id;
  final String title;
  final String amount;
  final String unit;
}

// ---------------------------------------------------------------------------
// Money / dashboards
// ---------------------------------------------------------------------------

class PaymentRecord {
  const PaymentRecord({
    required this.unit,
    required this.amount,
    required this.date,
  });
  final String unit;
  final String amount;
  final String date;
}

class Inquiry {
  const Inquiry({
    required this.name,
    required this.message,
    required this.time,
    required this.avatarUrl,
  });
  final String name;
  final String message;
  final String time;
  final String avatarUrl;
}

class PropertyPerformance {
  const PropertyPerformance({
    required this.name,
    required this.occupancy,
    required this.rent,
  });
  final String name;
  final int occupancy;
  final String rent;
}

class CommunityRevenue {
  const CommunityRevenue({required this.name, required this.revenue, required this.value});
  final String name;
  final String revenue;
  final double value;
}

class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.time,
    required this.icon,
    required this.tint,
  });
  final String title;
  final String time;
  final IconData icon;
  final Color tint;
}

class PlanSlice {
  const PlanSlice({
    required this.name,
    required this.count,
    required this.percent,
    required this.color,
  });
  final String name;
  final int count;
  final int percent;
  final Color color;
}

// ---------------------------------------------------------------------------
// Subscription plans
// ---------------------------------------------------------------------------

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.recommended = false,
  });

  final String name;
  final String tagline;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<PlanFeature> features;
  final bool recommended;
}

class PlanFeature {
  const PlanFeature(this.label, this.included);
  final String label;
  final bool included;
}

// ---------------------------------------------------------------------------
// Legal / static content
// ---------------------------------------------------------------------------

class LegalSection {
  const LegalSection(this.index, this.title, this.body);
  final int index;
  final String title;
  final String body;
}

// ---------------------------------------------------------------------------
// Tenant
// ---------------------------------------------------------------------------

class LeaseInfo {
  const LeaseInfo({
    required this.property,
    required this.unit,
    required this.period,
    required this.rentAmount,
    required this.dueDate,
    required this.daysRemaining,
    required this.serviceCharge,
  });

  final String property;
  final String unit;
  final String period;
  final String rentAmount;
  final String dueDate;
  final int daysRemaining;
  final String serviceCharge;
}

class Announcement {
  const Announcement({
    required this.title,
    required this.body,
    required this.date,
  });
  final String title;
  final String body;
  final String date;
}

// ---------------------------------------------------------------------------
// Communities (admin)
// ---------------------------------------------------------------------------

class AdminCommunity {
  const AdminCommunity({
    required this.name,
    required this.location,
    required this.properties,
    required this.occupancy,
    required this.revenue,
    required this.status,
    required this.imageUrl,
  });

  final String name;
  final String location;
  final int properties;
  final int occupancy;
  final String revenue;
  final String status;
  final String imageUrl;
}

// ---------------------------------------------------------------------------
// Offices (contact screen)
// ---------------------------------------------------------------------------

class OfficeArea {
  const OfficeArea(this.name, this.branches);
  final String name;
  final int branches;
}

// ---------------------------------------------------------------------------
// Community – Feed comments
// ---------------------------------------------------------------------------

class FeedComment {
  const FeedComment({
    required this.author,
    required this.body,
    required this.time,
    this.avatarUrl,
  });

  final String author;
  final String body;
  final String time;
  final String? avatarUrl;
}

// ---------------------------------------------------------------------------
// Community – Events
// ---------------------------------------------------------------------------

class CommunityEvent {
  const CommunityEvent({
    required this.title,
    required this.schedule,
    required this.place,
    this.description = '',
    this.maxAttendees = 50,
    this.attendees = 0,
  });

  final String title;
  final String schedule;
  final String place;
  final String description;
  final int maxAttendees;
  final int attendees;
}

// ---------------------------------------------------------------------------
// Community – Facility
// ---------------------------------------------------------------------------

enum FacilityStatus { open, bookable, closed }

class CommunityFacility {
  const CommunityFacility({
    required this.name,
    required this.status,
    required this.icon,
    required this.color,
    this.hours = '',
    this.availableSlots = 0,
  });

  final String name;
  final FacilityStatus status;
  final IconData icon;
  final Color color;
  final String hours;
  final int availableSlots;
}

// ---------------------------------------------------------------------------
// Community – Neighbour messages
// ---------------------------------------------------------------------------

class NeighbourMessage {
  const NeighbourMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  final String text;
  final bool isUser;
  final DateTime time;
}
