import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../models/models.dart';

/// Seed content for local testing. Mirrors the RESIVYN spec exactly so the
/// screens can be reviewed with realistic Dubai data and no backend.
class Img {
  Img._();
  static const _u = 'https://images.unsplash.com/photo-';
  static const _q = '?auto=format&fit=crop&w=1200&q=70';
  static const _qs = '?auto=format&fit=crop&w=400&q=70';
  static const _qa = '?auto=format&fit=facearea&facepad=2.5&w=200&h=200&q=70';

  // Properties / exteriors
  static const villaHero = '${_u}1613490493576-7fde63acd811$_q';
  static const villaDusk = '${_u}1600596542815-ffad4c1539a9$_q';
  static const villaExterior = '${_u}1512917774080-9991f1c4c750$_q';
  static const marinaApartment = '${_u}1582672060674-bc2bd808a8b5$_q';
  static const officeSpace = '${_u}1497366216548-37526070297c$_q';
  static const dubaiSkyline = '${_u}1518684079-3c830dcef090$_q';
  static const dubaiWaterfront = '${_u}1512453979798-5ea266f8880c$_q';

  // Interiors
  static const livingRoom = '${_u}1600607687939-ce8a6c25118c$_q';
  static const bedroom = '${_u}1600566753190-17f0baa2a6c3$_q';
  static const kitchen = '${_u}1600489000022-c2086d79f9d4$_q';
  static const pool = '${_u}1580537659466-0a9bfa916a54$_q';
  static const diningRoom = '${_u}1600210492486-724fe5c67fb0$_q';

  // Thumbnails
  static const thumbMarina = '${_u}1582672060674-bc2bd808a8b5$_qs';
  static const thumbVilla = '${_u}1613490493576-7fde63acd811$_qs';
  static const thumbSkyline = '${_u}1518684079-3c830dcef090$_qs';

  // People
  static const avatarAlex = '${_u}1560250097-0b93528c311a$_qa';
  static const avatarSam = '${_u}1519345182560-3f2917c472ef$_qa';
  static const avatarMichael = '${_u}1500648767791-00dcc994a43e$_qa';
  static const avatarSara = '${_u}1573497019940-1c28c88b4f3e$_qa';
  static const avatarJulia = '${_u}1494790108377-be9c29b29330$_qa';
  static const avatarAisha = '${_u}1438761681033-6461ffad8d80$_qa';
}

class MockData {
  MockData._();

  // ---- Properties -------------------------------------------------------

  /// Named separately so other const Property literals can reference it.
  static const villaDescription =
      'Experience elevated living in this exceptional 5-bedroom villa located '
      'on the iconic Palm Jumeirah. Designed with elegance and crafted for '
      'comfort, this residence offers panoramic views, premium finishes, and '
      'world-class amenities.';

  static const luxuryVilla = Property(
    id: 'RV-9842',
    title: 'Luxury Villa',
    community: 'Palm Jumeirah',
    city: 'Dubai',
    priceLabel: 'AED 8,200,000',
    listingType: ListingType.forSale,
    category: 'Villa',
    imageUrl: Img.villaHero,
    bedrooms: 5,
    bathrooms: 6,
    areaSqft: '7,280 sqft',
    features: ['Beach Access', 'Private Pool', 'Wine Cellar'],
    agency: 'Resivyn Real Estate',
    featured: true,
    photoCount: 24,
    description: villaDescription,
    gallery: [
      GalleryItem(label: 'Exterior Villa', url: Img.villaHero),
      GalleryItem(label: 'Living Room', url: Img.livingRoom),
      GalleryItem(label: 'Master Bedroom', url: Img.bedroom),
      GalleryItem(label: 'Kitchen', url: Img.kitchen),
      GalleryItem(label: 'Infinity Pool', url: Img.pool),
      GalleryItem(label: 'Dining Room', url: Img.diningRoom),
    ],
  );

  static const marinaApartment = Property(
    id: 'RV-4471',
    title: 'Marina Apartment',
    community: 'Dubai Marina',
    city: 'Dubai',
    priceLabel: 'AED 120,000 / year',
    listingType: ListingType.forRent,
    category: 'Apartment',
    imageUrl: Img.marinaApartment,
    bedrooms: 2,
    bathrooms: 3,
    areaSqft: '1,340 sqft',
    features: ['Furnished', 'Marina View', 'Balcony'],
    agency: 'Resivyn Real Estate',
    description:
        'A bright 2-bedroom residence overlooking Dubai Marina, fully furnished '
        'with floor-to-ceiling glazing and direct access to the promenade.',
    gallery: [
      GalleryItem(label: 'Marina View', url: Img.marinaApartment),
      GalleryItem(label: 'Living Room', url: Img.livingRoom),
      GalleryItem(label: 'Bedroom', url: Img.bedroom),
      GalleryItem(label: 'Kitchen', url: Img.kitchen),
    ],
  );

  static const primeOffice = Property(
    id: 'RV-2210',
    title: 'Prime Office Space',
    community: 'Business Bay',
    city: 'Dubai',
    priceLabel: 'AED 3,500,000',
    listingType: ListingType.forSale,
    category: 'Office',
    imageUrl: Img.officeSpace,
    areaSqft: '2,450 sqft',
    features: ['Fitted', 'High Floor', '2 Parking'],
    agency: 'Resivyn Commercial',
    description:
        'Fitted high-floor office in Business Bay with panoramic canal views, '
        'ready for immediate occupation.',
    gallery: [
      GalleryItem(label: 'Reception', url: Img.officeSpace),
      GalleryItem(label: 'Open Plan', url: Img.livingRoom),
    ],
  );

  static const allProperties = [luxuryVilla, marinaApartment, primeOffice];

  static const propertyCategories = [
    'All',
    'Apartment',
    'Villa',
    'House',
    'Store',
    'Office',
    'Land',
  ];

  // ---- Floor plans ------------------------------------------------------

  static const floorPlans = [
    FloorPlan(
      name: 'Ground Floor',
      areaSqft: '2,450 sqft',
      rooms: [
        RoomSpec('Living Room', '7.2m x 5.0m'),
        RoomSpec('Dining Room', '4.6m x 4.0m'),
        RoomSpec('Kitchen', '5.0m x 3.6m'),
        RoomSpec('Guest Bedroom', '4.2m x 4.0m'),
        RoomSpec('Ensuite Bathroom', '2.7m x 1.8m'),
        RoomSpec("Maid's Room", '2.6m x 2.2m'),
        RoomSpec('Powder Room', '2.0m x 1.6m'),
        RoomSpec('Terrace', '6.0m x 3.0m'),
      ],
    ),
    FloorPlan(
      name: 'First Floor',
      areaSqft: '2,180 sqft',
      rooms: [
        RoomSpec('Master Bedroom', '6.4m x 5.2m'),
        RoomSpec('Master Ensuite', '3.4m x 2.6m'),
        RoomSpec('Walk-in Wardrobe', '3.0m x 2.4m'),
        RoomSpec('Bedroom 2', '4.6m x 4.2m'),
        RoomSpec('Bedroom 3', '4.4m x 4.0m'),
        RoomSpec('Family Lounge', '5.2m x 4.4m'),
        RoomSpec('Balcony', '5.0m x 2.2m'),
      ],
    ),
    FloorPlan(
      name: 'Roof Terrace',
      areaSqft: '980 sqft',
      rooms: [
        RoomSpec('Sun Deck', '8.0m x 5.0m'),
        RoomSpec('Outdoor Kitchen', '3.6m x 2.4m'),
        RoomSpec('Shaded Majlis', '4.2m x 3.2m'),
        RoomSpec('Plunge Pool', '5.0m x 2.6m'),
      ],
    ),
  ];

  static const areaSummary = {
    'Plot Area': '5,732 sqft',
    'Built-up Area': '5,610 sqft',
    'Indoor Area': '4,630 sqft',
    'Outdoor Area': '980 sqft',
  };

  static const finishesBlurb =
      'Premium finishes with smart home automation, floor-to-ceiling windows, '
      'imported marble flooring, and branded fittings.';

  static const communityHighlights = [
    'Private Beach Access',
    '24/7 Security & Concierge',
    'Infinity Pool & Fitness Center',
    'Landscaped Gardens',
  ];

  // ---- Notifications ----------------------------------------------------

  static const notifications = [
    AppNotification(
      title: 'New inquiry from Sarah Johnson',
      subtitle: 'Interested in Marina Apartment • Dubai Marina',
      time: '10:24 AM',
      category: NotificationCategory.property,
      day: 'Today',
      unread: true,
      thumbnailUrl: Img.thumbMarina,
      icon: Icons.mark_email_unread_outlined,
    ),
    AppNotification(
      title: '5 new matches for your saved search',
      subtitle: 'Waterfront properties in Dubai Marina',
      time: '9:15 AM',
      category: NotificationCategory.property,
      day: 'Today',
      unread: true,
      thumbnailUrl: Img.thumbSkyline,
      icon: Icons.travel_explore_outlined,
    ),
    AppNotification(
      title: 'Price drop alert',
      subtitle: 'Palm Villa • Palm Jumeirah is now AED 7,900,000',
      time: '8:40 AM',
      category: NotificationCategory.property,
      day: 'Today',
      thumbnailUrl: Img.thumbVilla,
      icon: Icons.trending_down,
    ),
    AppNotification(
      title: 'Rent reminder',
      subtitle: 'Marina Apartment • Due on May 1, 2025',
      time: '8:00 AM',
      category: NotificationCategory.payments,
      day: 'Today',
      badge: 'AED 120,000',
      badgeColor: RC.teal,
      icon: Icons.payments_outlined,
    ),
    AppNotification(
      title: 'Maintenance update',
      subtitle: '#MR-4587 • AC repair scheduled for Apr 30',
      time: '6:12 PM',
      category: NotificationCategory.management,
      day: 'Yesterday',
      badge: 'In Progress',
      badgeColor: RC.warning,
      icon: Icons.build_outlined,
    ),
    AppNotification(
      title: 'Community announcement',
      subtitle: 'Pool maintenance on May 2 • 9:00 AM – 1:00 PM',
      time: '4:30 PM',
      category: NotificationCategory.management,
      day: 'Yesterday',
      icon: Icons.campaign_outlined,
    ),
    AppNotification(
      title: 'Support reply from Alex',
      subtitle: 'Re: Issue with clubhouse booking',
      time: '2:05 PM',
      category: NotificationCategory.support,
      day: 'Yesterday',
      icon: Icons.support_agent_outlined,
    ),
    AppNotification(
      title: 'Booking confirmed',
      subtitle: 'Clubhouse • May 3, 2025 • 3:00 PM – 5:00 PM',
      time: '11:48 AM',
      category: NotificationCategory.management,
      day: 'Yesterday',
      badge: 'Confirmed',
      badgeColor: RC.success,
      icon: Icons.event_available_outlined,
    ),
  ];

  // ---- Support ----------------------------------------------------------

  static const supportCategories = [
    SupportCategory(
        'Payments', 'Invoices, billing & refunds', Icons.credit_card_outlined, RC.teal),
    SupportCategory('Leasing', 'Contracts, renewals & leasing support',
        Icons.description_outlined, RC.info),
    SupportCategory('Maintenance', 'Service requests & repairs',
        Icons.handyman_outlined, RC.warning),
    SupportCategory('Technical Help', 'App, account & technical issues',
        Icons.devices_outlined, RC.purple),
    SupportCategory(
        'Legal', 'Policies, compliance & legal support', Icons.gavel_outlined, RC.navy),
  ];

  static const faqs = [
    FaqItem(
      'How do I make a rent payment?',
      'Open the Payments tab, select the outstanding invoice and pay by card, '
          'bank transfer or direct debit. A receipt is issued instantly.',
    ),
    FaqItem(
      'How can I submit a maintenance request?',
      'Go to Support → Create Ticket, choose Maintenance, describe the issue '
          'and attach photos. A maintainer is assigned within 2 hours.',
    ),
    FaqItem(
      'How do I update my personal information?',
      'Profile → Personal Information. Changes to your legal name or Emirates '
          'ID require document verification.',
    ),
    FaqItem(
      'What is the security deposit policy?',
      'Deposits are held for the lease term and refunded within 30 days of '
          'handover, less any documented damages.',
    ),
  ];

  static const recentTickets = [
    SupportTicket(
      id: 'TK-48291',
      title: 'Maintenance Request — AC not cooling',
      status: 'In Progress',
      category: 'Maintenance',
    ),
    SupportTicket(
      id: 'TK-48122',
      title: 'Payment Issue — Refund not received',
      status: 'Resolved',
      category: 'Payments',
    ),
    SupportTicket(
      id: 'TK-47988',
      title: 'Login Issue — Cannot access account',
      status: 'Closed',
      category: 'Technical Help',
    ),
  ];

  static const detailedTicket = SupportTicket(
    id: 'TK-2025-1458',
    title: 'Unable to upload property photos',
    status: 'Open',
    category: 'Technical Support',
    priority: 'Medium',
    createdAt: 'May 31, 2025 • 10:24 AM',
    description:
        'I’m trying to upload photos while adding a new property listing, '
        'but the upload keeps failing. I’ve tried different file types and '
        'sizes, but nothing works.',
    messages: [
      TicketMessage(
        author: 'Sara Collins',
        role: 'Support Agent',
        body:
            'Hi Alex, thanks for reaching out. I’m looking into this issue '
            'for you. Could you please share the file type and size of the '
            'photos you’re trying to upload?',
        timestamp: 'May 31, 2025 • 10:28 AM',
        fromAgent: true,
      ),
      TicketMessage(
        author: 'Alex Johnson',
        role: 'You',
        body:
            'Hi Sara, I tried JPG images, around 5MB each. I also tried PNG and '
            'HEIC, same issue.',
        timestamp: 'May 31, 2025 • 10:33 AM',
        fromAgent: false,
      ),
      TicketMessage(
        author: 'Sara Collins',
        role: 'Support Agent',
        body:
            'Thanks for the info, Alex. We’ve identified the issue and our '
            'team is working on a fix. I’ll update you as soon as it’s '
            'resolved.',
        timestamp: 'May 31, 2025 • 10:40 AM',
        fromAgent: true,
      ),
      TicketMessage(
        author: 'Alex Johnson',
        role: 'You',
        body:
            'Great news! It’s been updated and now the uploads are working '
            'perfectly. Thank you!',
        timestamp: 'May 31, 2025 • 11:02 AM',
        fromAgent: false,
      ),
    ],
  );

  // ---- Maintenance ------------------------------------------------------

  static const todaySchedule = [
    WorkOrder(
      id: 'WO-1024',
      title: 'AC not cooling',
      unit: 'Marina Apartment 1502',
      time: '9:00 AM',
      priority: WorkPriority.high,
      status: 'In Progress',
    ),
    WorkOrder(
      id: 'WO-1025',
      title: 'Kitchen sink leak',
      unit: 'Palm Villa 27',
      time: '11:00 AM',
      priority: WorkPriority.medium,
    ),
    WorkOrder(
      id: 'WO-1026',
      title: 'Light replacement',
      unit: 'Skyline Residences B-804',
      time: '2:00 PM',
      priority: WorkPriority.low,
    ),
  ];

  static const assignedOrders = [
    WorkOrder(
      id: 'WO-1024',
      title: 'AC not cooling in living room',
      unit: 'Marina Apartment 1502',
      time: 'Today • 9:00 AM',
      priority: WorkPriority.high,
      status: 'In Progress',
    ),
    WorkOrder(
      id: 'WO-1025',
      title: 'Kitchen sink leak',
      unit: 'Palm Villa 27',
      time: 'Today • 11:00 AM',
      priority: WorkPriority.medium,
      status: 'Assigned',
    ),
    WorkOrder(
      id: 'WO-1026',
      title: 'Light replacement in hallway',
      unit: 'Skyline Residences B-804',
      time: 'Today • 2:00 PM',
      priority: WorkPriority.low,
      status: 'Assigned',
    ),
  ];

  static const approvals = [
    ApprovalRequest(
      id: 'WO-1024',
      title: 'Replace water heater',
      amount: 'AED 1,250.00',
      unit: 'Marina Apartment 1103',
    ),
  ];

  static const maintenanceActivity = [
    ActivityEntry(
      title: '#WO-1015 Completed — Paint touch-up',
      time: '2 hours ago',
      icon: Icons.check_circle_outline,
      tint: RC.success,
    ),
    ActivityEntry(
      title: '#WO-1016 In Progress — Bathroom faucet replacement',
      time: '4 hours ago',
      icon: Icons.hourglass_bottom_outlined,
      tint: RC.warning,
    ),
  ];

  static const areaWorkload = {
    'Dubai Marina': 3,
    'Palm Jumeirah': 2,
    'Downtown Dubai': 1,
  };

  // ---- Tenant -----------------------------------------------------------

  static const lease = LeaseInfo(
    property: 'Marina Apartment',
    unit: 'A-1204',
    period: '01 Jan 2025 – 31 Dec 2025',
    rentAmount: 'AED 12,000',
    dueDate: '05 May 2025',
    daysRemaining: 3,
    serviceCharge: 'AED 850',
  );

  static const announcements = [
    Announcement(
      title: 'Pool Maintenance on 10th May 2025',
      body: 'The swimming pool will be closed for routine maintenance.',
      date: '02 May 2025',
    ),
    Announcement(
      title: 'Visitor parking resurfacing',
      body: 'Level B2 visitor bays are unavailable until 14 May 2025.',
      date: '30 Apr 2025',
    ),
  ];

  // ---- Owner ------------------------------------------------------------

  static const incomeSeries = <double>[
    398000,
    412000,
    436000,
    455000,
    457500,
    512400,
  ];
  static const incomeLabels = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];

  static const inquiries = [
    Inquiry(
      name: 'Julia Martin',
      message: 'Interested in Marina Apartment',
      time: '12 min ago',
      avatarUrl: Img.avatarJulia,
    ),
    Inquiry(
      name: 'Rohan Kapoor',
      message: 'Inquiry about Palm Villa',
      time: '1 hour ago',
      avatarUrl: Img.avatarMichael,
    ),
    Inquiry(
      name: 'Aisha Saeed',
      message: 'Looking for 2BR in Downtown',
      time: '3 hours ago',
      avatarUrl: Img.avatarAisha,
    ),
  ];

  static const recentPayments = [
    PaymentRecord(
        unit: 'Marina Apartment 501', amount: 'AED 18,000', date: '18 May 2025'),
    PaymentRecord(
        unit: 'Downtown Suites 1203', amount: 'AED 16,500', date: '15 May 2025'),
    PaymentRecord(unit: 'Palm Villa 17', amount: 'AED 24,000', date: '12 May 2025'),
  ];

  static const performance = [
    PropertyPerformance(
        name: 'Marina Apartment', occupancy: 92, rent: 'AED 18,000/mo'),
    PropertyPerformance(name: 'Palm Villa', occupancy: 100, rent: 'AED 45,000/mo'),
    PropertyPerformance(
        name: 'Downtown Suites', occupancy: 88, rent: 'AED 16,500/mo'),
    PropertyPerformance(
        name: 'Jumeirah Lofts', occupancy: 85, rent: 'AED 14,000/mo'),
  ];

  // ---- Super admin ------------------------------------------------------

  static const adminCommunities = [
    AdminCommunity(
      name: 'Palm Jumeirah Residences',
      location: 'Palm Jumeirah, Dubai',
      properties: 186,
      occupancy: 94,
      revenue: 'AED 210,000',
      status: 'Active',
      imageUrl: Img.villaHero,
    ),
    AdminCommunity(
      name: 'Dubai Marina Towers',
      location: 'Dubai Marina, Dubai',
      properties: 242,
      occupancy: 88,
      revenue: 'AED 160,500',
      status: 'Active',
      imageUrl: Img.marinaApartment,
    ),
    AdminCommunity(
      name: 'Downtown Views',
      location: 'Downtown Dubai, Dubai',
      properties: 156,
      occupancy: 91,
      revenue: 'AED 135,200',
      status: 'Active',
      imageUrl: Img.dubaiSkyline,
    ),
    AdminCommunity(
      name: 'Emirates Hills',
      location: 'Emirates Hills, Dubai',
      properties: 78,
      occupancy: 86,
      revenue: 'AED 112,300',
      status: 'Active',
      imageUrl: Img.villaDusk,
    ),
    AdminCommunity(
      name: 'Jumeirah Beach Residence',
      location: 'JBR, Dubai',
      properties: 312,
      occupancy: 82,
      revenue: 'AED 98,700',
      status: 'Active',
      imageUrl: Img.dubaiWaterfront,
    ),
    AdminCommunity(
      name: 'Business Bay Executive',
      location: 'Business Bay, Dubai',
      properties: 94,
      occupancy: 79,
      revenue: 'AED 87,400',
      status: 'Review',
      imageUrl: Img.officeSpace,
    ),
  ];

  static const revenueSeries = <double>[
    960000,
    1035000,
    1088000,
    1162000,
    1240000,
  ];
  static const revenueLabels = [
    'Apr 21',
    'Apr 28',
    'May 05',
    'May 12',
    'May 19',
  ];

  static const planBreakdown = [
    PlanSlice(name: 'Enterprise', count: 32, percent: 25, color: RC.navy),
    PlanSlice(name: 'Growth', count: 48, percent: 38, color: RC.teal),
    PlanSlice(name: 'Starter', count: 28, percent: 22, color: RC.info),
    PlanSlice(name: 'Basic', count: 20, percent: 15, color: RC.borderStrong),
  ];

  static const platformActivity = [
    ActivityEntry(
      title: 'New community "Marina Heights" was created',
      time: '8 min ago',
      icon: Icons.apartment_outlined,
      tint: RC.teal,
    ),
    ActivityEntry(
      title: 'Subscription upgraded to Enterprise Plan',
      time: '32 min ago',
      icon: Icons.workspace_premium_outlined,
      tint: RC.warning,
    ),
    ActivityEntry(
      title: 'New user registered: Sarah Johnson',
      time: '1 hour ago',
      icon: Icons.person_add_alt_outlined,
      tint: RC.info,
    ),
    ActivityEntry(
      title: 'Maintenance request submitted in Sunrise Villas',
      time: '2 hours ago',
      icon: Icons.build_outlined,
      tint: RC.purple,
    ),
  ];

  static const topCommunities = [
    CommunityRevenue(
        name: 'Palm Jumeirah Residences', revenue: 'AED 210,000', value: 1.0),
    CommunityRevenue(
        name: 'Dubai Marina Towers', revenue: 'AED 160,500', value: 0.76),
    CommunityRevenue(name: 'Downtown Views', revenue: 'AED 135,200', value: 0.64),
    CommunityRevenue(name: 'Emirates Hills', revenue: 'AED 112,300', value: 0.53),
  ];

  // ---- Plans ------------------------------------------------------------

  static const plans = [
    SubscriptionPlan(
      name: 'STARTER',
      tagline: 'Perfect for getting started',
      monthlyPrice: 99,
      yearlyPrice: 950,
      features: [
        PlanFeature('Up to 5 Listings', true),
        PlanFeature('1 Featured Listing', true),
        PlanFeature('Community Access', true),
        PlanFeature('Basic Analytics', true),
        PlanFeature('Email Support', true),
        PlanFeature('Owner Portals', false),
        PlanFeature('Maintenance Tools', false),
      ],
    ),
    SubscriptionPlan(
      name: 'PROFESSIONAL',
      tagline: 'Ideal for growing portfolios',
      monthlyPrice: 249,
      yearlyPrice: 2390,
      recommended: true,
      features: [
        PlanFeature('Up to 25 Listings', true),
        PlanFeature('5 Featured Listings', true),
        PlanFeature('Community Access', true),
        PlanFeature('Advanced Analytics', true),
        PlanFeature('Priority Support', true),
        PlanFeature('Owner Portals', true),
        PlanFeature('Maintenance Tools', true),
      ],
    ),
    SubscriptionPlan(
      name: 'ENTERPRISE',
      tagline: 'For large teams & enterprises',
      monthlyPrice: 499,
      yearlyPrice: 4790,
      features: [
        PlanFeature('Unlimited Listings', true),
        PlanFeature('Unlimited Featured', true),
        PlanFeature('Community Access', true),
        PlanFeature('Advanced Analytics', true),
        PlanFeature('24/7 Priority Support', true),
        PlanFeature('Owner Portals', true),
        PlanFeature('Maintenance Tools', true),
      ],
    ),
  ];

  // ---- Legal ------------------------------------------------------------

  static const privacySections = [
    LegalSection(1, 'Introduction',
        'At RESIVYN, we value your trust and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data.'),
    LegalSection(2, 'Information We Collect',
        'We collect personal info you provide (e.g., name, email, phone), property details, usage data, and device information to deliver and improve our services.'),
    LegalSection(3, 'How We Use Your Information',
        'We use your data to manage your account, list and manage properties, process transactions, provide support, and enhance your experience on RESIVYN.'),
    LegalSection(4, 'Data Sharing',
        'We do not sell your personal data. We may share information with trusted service providers and legal authorities when required by law or to protect our rights.'),
    LegalSection(5, 'Cookies & Analytics',
        'We use cookies and similar technologies to remember your preferences, analyze app usage, and improve our services. You can manage your cookie settings anytime.'),
    LegalSection(6, 'Your Rights',
        'You have the right to access, correct, or delete your personal data. You can also object to processing or withdraw consent at any time through your account settings.'),
  ];

  static const termsSections = [
    LegalSection(1, 'Acceptance of Terms',
        'By accessing or using RESIVYN, you agree to be bound by these Terms & Conditions and our Privacy Policy.'),
    LegalSection(2, 'Use of Platform',
        'RESIVYN provides a platform for real estate listings, communication, and related services. You agree to use the platform only for lawful purposes.'),
    LegalSection(3, 'User Accounts',
        'You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. Notify us immediately of any unauthorized use.'),
    LegalSection(4, 'Listings & Content',
        'You are solely responsible for the accuracy of listings and content you post. RESIVYN reserves the right to review, edit, or remove any content that violates these terms.'),
    LegalSection(5, 'Payments & Billing',
        'All payments are processed securely. Fees, taxes, and charges are non-refundable unless stated otherwise.'),
    LegalSection(6, 'Limitation of Liability',
        'RESIVYN is not liable for any indirect, incidental, or consequential damages arising from your use of the platform or reliance on any information provided.'),
  ];

  static const offices = [
    OfficeArea('Dubai Marina', 2),
    OfficeArea('Jumeirah', 1),
    OfficeArea('Business Bay', 3),
    OfficeArea('DIFC', 1),
    OfficeArea('Downtown Dubai', 2),
    OfficeArea('Dubai Creek Harbour', 1),
  ];

  // ---- About ------------------------------------------------------------

  static const aboutBlurb =
      'RESIVYN is a next-generation real estate and community operating system '
      'that connects buyers, renters, owners, tenants, and property managers on '
      'one seamless platform. We simplify how people discover, manage, and grow '
      'their real estate experiences.';

  static const aboutPillars = [
    ('Our Mission',
        'To simplify real estate experiences through innovation, transparency, and trust.',
        Icons.flag_outlined),
    ('Our Vision',
        'To be the leading real estate OS that empowers communities worldwide.',
        Icons.visibility_outlined),
    ('Our Values',
        'Integrity, customer centricity, innovation, and a commitment to excellence.',
        Icons.favorite_outline),
  ];

  static const offerings = [
    ('Buy', Icons.sell_outlined),
    ('Rent', Icons.vpn_key_outlined),
    ('Sell', Icons.real_estate_agent_outlined),
    ('Communities', Icons.holiday_village_outlined),
    ('Property Management', Icons.corporate_fare_outlined),
    ('Maintenance', Icons.handyman_outlined),
  ];
}
