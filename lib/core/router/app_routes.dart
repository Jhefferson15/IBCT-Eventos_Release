class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String checkin = '/checkin';
  
  // Dynamic routes (methods to generate paths)
  static String editor(String eventId) => '/editor/$eventId';
  static String analytics(String eventId) => '/analytics/$eventId';
  static String storeSettings(String eventId) => '/store-settings/$eventId';
  static String storeDashboard(String eventId) => '/store-dashboard/$eventId';
  static String storePos(String eventId) => '/store-pos/$eventId';
  static String storeHistory(String eventId) => '/store-history/$eventId';

  // Route Names (optional, if using named routes)
  static const String loginName = 'login';
  static const String dashboardName = 'dashboard';
  static const String profileName = 'profile';
  static const String changePasswordName = 'changePassword';
  static const String checkinName = 'checkin';
  static const String editorName = 'editor';
  static const String analyticsName = 'analytics';
  static const String storeSettingsName = 'storeSettings';
  static const String storeDashboardName = 'storeDashboard';
  static const String storePosName = 'storePos';
  static const String storeHistoryName = 'storeHistory';
}
