/// Named routes for every screen in the app.
///
/// The trailing comment is the screen number from the RESIVYN spec, so the
/// spec and the code stay traceable to each other.
class Routes {
  Routes._();

  static const login = '/login'; // 10
  static const signup = '/signup'; // registration
  static const forgotPassword = '/forgot-password';
  static const liveChat = '/live-chat';
  static const personalInfo = '/personal-info';
  static const security = '/security';
  static const notificationSettings = '/notification-settings';
  static const accountSettings = '/account-settings';
  static const language = '/language';
  static const paymentMethods = '/payment-methods';
  static const savedSearches = '/saved-searches';
  static const supportCategory = '/support-category';
  static const devIndex = '/dev-index'; // developer screen browser
  static const shell = '/shell'; // visitor tab shell (Home/Search/Saved/…)

  static const home = '/home'; // 11
  static const search = '/search'; // 09
  static const saved = '/saved'; // supporting
  static const community = '/community'; // supporting
  static const profile = '/profile'; // 21

  static const propertyDetails = '/property'; // 12
  static const villaDetails = '/property/villa'; // 08
  static const floorPlan = '/property/floor-plan'; // 01
  static const gallery = '/property/gallery'; // 13
  static const sellProperty = '/sell'; // 14

  static const support = '/support'; // 02
  static const ticketDetails = '/support/ticket'; // 20
  static const notifications = '/notifications'; // 03

  static const adminDashboard = '/dashboard/admin'; // 04
  static const adminCommunities = '/dashboard/admin/communities';
  static const adminProperties = '/dashboard/admin/properties';
  static const maintenanceDashboard = '/dashboard/maintenance'; // 05
  static const tenantDashboard = '/dashboard/tenant'; // 06
  static const ownerDashboard = '/dashboard/owner'; // 07

  static const about = '/about'; // 15
  static const contact = '/contact'; // 16
  static const plans = '/plans'; // 17
  static const privacy = '/privacy'; // 18
  static const terms = '/terms'; // 19
}
