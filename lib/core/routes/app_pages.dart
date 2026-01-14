import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/core/auth/auth_binding.dart';
import 'package:v6_invoice_mobile/core/auth/auth_controller.dart';
import 'package:v6_invoice_mobile/pages/home_page.dart';
import 'package:v6_invoice_mobile/pages/invoice_list_page.dart';
import 'package:v6_invoice_mobile/pages/invoice_page.dart';
import 'package:v6_invoice_mobile/pages/login_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    //GetPage(
      //name: AppRoutes.SPLASH,
      //page: () => const SplashScreen(),
      //page: () => const V6SplashScreen(),
      //page: () => const EnhancedSplashScreen(),
      //page: () => const ModernV6SplashScreen(),
      //binding: AppBinding(),
    //),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
      binding: AppBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN_PAGE,
      page: () => const LoginPage(),
      binding: AppBinding(),
    ),
    // GetPage(
    //   name: AppRoutes.BUSINESS_UNIT_SELECTION,
    //   page: () => const BusinessUnitSelectionScreen(),
    //   binding: AppBinding(),
    // ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomePage(),
      binding: AppBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SALE_ORDER,
      page: () => InvoiceListPage(),
      binding: AppBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // GetPage(
    //   name: AppRoutes.SALE_ORDER,
    //   page: () => InvoicePage(),
    //   binding: AppBinding(),
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_RECEIPT_LIST,
    //   page: () => const InventoryReceiptListScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_RECEIPT_DETAIL,
    //   page: () => const InventoryReceiptDetailScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_INSPECTION_LIST,
    //   page: () => const InventoryInspectionListScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_INSPECTION_DETAIL,
    //   page: () => const InventoryInspectionDetailScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.QRCODE_SCANNER,
    //   page: () => const QRScannerScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_ISSUE_LIST,
    //   page: () => const InventoryIssueListScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_ISSUE_DETAIL,
    //   page: () => const InventoryIssueDetailScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_TRANSFER_LIST,
    //   page: () => const InventoryTransferListScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_TRANSFER_DETAIL,
    //   page: () => const InventoryTransferDetailScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.TRANSACTION_HISTORY,
    //   page: () => const TransactionHistoryScreen(),
    //   bindings: [AppBinding(), ReportBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_HISTORY,
    //   page: () => const InventoryHistoryScreen(),
    //   bindings: [AppBinding(), ReportBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_POSITION_REPORT,
    //   page: () => const InventoryPositionReportScreen(),
    //   bindings: [AppBinding(), ReportBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.INVENTORY_SCAN_DETAIL,
    //   page: () {
    //     final args = Get.arguments;
    //     final map = args is Map ? args : <String, dynamic>{};
    //     return InventoryScanDetailScreen(
    //       vtTonKho: map['vtTonKho'] as String?,
    //       maKho: map['maKho'] as String?,
    //       maViTri: map['maViTri'] as String?,
    //       maVt: map['maVt'] as String?,
    //       fromDate: map['fromDate'] as String?,
    //       toDate: map['toDate'] as String?,
    //       conditionSd: map['conditionSd'] as String?,
    //     );
    //   },
    //   bindings: [AppBinding(), ReportBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.PROFILE,
    //   page: () => const ProfileScreen(),
    //   bindings: [AppBinding(), ProfileBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.PROFILE_BUSINESS_UNIT_SELECTION,
    //   page: () => const profile_business_unit.BusinessUnitSelectionScreen(),
    //   bindings: [AppBinding(), ProfileBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.PROFILE_FAB_ACTION_SELECTION,
    //   page: () => const FabActionSelectionScreen(),
    //   bindings: [AppBinding(), ProfileBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
    // GetPage(
    //   name: AppRoutes.CUSTOMER_SELECTION,
    //   page: () => const CustomerSelectionScreen(),
    //   bindings: [AppBinding(), QRCodeBinding()],
    //   middlewares: [AuthMiddleware()],
    // ),
  ];
}

// Middleware to protect routes
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    if (AppSession.token == null || AppSession.token!.isEmpty){// !authController.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }
    return null;
  }
}
