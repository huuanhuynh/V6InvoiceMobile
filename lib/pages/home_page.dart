import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v6_invoice_mobile/core/auth/auth_controller.dart';
import 'package:v6_invoice_mobile/core/utils/qr_code_utils.dart';
import 'package:v6_invoice_mobile/pages/login_page.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/config/app_colors.dart';
//import '../../../core/utils/qr_code_utils.dart';
//import '../../auth/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final AuthController _authController = Get.find<AuthController>();
  late AnimationController _headerAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Header animations
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    );

    //_authController.ensureBusinessUnitsLoaded();
    _headerAnimationController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      // Center button (QR Scanner) - handled by FAB
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on index
    switch (index) {
      case 0:
        // Home - already here, just update selection
        break;
      case 1:
        // Offers/Promotions
        Get.snackbar('Thông báo', 'Chức năng ưu đãi đang phát triển');
        break;
      case 3:
        // Transaction history
        Get.toNamed(AppRoutes.TRANSACTION_HISTORY);
        break;
      case 4:
        // Profile/Settings
        Get.toNamed(AppRoutes.PROFILE);
        break;
    }
  }

  Future<void> _openInventoryScanDetail() async {
    final scanned = await Get.toNamed(
      AppRoutes.QRCODE_SCANNER,
      arguments: {'mode': 'inventory_scan_detail'},
    );

    if (scanned is! String || scanned.isEmpty) {
      return;
    }

    final extracted = extractScannedQRCode(scanned);
    if (extracted == null) {
      Get.snackbar(
        'Lỗi',
        'Dữ liệu QR code không hợp lệ. Định dạng phải là: maVt|location|warehouse|identifier',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(
      AppRoutes.INVENTORY_SCAN_DETAIL,
      arguments: {
        'maKho': extracted.maKho,
        'maViTri': extracted.maViTri,
        'maVt': extracted.maVt,
        'vtTonKho': extracted.maViTri,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // Expand header height slightly to account for varying status bar padding.
    final double expandedHeight = 145 + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.95),
                          AppColors.secondary.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Decorative shapes in background
                        Positioned(
                          top: -60,
                          right: -60,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: 200,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: -40,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ),
                        // Wave pattern
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: CustomPaint(
                            size: const Size(double.infinity, 40),
                            painter: WavePainter(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Main content
                        Positioned.fill(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minWidth: constraints.maxWidth,
                            maxWidth: constraints.maxWidth,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    // Top row with logo and menu
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ScaleTransition(
                                          scale: _scaleAnimation,
                                          child: Row(
                                            children: [
                                              // Logo with glassmorphism effect
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.1),
                                                      blurRadius: 20,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: Image.asset(
                                                    'assets/images/launcher_icon.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // App name and tagline
                                              FadeTransition(
                                                opacity: _fadeAnimation,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'V6 Mobile',
                                                      style: TextStyle(
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.3),
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Giải pháp quản lý kho & bán hàng',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Notification icon
                                        FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Transform.translate(
                                            offset: const Offset(5, -10),
                                            child: Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .notifications_outlined,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                  Positioned(
                                                    right: 10,
                                                    top: 6,
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors
                                                                .redAccent,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Welcome message
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Text(
                                          //   'Đơn vị:',
                                          //   style: TextStyle(
                                          //     fontSize: 18,
                                          //     fontWeight: FontWeight.bold,
                                          //     color: Colors.white,
                                          //     //letterSpacing: 0.3,
                                          //   ),
                                          // ),
                                          // const SizedBox(height: 6),
                                          Obx(() {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 35,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.35),
                                                      width: 0.7,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.apartment_rounded,
                                                    size: 25,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    _authController
                                                        .businessUnitName
                                                        .value,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              collapseMode: CollapseMode.parallax,
            ),
            // Collapsed app bar title
            title: AnimatedOpacity(
              opacity:
                  0.0, // Will be controlled by scroll position in a real implementation
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/launcher_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'V6 Mobile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Quick stats cards
          // SliverToBoxAdapter(
          //   child: Container(
          //     constraints: const BoxConstraints(minHeight: 90),
          //     margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: _buildStatsCard(
          //             icon: Icons.inventory_2_outlined,
          //             title: 'Tồn kho',
          //             value: '1,234',
          //             color: Colors.blue,
          //             onTap: () => Get.toNamed(AppRoutes.INVENTORY_HISTORY),
          //           ),
          //         ),
          //         const SizedBox(width: 10),
          //         Expanded(
          //           child: _buildStatsCard(
          //             icon: Icons.trending_up,
          //             title: 'Doanh thu',
          //             value: '45.6M',
          //             color: Colors.green,
          //             onTap: () => Get.snackbar(
          //               'Thông báo',
          //               'Chức năng đang phát triển',
          //             ),
          //           ),
          //         ),
          //         const SizedBox(width: 10),
          //         Expanded(
          //           child: _buildStatsCard(
          //             icon: Icons.receipt_long_outlined,
          //             title: 'Đơn hàng',
          //             value: '156',
          //             color: Colors.orange,
          //             onTap: () => Get.snackbar(
          //               'Thông báo',
          //               'Chức năng đang phát triển',
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // Main content sections
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Inventory Management Section with new design
                _buildModernSection(
                  title: 'Quản lý kho',
                  icon: Icons.warehouse_outlined,
                  crossAxisCount: 4,
                  items: [
                    _buildModernServiceItem(
                      icon: Icons.search_sharp,
                      label: 'Phiếu kiểm kho',
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        Get.toNamed(AppRoutes.INVENTORY_INSPECTION_LIST);
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Phiếu xuất kho',
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Get.toNamed(AppRoutes.INVENTORY_ISSUE_LIST);
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.archive_outlined,
                      label: 'Phiếu nhập kho',
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Get.toNamed(AppRoutes.INVENTORY_RECEIPT_LIST);
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.compare_arrows_outlined,
                      label: 'Phiếu chuyển kho',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Get.toNamed(AppRoutes.INVENTORY_TRANSFER_LIST);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // thêm phần chứng từ
                _buildModernSection(
                  title: 'Quản lý chứng từ',
                  icon: Icons.folder_open_outlined,
                  crossAxisCount: 4,
                  items: [
                    // _buildModernServiceItem(
                    //   icon: Icons.receipt_long_outlined,
                    //   label: 'Hóa đơn bán hàng',
                    //   color: const Color(0xFFEF4444),
                    //   onTap: () {
                    //     Get.toNamed(AppRoutes.INVOICE_LIST);
                    //   },
                    // ),
                    _buildModernServiceItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Đơn đặt hàng',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Get.toNamed(AppRoutes.SALE_ORDER);
                      },
                    ),
                    // _buildModernServiceItem(
                    //   icon: Icons.point_of_sale,
                    //   label: 'Bán hàng nhanh',
                    //   color: const Color(0xFF8B5CF6),
                    //   onTap: () {
                    //     Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                    //   },
                    // ),
                    // _buildModernServiceItem(
                    //   icon: Icons.receipt_outlined,
                    //   label: 'Phiếu thu',
                    //   color: const Color(0xFFF59E0B),
                    //   onTap: () {
                    //     Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 12),

                // // Sales & Export Section with new design
                // _buildModernSection(
                //   title: 'Bán hàng & Xuất kho',
                //   icon: Icons.point_of_sale_outlined,
                //   items: [
                //     _buildModernServiceItem(
                //       icon: Icons.history_outlined,
                //       label: 'Lịch sử tồn kho',
                //       color: const Color(0xFFF59E0B),
                //       onTap: () {
                //         Get.toNamed(AppRoutes.INVENTORY_HISTORY);
                //       },
                //     ),
                //     _buildModernServiceItem(
                //       icon: Icons.point_of_sale,
                //       label: 'Bán hàng',
                //       color: const Color(0xFF8B5CF6),
                //       onTap: () {
                //         Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                //       },
                //     ),
                //     _buildModernServiceItem(
                //       icon: Icons.receipt_long_outlined,
                //       label: 'Hóa đơn',
                //       color: const Color(0xFFEF4444),
                //       onTap: () {
                //         Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                //       },
                //     ),
                //     _buildModernServiceItem(
                //       icon: Icons.shopping_cart_outlined,
                //       label: 'Đơn hàng',
                //       color: const Color(0xFF3B82F6),
                //       onTap: () {
                //         Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                //       },
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),

                // Reports Section with new design
                _buildModernSection(
                  title: 'Báo cáo & Thống kê',
                  icon: Icons.analytics_outlined,
                  items: [
                    _buildModernServiceItem(
                      icon: Icons.qr_code_scanner_outlined,
                      label: 'Quét chi tiết tồn kho',
                      color: const Color(0xFF0EA5E9),
                      onTap: _openInventoryScanDetail,
                    ),
                    _buildModernServiceItem(
                      icon: Icons.table_chart_outlined,
                      label: 'Tồn kho theo vị trí',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Get.toNamed(AppRoutes.INVENTORY_POSITION_REPORT);
                      },
                    ),
                    // _buildModernServiceItem(
                    //   icon: Icons.pie_chart_outline,
                    //   label: 'Báo cáo',
                    //   color: const Color(0xFFF97316),
                    //   onTap: () {
                    //     Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                    //   },
                    // ),
                    // _buildModernServiceItem(
                    //   icon: Icons.trending_up_outlined,
                    //   label: 'Lợi nhuận',
                    //   color: const Color(0xFF22C55E),
                    //   onTap: () {
                    //     Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                    //   },
                    // ),
                    _buildModernServiceItem(
                      icon: Icons.download_outlined,
                      label: 'Xuất báo cáo',
                      color: const Color(0xFFA855F7),
                      onTap: () {
                        Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // System Management Section with new design
                _buildModernSection(
                  title: 'Quản lý hệ thống',
                  icon: Icons.settings_outlined,
                  items: [
                    _buildModernServiceItem(
                      icon: Icons.people_outline,
                      label: 'Nhân viên',
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.business_outlined,
                      label: 'Nhà cung cấp',
                      color: const Color(0xFF059669),
                      onTap: () {
                        Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.settings,
                      label: 'Cài đặt',
                      color: const Color(0xFF64748B),
                      onTap: () {
                        Get.toNamed(AppRoutes.PROFILE);
                      },
                    ),
                    _buildModernServiceItem(
                      icon: Icons.apps_outlined,
                      label: 'Dịch vụ',
                      color: const Color(0xFFDC2626),
                      onTap: () {
                        Get.snackbar('Thông báo', 'Chức năng đang phát triển');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final fabAction = _authController.fabAction.value;
        return Container(
          margin: const EdgeInsets.only(top: 20),
          child: FloatingActionButton(
            onPressed: () {
              Get.toNamed(fabAction.route);
            },
            backgroundColor: AppColors.primary,
            elevation: 8,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(fabAction.icon, size: 28, color: Colors.white),
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: BottomAppBar(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Trang chủ',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.local_offer_outlined,
                    selectedIcon: Icons.local_offer,
                    label: 'Ưu đãi',
                    index: 1,
                  ),
                  const SizedBox(width: 70), // Space for FAB
                  _buildBottomNavItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'Giao dịch',
                    index: 3,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Tôi',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
    int crossAxisCount = 4,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          //const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildModernServiceItem({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.03),
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: iconWidget ?? Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom wave painter for decorative background
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
