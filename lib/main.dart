// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:v6_invoice_mobile/app_session.dart'; // Không cần dùng trực tiếp AppSession ở đây
import 'package:v6_invoice_mobile/pages/catalog_page.dart';
import 'package:v6_invoice_mobile/screens/login_screen.dart';
import 'repository.dart';
//import 'pages/invoice_list_page.dart'; // Đổi tên thành InvoicePage
import 'pages/invoice_page.dart'; 
import 'pages/item_edit_page.dart';

void main() {
  runApp(const V6InvoiceApp());
}

class V6InvoiceApp extends StatelessWidget {
  const V6InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceRepository(),
      child: MaterialApp(
        title: 'V6 Invoice Mobile',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: false,
        ),
        // 1. Đặt trang khởi động mặc định là LoginScreen
        initialRoute: LoginScreen.routeName, 
        
        routes: {
          // Trang Login: Sẽ là trang đầu tiên (hoặc đặt route là '/')
          LoginScreen.routeName: (_) => const LoginScreen(), 
          
          // Trang Chính sau khi Login (thường gọi là '/home' hoặc '/invoice')
          InvoicePage.routeName: (_) => const InvoicePage(mact: "SOH"),
          
          // Các routes phụ
          ItemEditPage.routeName: (_) => const ItemEditPage(),
          
          // Thêm CatalogPage (cần cho chức năng tra cứu)
          // CatalogPage không có routeName tĩnh, nên định nghĩa trực tiếp:
          '/catalog': (context) {
            // Lấy arguments nếu có (cần thiết cho CatalogPage)
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return CatalogPage(
              fvvar: args?['fvvar'] ?? '',
              type: args?['type'] ?? '',
            );
          },
        },
      ),
    );
  }
}