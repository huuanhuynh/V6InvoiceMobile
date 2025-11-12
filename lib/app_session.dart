class AppSession {
  static String? token;
  static String? username;
  static String? baseUnitCode;
  static Map<String, dynamic>? userData;

  static var userInfo;

  static bool get isLoggedIn => token != null;
}
