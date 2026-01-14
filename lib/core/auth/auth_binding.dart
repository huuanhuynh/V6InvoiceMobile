import 'package:get/get.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
import 'package:v6_invoice_mobile/services/auth_api_service.dart';
import 'auth_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Global singletons (idempotent)
    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    }
    // if (!Get.isRegistered<LookupApiService>()) {
    //   Get.lazyPut<LookupApiService>(() => LookupApiService(), fenix: true);
    // }
    if (!Get.isRegistered<AuthApiService>()) {
      Get.lazyPut<AuthApiService>(() => AuthApiService(), fenix: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
