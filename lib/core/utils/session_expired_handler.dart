import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:v6_invoice_mobile/core/auth/auth_controller.dart';
import '../config/app_colors.dart';

class SessionExpiredHandler {
  static bool _isDialogShowing = false;

  static Future<void> promptReLogin() async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Phiên đăng nhập đã hết hạn'),
          content: const Text(
            'Vui lòng đăng nhập lại để tiếp tục sử dụng ứng dụng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Để sau'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final auth = Get.find<AuthController>();
                  await auth.logout();
                } catch (_) {
                  // Fallback navigate to login if AuthController not available
                  Get.offAllNamed('/login');
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Đăng nhập lại'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      _isDialogShowing = false;
    }
  }
}
