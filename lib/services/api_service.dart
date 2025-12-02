import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/models/api_response.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';

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

  static Future<dynamic> getInvoiceList({
    required String maCt, // Invoice type: SOH or ARC
    required String fromDate, // Format: yyyyMMdd (e.g., "20251020")
    required String toDate, // Format: yyyyMMdd (e.g., "20251021")
    required String maDvcs, // Base unit code (e.g., "BB")
    String type = '2', // Type parameter (default: "2")
    int pageIndex = 1, // Page number for pagination
    int pageSize = 10, // Page size for pagination
  }) async {
    final token = AppSession.token;

    try {
      final requestBody = {
        'fromDate': fromDate,
        'toDate': toDate,
        'maDvcs': maDvcs,
        'type': type,
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v6-api/qr-codes/inventory-management/$maCt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (decoded);
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        throw Exception('Failed to load QR codes: ${response.body}');
      }
    } catch (e) {
      throw ('Network error: $e');
    }
  }

  static getNewInvoiceNumber(String mact) {
    // Giả sử định dạng số hóa đơn là "SOH-YYYYMMDD-XXXX"
    final now = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (1000 + (now.millisecond % 9000)).toString(); // Tạo phần ngẫu nhiên
    return '$mact-$datePart-$randomPart';
  }

  static Future<void> postNewInvoice(Invoice invoice) async {}

  static Future<void> putUpdateInvoice(Invoice invoice) async {}


}
