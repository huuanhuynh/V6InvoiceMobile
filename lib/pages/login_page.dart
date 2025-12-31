import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/pages/invoice_list_page.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  static const routeName = '/login'; 
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _statusText;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nhập tên đăng nhập!';
    }
    // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    //   return 'Please enter a valid email';
    // }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nhập mật khẩu!';
    }
    // if (value.length < 6) {
    //   return 'Password must be at least 6 characters';
    // }
    return null;
  }

  Future<void> _handleLogin0() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _statusText = null;
    });
    String userName = _userController.text.trim();
    String password = _passController.text.trim();
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

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                ),

                const SizedBox(height: 32),

                // Welcome Text
                Text(
                  'V6SOFT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sale order management',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                const SizedBox(height: 48),

                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _userController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateUsername,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passController,
                          obscureText: !_isPasswordVisible,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),


                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "V6 © 2025",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_statusText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SelectableText(
                    _statusText!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],              
            ),
          ),
        ),
      ),
    );
  }
}