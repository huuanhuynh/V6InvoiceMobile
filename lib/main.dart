// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/pages/invoice_list_page.dart';
import 'package:v6_invoice_mobile/pages/login_page.dart';
import 'package:v6_invoice_mobile/screens/login_screen.dart';
import 'repository.dart';
import 'pages/invoice_page.dart';

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
        // 1. Đặt trang khởi động mặc định là LoginPage
        initialRoute: LoginPage.routeName,
        routes: {
          // Trang Login: Sẽ là trang đầu tiên (hoặc đặt route là '/')
          LoginPage.routeName: (_) => const LoginPage(), 
          InvoiceListPage.routeName: (_) => const InvoiceListPage(),
          InvoicePage.routeName: (_) => InvoicePage(mact: "SOH", invoice: Invoice(), mode: InvoiceMode.view),
        },
      ),
    );
  }
}