// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:v6_invoice_mobile/pages/invoice_list_page.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
import 'package:v6_invoice_mobile/h.dart';
import '../app_session.dart';

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
  String? _statusText;
  bool _isLoading = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    //baseController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAndSelectCatalog(BuildContext context) async {
    // Đặt giá trị mặc định cho các tham số catalogs. Cần điều chỉnh theo thực tế.
    const String fvvar = 'MA_DVCS'; // Ví dụ: biến API để lấy danh sách đơn vị
    const String type = '2';
    const String filterValue = '';
    const int pageIndex = 1;
    const int pageSize = 100;

    setState(() {
      _isLoading = true; // Bật loading trong khi load danh mục
      _statusText = 'Đang tải danh mục DVCS...';
    });
    
    try {
      // Gọi API để lấy danh sách
      final apiResponse = await ApiService.catalogs(
        vvar: fvvar,
        filterValue: filterValue,
        type: type,
        pageIndex: pageIndex,
        pageSize: pageSize,
        advance: '',
      );

      if (apiResponse.error == null && apiResponse.data != null) {
        final parsed = apiResponse.data;
        // Trích xuất danh sách items từ data (dựa trên logic bạn cung cấp)
        final List<dynamic> listItems = parsed is List ? parsed : (parsed['items'] ?? parsed['data'] ?? []);

        setState(() {
          _isLoading = false; // Tắt loading để cho phép hiển thị dialog
        });

        if (listItems.isNotEmpty) {
          final selectedItem = await showCatalogSelectionDialog(context, listItems);
          
          if (selectedItem != null) {
            AppSession.madvcs = H.getValue(selectedItem, 'MA_DVCS');
            // Chuyển hướng đến trang chính sau khi chọn đơn vị
            if (mounted) {
              Navigator.pushReplacementNamed(context, InvoiceListPage.routeName);
            }
          } else {
            // Người dùng đóng Dialog mà không chọn
            setState(() {
              _statusText = 'Vui lòng chọn một đơn vị để tiếp tục.';
              _isLoading = false; // Đảm bảo loading là false
            });
          }
        } else {
          setState(() {
            _statusText = 'Không tìm thấy danh mục đơn vị.';
          });
        }
      } else {
        setState(() {
          _statusText = 'Lỗi tải danh mục: ${apiResponse.error ?? 'Unknown error'}';
        });
      }

    } catch (e) {
      setState(() {
        _statusText = 'Lỗi trong quá trình tải danh mục: $e';
      });
    } finally {
      // Luôn đảm bảo loading được đặt lại, trừ khi đã chuyển hướng thành công
      if (_isLoading) {
        setState(() {
            _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> showCatalogSelectionDialog(
      BuildContext context, List<dynamic> items) {
    
    // Xử lý trường hợp items có thể là Map<String, dynamic> (nếu bạn dùng ListView)
    final List<Map<String, dynamic>> catalogList = 
        items.map((e) => Map<String, dynamic>.from(e)).toList();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // BẮT BUỘC KHÔNG THỂ THOÁT NẾU CHƯA CHỌN
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Chọn Đơn Vị/Chi Nhánh'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: catalogList.length,
              itemBuilder: (context, index) {
                final item = catalogList[index];
                // Giả định item có trường 'TenDonVi' hoặc 'Name'
                final itemName = '${H.getValue(item, 'MA_DVCS')}: ${H.getValue(item, 'TEN_DVCS')}';

                return ListTile(
                  title: Text(itemName),
                  onTap: () {
                    // Trả về item đã chọn và đóng Dialog
                    Navigator.of(dialogContext).pop(item); 
                  },
                );
              },
            ),
          ),
          actions: [
            // Thường không có nút đóng khi bắt buộc chọn, 
            // nhưng có thể thêm nếu muốn người dùng hủy bỏ (và quay lại trang login)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null), // Trả về null khi hủy
              child: const Text('Hủy bỏ'),
            )
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _statusText = null;
    });
    String userName = userController.text.trim();
    String password = passController.text.trim();
    //String madvcs = baseController.text.trim();

    try {
      final fresponse = ApiService.login(username: userName, password: password);
      var apiResponse = await fresponse;
      setState(() {
        _statusText = '${apiResponse.response}';
      });

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        final data = jsonDecode(apiResponse.response!.body);
        if (data['access_token'] != null) {
          AppSession.token = data['access_token'];
          AppSession.userInfo = data;
          AppSession.madvcs = 'BB';
          _loadAndSelectCatalog(context);
        }
      } else {
        setState(() {
          _statusText = 'Đăng nhập thất bại: ${apiResponse.response?.statusCode}';
        });
      }

    } catch (e) {
      setState(() {
        _statusText = 'Error: $e';
      });
      // Bỏ qua dòng này khi deploy thật
      // _fakeLogin(); 
      
    } finally {
      // Đảm bảo loading là false ở cuối cùng
      setState(() {
        _isLoading = false;
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
            TextField(controller: userController, decoration: const InputDecoration(labelText: 'UserName')),
            TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password',),
              obscureText: true,
            ),
            //TextField(controller: baseController, decoration: const InputDecoration(labelText: 'BaseUnitCode')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 20),
            if (_statusText != null)
              Expanded(
                child: SelectableText(
                  _statusText!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}