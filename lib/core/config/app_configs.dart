import 'package:flutter/material.dart';

/// Shared application-level configuration values.
class AppConfigs {
  /// Consistent font size for AppBar titles across the app.
  static const double appBarTitleFontSize = 20.0;

  static const String version = "1.1.1";

  /// Font weight used alongside the shared app bar title size.
  static const FontWeight appBarTitleFontWeight = FontWeight.w600;

  /// Reusable text style for AppBar titles.
  static const TextStyle appBarTitleTextStyle = TextStyle(
    fontSize: appBarTitleFontSize,
    fontWeight: appBarTitleFontWeight,
  );

  /// Invoice type border colors to differentiate each invoice type visually.
  /// ARC - Inventory Inspection (Teal)
  static const Color invoiceBorderArc = Color(0xFF00897B);

  /// IND - Inventory Receipt (Green)
  static const Color invoiceBorderInd = Color(0xFF43A047);

  /// IXA - Inventory Issue (Orange)
  static const Color invoiceBorderIxa = Color(0xFFEF6C00);

  /// IXB - Inventory Transfer (Purple)
  static const Color invoiceBorderIxb = Color(0xFF7B1FA2);

  /// Border width for invoice type decoration.
  static const double invoiceBorderWidth = 3.0;
}
