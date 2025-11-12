import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/models.dart';

class ApiService {
  static const String baseUrl = 'http://digitalantiz.net';

  static Future<ApiResponse> login({required String username, required String password, required String baseUnitCode,
  }) async {
    final url = Uri.parse('$baseUrl/v6-api/users/login');
    final body = jsonEncode({
      'UserName': username,
      'Password': password,
      'baseUnitCode': baseUnitCode,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    ApiResponse result = ApiResponse();
    result.response = response;
    if (response.statusCode == 200) {
      result.data = jsonDecode(response.body);
    } else {
      result.error = response.reasonPhrase;
    }
    return result;
  }

  static Future<ApiResponse> catalogs({
    required String vvar,
    required String filterValue,
    required String type,
    required int pageIndex,
    required int pageSize,
  }) async {
    final url = Uri.parse('$baseUrl/v6-api/catalogs');
    final body = jsonEncode({
      'vVar' : vvar,
      'vValue' : filterValue, // giá trị gõ vào để lọc
      'language' : 'V',
      'maDvcs' : AppSession.madvcs,
      'advance' : null, // chưa dùng
      'type': type,
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AppSession.token}'},      
      body: body,
    );
    ApiResponse result = ApiResponse();
    result.response = response;

    if (response.statusCode == 200) {
      result.data = jsonDecode(response.body);
      return result;
    } else {
      result.error = response.reasonPhrase;
      return result;
    }
  }


}
