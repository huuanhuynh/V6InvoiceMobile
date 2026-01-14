import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:v6_invoice_mobile/services/api_exceptions.dart';
import '../../../core/config/environment.dart';

class AuthApiService {
  String get baseUrl => Environment.apiBaseUrl;
  final storage = GetStorage();

  // Step 1: Login with username and password, then fetch business units
  // Returns: { access_token: string, businessUnits: Array<{key: string, value: string}> }
  Future<Map<String, dynamic>> loginStep1(
    String username,
    String password,
  ) async {
    try {
      // Step 1a: Login to get access token
      final loginBody = {'userName': username, 'password': password};

      final loginResponse = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginBody),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Login failed: ${loginResponse.body}');
      }

      // Extract access_token from login response
      String accessToken;
      try {
        final decoded = jsonDecode(loginResponse.body);
        if (decoded is Map<String, dynamic>) {
          accessToken = decoded['access_token'] ?? decoded['token'] ?? '';
        } else if (decoded is String) {
          accessToken = decoded;
        } else {
          accessToken = loginResponse.body.trim();
        }
      } catch (e) {
        accessToken = loginResponse.body.trim();
      }

      if (accessToken.isEmpty) {
        throw Exception('No access token received');
      }

      // Step 1b: Use the access token to fetch business units
      final businessUnitsBody = {
        'keyName': 'ma_dvcs',
        'valueName': 'ten_dvcs',
        'vVar': 'MA_DVCS',
        'vValue': '',
        'type': '2',
        'maDvcs': '',
        'pageIndex': 1,
        'pageSize': 50,
      };

      final businessUnitsResponse = await http.post(
        Uri.parse('$baseUrl/catalogs/key-value'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(businessUnitsBody),
      );

      if (businessUnitsResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch business units: ${businessUnitsResponse.body}',
        );
      }

      final businessUnitsData = jsonDecode(businessUnitsResponse.body);
      List<dynamic> businessUnits = [];

      // Handle different response formats
      if (businessUnitsData is List) {
        businessUnits = businessUnitsData;
      } else if (businessUnitsData is Map &&
          businessUnitsData.containsKey('data')) {
        businessUnits = businessUnitsData['data'] as List;
      } else if (businessUnitsData is Map &&
          businessUnitsData.containsKey('items')) {
        businessUnits = businessUnitsData['items'] as List;
      }

      // Return both access token and business units
      return {'access_token': accessToken, 'businessUnits': businessUnits};
    } catch (e) {
      if (e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Network error: $e');
    }
  }

  // Step 2: Select business unit
  // Since the user is already authenticated (has access_token from step 1),
  // we just return the token. The selected business unit is saved locally.
  // If your backend requires an API call to set the business unit, update this method.
  Future<Map<String, dynamic>> selectBusinessUnit(
    String accessToken,
    String baseUnitCode,
  ) async {
    // Option 1: No backend call needed - just return the token
    // The business unit code will be saved locally in the controller
    return {'access_token': accessToken};

    // Option 2: If backend needs to know the selected business unit, uncomment this:
    /*
    try {
      final requestBody = {
        'baseUnitCode': baseUnitCode,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/select-business-unit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Backend confirmed the business unit selection
        return {'access_token': accessToken};
      } else {
        throw Exception('Business unit selection failed: ${response.body}');
      }
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
    */
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    final token = storage.read('access_token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      } else {
        throw Exception('Failed to load profile');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    final token = storage.read('access_token');

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore logout network errors
    }
  }
}
