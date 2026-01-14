import 'package:flutter/material.dart';
import 'package:v6_invoice_mobile/core/routes/app_routes.dart';

class FabAction {
  final String id;
  final String label;
  final String route;
  final IconData icon;

  const FabAction({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
  });

  // Available FAB actions
  static const List<FabAction> availableActions = [
    FabAction(
      id: 'inventory_inspection',
      label: 'Phiếu Kiểm Kho',
      route: AppRoutes.INVENTORY_INSPECTION_LIST,
      icon: Icons.search_sharp,
    ),
    FabAction(
      id: 'inventory_receipt',
      label: 'Phiếu Nhập Kho',
      route: AppRoutes.INVENTORY_RECEIPT_LIST,
      icon: Icons.archive_outlined,
    ),
    FabAction(
      id: 'inventory_issue',
      label: 'Phiếu Xuất Kho',
      route: AppRoutes.INVENTORY_ISSUE_LIST,
      icon: Icons.local_shipping_outlined,
    ),
    FabAction(
      id: 'inventory_transfer',
      label: 'Phiếu Chuyển Kho',
      route: AppRoutes.INVENTORY_TRANSFER_LIST,
      icon: Icons.compare_arrows_outlined,
    ),
  ];

  // Find action by ID
  static FabAction? findById(String id) {
    try {
      return availableActions.firstWhere((action) => action.id == id);
    } catch (e) {
      return null;
    }
  }

  // Default action
  static FabAction get defaultAction => availableActions.first;

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'route': route};
  }

  factory FabAction.fromJson(Map<String, dynamic> json) {
    final action = findById(json['id']);
    return action ?? defaultAction;
  }
}
