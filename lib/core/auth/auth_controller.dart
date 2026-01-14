import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:v6_invoice_mobile/models/fab_action.dart';
import 'package:v6_invoice_mobile/models/key_value_pair.dart';
import 'package:v6_invoice_mobile/services/api_exceptions.dart';
import 'package:v6_invoice_mobile/services/auth_api_service.dart';
import '../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthApiService _authApiService = Get.find<AuthApiService>();
  final storage = GetStorage();

  // Observable variables
  var isAuthenticated = false.obs;
  var isLoading = false.obs;
  var businessUnit = ''.obs;
  var businessUnitName = ''.obs;
  var username = ''.obs;
  var accessToken = ''.obs;

  // Two-step authentication variables
  var tempToken = ''.obs;
  var availableBusinessUnits = <KeyValuePair>[].obs;

  // FAB action preference
  var fabAction = Rx<FabAction>(FabAction.defaultAction);

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // Check if user is already logged in
  void checkAuthStatus() {
    final token = storage.read('access_token');
    final savedUsername = storage.read('username');
    final savedBusinessUnit = storage.read('maDvcs');
    final savedBusinessUnitName = storage.read('maDvcsName');
    final savedBusinessUnits = storage.read('businessUnits');
    final savedFabActionId = storage.read('fab_action_id');

    if (token != null && token.isNotEmpty) {
      accessToken.value = token;
      username.value = savedUsername ?? '';
      businessUnit.value = savedBusinessUnit ?? '';
      businessUnitName.value = savedBusinessUnitName ?? '';
      isAuthenticated.value = true;

      // Load business units from storage if available
      if (savedBusinessUnits != null && savedBusinessUnits is List) {
        availableBusinessUnits.value = savedBusinessUnits
            .map((item) => KeyValuePair.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Fallback: resolve display name from cached list if name not stored
      if (businessUnitName.value.isEmpty &&
          businessUnit.value.isNotEmpty &&
          availableBusinessUnits.isNotEmpty) {
        final unit = availableBusinessUnits.firstWhere(
          (unit) => unit.key == businessUnit.value,
          orElse: () => availableBusinessUnits.first,
        );
        businessUnitName.value = unit.value;
      }

      // Load FAB action preference
      if (savedFabActionId != null && savedFabActionId.isNotEmpty) {
        final action = FabAction.findById(savedFabActionId);
        if (action != null) {
          fabAction.value = action;
        }
      }
    }
  }

  // Ensure business units list is loaded (used outside login flow)
  void ensureBusinessUnitsLoaded() {
    if (availableBusinessUnits.isNotEmpty) return;

    final savedBusinessUnits = storage.read('businessUnits');
    if (savedBusinessUnits != null && savedBusinessUnits is List) {
      availableBusinessUnits.value = savedBusinessUnits
          .map(
            (item) => KeyValuePair.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    }
  }

  // Step 1: Login with username and password
  // The service layer will:
  // 1. Call login API to get access_token
  // 2. Use the token to fetch business units
  // 3. Return both in the response
  Future<void> loginStep1(String usernameInput, String password) async {
    try {
      isLoading.value = true;

      // Call service which handles login + fetching business units
      final response = await _authApiService.loginStep1(
        usernameInput,
        password,
      );

      // Extract access token (returned from login API)
      final accessTokenValue = response['access_token'];
      if (accessTokenValue == null || accessTokenValue.isEmpty) {
        throw Exception('No access token received from login');
      }

      // Store access_token and username in localStorage for persistence
      await storage.write('access_token', accessTokenValue);
      await storage.write('username', usernameInput);

      // Update state
      tempToken.value = accessTokenValue;
      accessToken.value = accessTokenValue;
      username.value = usernameInput;

      // Extract business units (fetched using the access_token)
      final businessUnitsData = response['businessUnits'];
      if (businessUnitsData == null) {
        throw Exception('No business units data received');
      }

      // Parse business units list
      final businessUnitsList = businessUnitsData as List;
      if (businessUnitsList.isEmpty) {
        Get.snackbar(
          'Thông báo',
          'Không có đơn vị cơ sở khả dụng cho tài khoản này.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      availableBusinessUnits.value = businessUnitsList
          .map((item) => KeyValuePair.fromJson(item as Map<String, dynamic>))
          .toList();

      // Save business units to storage for later use
      await storage.write('businessUnits', businessUnitsData);

      // Navigate to business unit selection screen
      Get.toNamed(AppRoutes.BUSINESS_UNIT_SELECTION);
    } catch (e) {
      if (e is NetworkException || e.toString().contains('Network error')) {
        Get.snackbar(
          'Lỗi mạng',
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Đăng nhập không thành công. Vui lòng kiểm tra tài khoản và thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Select business unit
  Future<void> selectBusinessUnit(String baseUnitCode) async {
    try {
      isLoading.value = true;

      final response = await _authApiService.selectBusinessUnit(
        tempToken.value,
        baseUnitCode,
      );

      final token = response['access_token'] ?? response['token'];

      if (token != null) {
        final unitName = _resolveBusinessUnitName(baseUnitCode);

        // Save business unit to storage
        // (access_token and username are already saved from step 1)
        await storage.write('maDvcs', baseUnitCode);
        await storage.write('maDvcsName', unitName);

        // Update state
        businessUnit.value = baseUnitCode;
        businessUnitName.value = unitName;
        isAuthenticated.value = true;

        // Clear temporary data
        tempToken.value = '';

        // Navigate to home
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        throw Exception('No token received');
      }
    } catch (e) {
      if (e is NetworkException || e.toString().contains('Network error')) {
        Get.snackbar(
          'Lỗi mạng',
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Chọn đơn vị không thành công. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update business unit (for switching business unit after login)
  Future<void> updateBusinessUnit(
    String baseUnitCode, {
    bool navigateBack = false,
  }) async {
    try {
      isLoading.value = true;

      // Save the new business unit to storage
      await storage.write('maDvcs', baseUnitCode);
      await storage.write('maDvcsName', _resolveBusinessUnitName(baseUnitCode));

      // Update state
      businessUnit.value = baseUnitCode;
      businessUnitName.value = _resolveBusinessUnitName(baseUnitCode);

      if (navigateBack) {
        Get.back();
      }

      // Get.snackbar(
      //   'Thành công',
      //   'Đã chuyển đơn vị kinh doanh',
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 2),
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chuyển đơi vị. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update FAB action preference
  Future<void> updateFabAction(FabAction action, {bool showSnackbar = true}) async {
    try {
      // Save the new FAB action to storage
      await storage.write('fab_action_id', action.id);

      // Update state
      fabAction.value = action;

      if (showSnackbar) {
        Get.snackbar(
          'Thành công',
          'Đã cập nhật hành động nút nổi',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (showSnackbar) {
        Get.snackbar(
          'Lỗi',
          'Không thể cập nhật hành động. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      rethrow;
    }
  }

  // Clear temporary authentication state (called when user goes back)
  Future<void> clearTempAuthState() async {
    // Clear in-memory temporary data
    tempToken.value = '';
    availableBusinessUnits.clear();
    username.value = '';
    accessToken.value = '';
    businessUnitName.value = '';

    // Remove stored credentials since user didn't complete the flow
    await storage.remove('access_token');
    await storage.remove('username');
    await storage.remove('maDvcsName');
  }

  // Logout function
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authApiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API error: $e');
    } finally {
      // Clear storage
      await storage.remove('access_token');
      await storage.remove('username');
      await storage.remove('maDvcs');
      await storage.remove('maDvcsName');

      // Clear state
      accessToken.value = '';
      username.value = '';
      businessUnit.value = '';
      businessUnitName.value = '';
      isAuthenticated.value = false;
      isLoading.value = false;

      // Navigate to login - use Get.offAllNamed to clear all routes
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  String _resolveBusinessUnitName(String baseUnitCode) {
    if (availableBusinessUnits.isEmpty) return baseUnitCode;

    final unit = availableBusinessUnits.firstWhere(
      (item) => item.key == baseUnitCode,
      orElse: () => availableBusinessUnits.first,
    );

    return unit.value;
  }
}
