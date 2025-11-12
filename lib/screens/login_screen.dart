// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_session.dart';
import '../pages/invoice_page.dart'; // Import InvoicePage để dùng routeName

class LoginScreen extends StatefulWidget {
  // Thêm routeName tĩnh để sử dụng trong main.dart
  static const routeName = '/login'; 
  
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController(text: 'admin');
  final passController = TextEditingController(text: 'HPC');
  final baseController = TextEditingController(text: 'BB');
  String? responseText;
  bool loading = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    baseController.dispose();
    super.dispose();
  }
  
  // Hàm chuyển hướng sau khi đăng nhập thành công
  void _navigateToHome() {
    if (mounted) {
      // Dùng InvoicePage.routeName thay cho '/home' để đồng bộ
      // Nếu '/home' trong main.dart là InvoicePage, bạn vẫn có thể dùng '/home'
      Navigator.pushReplacementNamed(context, InvoicePage.routeName); 
    }
  }
  
  // Logic đăng nhập giả để kiểm tra giao diện (có thể xóa khi deploy)
  void _fakeLogin() {
      // Chỉ chạy mã giả này khi cần test UI
      AppSession.token = 'fake_access_token';
      AppSession.userInfo = {'access_token' : AppSession.token};
      _navigateToHome();
  }

  Future<void> _login() async {
    setState(() {
      loading = true;
      responseText = null;
    });
    String userName = userController.text.trim();
    String password = passController.text.trim();
    String madvcs = baseController.text.trim();
    final url = Uri.parse('http://digitalantiz.net/v6-api/users/login');
    final body = jsonEncode({
      "UserName": userName, "password": password, "baseUnitCode": madvcs,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Cập nhật response trước khi kiểm tra trạng thái
      setState(() {
        responseText = '${response.statusCode}\n${response.body}';
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          // THÀNH CÔNG THỰC SỰ
          AppSession.token = data['access_token'];
          AppSession.userInfo = data;
          AppSession.baseUnitCode = madvcs;
          _navigateToHome(); // CHUYỂN HƯỚNG CHỈ KHI THÀNH CÔNG
          return; // Thoát khỏi hàm _login
        }
      }
      
      // Nếu không phải 200 HOẶC không có token: GỌI ĐĂNG NHẬP GIẢ
      // Bỏ qua dòng này khi deploy thật
      // _fakeLogin(); 

    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
      });
      // Bỏ qua dòng này khi deploy thật
      // _fakeLogin(); 
      
    } finally {
      // Đảm bảo loading là false ở cuối cùng
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... (Phần UI giữ nguyên) ...
            TextField(controller: userController, decoration: const InputDecoration(labelText: 'UserName')),
            TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password',)),
            TextField(controller: baseController, decoration: const InputDecoration(labelText: 'BaseUnitCode')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 20),
            if (responseText != null)
              Expanded(
                child: SelectableText(
                  responseText!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}