import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/api_response.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';

class ApiService {
  //static const String baseUrl = 'http://digitalantiz.net/v6-api';
  ///https://localhost:5001
  static const String baseUrl = 'https://localhost:5001';

  static Future<ApiResponse> login({required String username, required String password
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
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
    required String type, // '2'
    required int pageIndex,
    /// số phần tử mỗi trang.
    required int pageSize,
    required String advance,
  }) async {
    final url = Uri.parse('$baseUrl/catalogs');
    final body = jsonEncode({
      'vVar' : vvar,
      'vValue' : filterValue, // giá trị gõ vào để lọc
      'language' : 'V',
      'maDvcs' : AppSession.madvcs,
      'advance' : advance, // chưa dùng
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

  /// Lấy dữ liệu danh sách chứng từ trả về {data: {items: List<invoiceAPI>}}
  static Future<Map<String,dynamic>> getInvoiceList({
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
        Uri.parse('$baseUrl/qr-codes/inventory-management/$maCt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String,dynamic>;
        return decoded;
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        throw Exception('getInvoiceList Failed: ${response.body}');
      }
    } catch (e) {
      throw ('Network error: $e');
    }
  }

  static Future<Map<String,dynamic>> getInvoiceListSOH({
    required String fromDate, // Format: yyyyMMdd (e.g., "20251020")
    required String toDate, // Format: yyyyMMdd (e.g., "20251021")
    required String maDvcs, // Base unit code (e.g., "BB")
    String? advance,
    String type = '2', // Type parameter (default: "2")
    int pageIndex = 1, // Page number for pagination
    int pageSize = 10, // Page size for pagination
  }) async {
    final token = AppSession.token;

    try {
      final queryParameters = {
        'fromDate': fromDate,
        'toDate': toDate,
        'maDvcs': maDvcs,
        //'advance': advance, // chưa dùng
        'type': type,
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      };
      Uri uri;
      if (baseUrl.startsWith('http://')) {
        uri = Uri.http(baseUrl.replaceFirst('http://', ''), '/invoices/sale-order', queryParameters);
      } else if (baseUrl.startsWith('https://')) {
        uri = Uri.https(baseUrl.replaceFirst('https://', ''), '/invoices/sale-order', queryParameters);
      }
      else {
        uri = Uri.http(baseUrl, '/invoices/sale-order', queryParameters);
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String,dynamic>;
        return decoded;
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        throw Exception('getInvoiceList Failed: ${response.body}');
      }
    } catch (e) {
      throw ('Network error: $e');
    }
  }


  /// Lấy dữ liệu 1 chứng từ trả về {data: invoiceAPI}
  static Future<Map<String,dynamic>> getInvoice({
    required String maCt, // Invoice type: SOH or IXB
    required String sttRec,
    required String maDvcs
  }) async {
    final token = AppSession.token;

    try {
      final requestBody = {
        'maDvcs': maDvcs,
        'lan': 'V'
      };

      final response = await http.post(
        Uri.parse('$baseUrl/qr-codes/inventory-management/$maCt/$sttRec'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String,dynamic>;
        return decoded;
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        throw Exception('getInvoiceList Failed: ${response.body}');
      }
    } catch (e) {
      throw ('Network error: $e');
    }
  }

  static Future<Map<String,dynamic>> getAlct1Config({
    required String mact,
    required String magd,
  }) async 
  {
    try {
      final queryParameters = {
        'mact': mact,
        'magd': magd,
      };
      Uri uri;
      if (baseUrl.startsWith('http://')) {
        uri = Uri.http(baseUrl.replaceFirst('http://', ''), '/invoices/alct1', queryParameters);
      } else if (baseUrl.startsWith('https://')) {
        uri = Uri.https(baseUrl.replaceFirst('https://', ''), '/invoices/alct1', queryParameters);
      }
      else {
        uri = Uri.http(baseUrl, '/invoices/alct1', queryParameters);
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSession.token}',
        }
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String,dynamic>;
        return decoded;
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        throw Exception('getInvoiceList Failed: ${response.body}');
      }
    } catch (e) {
      throw ('Network error: $e');
    }
  }



  static getNewSttRec(String mact) {
    // Giả sử định dạng số hóa đơn là "SOH-YYYYMMDD-XXXX"
    final now = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (1000 + (now.millisecond % 9000)).toString(); // Tạo phần ngẫu nhiên
    return '$mact-$datePart-$randomPart';
  }

  static Future<ApiResponse> postNewInvoice(Invoice invoice) async {
    final token = AppSession.token;
    try {
      final requestBody = {
        'mode': 'ADD',
        'data': {
          'master' : invoice.getMasterDataForAPI,
          'details' : invoice.getDetailDatasForAPI
        },
      };
      String jsonBody = H.toJson(requestBody);
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/sale-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonBody,
      );

      ApiResponse result = ApiResponse();
      result.response = response;
      if (response.statusCode == 200) {
        result.data = jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        result.error = response.reasonPhrase;
      }
      return result;
    } catch (e) {
      throw ('Error: $e');
    }
  }

  static Future<ApiResponse> putUpdateInvoice(Invoice invoice) async {
    final token = AppSession.token;
    try {
      final requestBody = {
        'mode': 'EDIT',
        'data': {
          'master' : invoice.getMasterDataForAPI,
          'details' : invoice.getDetailDatasForAPI
        },
      };

      String jsonBody = H.toJson(requestBody);

      final response = await http.post(
        Uri.parse('$baseUrl/invoices/sale-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonBody,
      );

      ApiResponse result = ApiResponse();
      result.response = response;
      if (response.statusCode == 200) {
        result.data = jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        result.error = response.reasonPhrase;
      }
      return result;
    } catch (e) {
      throw ('Error: $e');
    }
  }

  static Future<ApiResponse> deleteInvoiceSOH(Invoice invoice) async {
    final token = AppSession.token;
    try {
      // final requestBody = {
      //   'mode': 'DELETE',
      //   'data': {
      //     'stt_rec': invoice.sttrec, // chỉ cần gửi stt_rec để xóa cho nhẹ? // hoặc tạo hàm xóa
      //     'master' : invoice.getMasterDataForAPI,
      //     'details' : invoice.getDetailDatasForAPI
      //   },
      // };
      //String jsonBody = H.toJson(requestBody);

      final response = await http.delete(
        Uri.parse('$baseUrl/qr-codes/inventory-management/SOH/${invoice.sttrec}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        //body: jsonBody,
      );

      ApiResponse result = ApiResponse();
      result.response = response;
      if (response.statusCode == 200) {
        result.data = jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw ('Unauthorized');
      } else {
        result.error = response.reasonPhrase;
      }
      return result;
    } catch (e) {
      throw ('Error: $e');
    }
  }

  static Future<double> getTyGia(String mant, DateTime ngayct) async {
    // Giả sử tỷ giá cố định cho ví dụ
    if (mant == 'USD') {
      return 23000.0; // Ví dụ tỷ giá USD/VND
    } else if (mant == 'EUR') {
      return 27000.0; // Ví dụ tỷ giá EUR/VND
    } else if (mant == 'JPY') {
      return 200.0; // Ví dụ tỷ giá JPY/VND
    } else if (mant == 'AUD') {
      return 16000.0; // Ví dụ tỷ giá AUD/VND
    } else {
      return 1.0; // Mặc định VND mant0
    }
  }

  


}
