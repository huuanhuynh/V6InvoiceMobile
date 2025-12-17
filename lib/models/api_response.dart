import 'package:http/http.dart';

class ApiResponse{
  dynamic data;
  bool get isSuccess => data != null && data['isSuccess'] == true;
  String? error;
  Response? response;
}