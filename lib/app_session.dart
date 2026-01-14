class AppSession {
  static String? token;
  static String? username;
  static String? madvcs;
  static Map<String, dynamic>? userData;

  static dynamic loginData;

  static bool get isLoggedIn => token != null;
}
