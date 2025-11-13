import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/models.dart';

class ApiService {
  static const String baseUrl = 'http://digitalantiz.net';

  static Future<ApiResponse> login({required String username, required String password
  }) async {
    final url = Uri.parse('$baseUrl/v6-api/users/login');
    final body = jsonEncode({
      'UserName': username,
      'Password': password,
      //'baseUnitCode': baseUnitCode,
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

  /// Gọi API lấy danh mục.
  ///
  /// Các tham số:
  /// - [vvar]: Mã danh mục cần truy vấn.
  /// - [filterValue]: Giá trị người dùng nhập để lọc.
  /// - [type]: Loại danh mục (ví dụ: 'PRODUCT', 'CUSTOMER').
  /// - [pageIndex]: Trang hiện tại (bắt đầu từ 1).
  /// - [pageSize]: Số dòng mỗi trang.
  ///
  /// Returns:
  /// - Một [ApiResponse] chứa kết quả truy vấn danh mục từ API.
  ///   Nếu lỗi, thuộc tính [ApiResponse.error] sẽ có thông tin lỗi.
  static Future<ApiResponse> catalogs({
    required String vvar,
    required String filterValue,
    required String type,
    required int pageIndex,
    /// số phần tử mỗi trang.
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
