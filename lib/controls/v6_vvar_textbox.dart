// v6_lookup_field.dart

import 'package:flutter/material.dart';
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/core/config/app_colors.dart';
import 'package:v6_invoice_mobile/pages/catalog_page.dart';
import 'package:v6_invoice_mobile/h.dart';

// Định nghĩa typedef cho onChanged để tương thích với hàm _handleFieldChange
typedef ValueChangedCallback = void Function(V6VvarTextBox sender, String newValue, bool isLookup);
typedef VvarLookedCallback = void Function(V6VvarTextBox sender, Map<String, dynamic> selectedData);

class V6VvarTextBox extends StatefulWidget {
  // --- THUỘC TÍNH MỚI/CẤU HÌNH ---
  final String label; // Tiêu đề hiển thị (caption)
  final String? vvar; // Mã tra cứu danh mục (Mã VVAR)
  final String fieldKey; // Tên trường lấy value
  final String ftype; // Kiểu dữ liệu (N2, C0,...)
  final bool isRequired; // Bắt buộc nhập (notempty)
  final bool noFilter; // Không lọc khi tra cứu
  final bool enabled;
  
  // --- THUỘC TÍNH CỦA TEXTFIELD/FORM FIELD ---
  final TextBoxC controller;
  final ValueChangedCallback? onChanged;
  final VvarLookedCallback? onLooked;
  final Map<String, dynamic>? configTables;
  
  V6VvarTextBox({
    super.key,
    required this.label,
    this.vvar,
    required this.fieldKey,
    required this.ftype,
    this.isRequired = false,
    this.noFilter = false,
    this.enabled = true, // Giá trị mặc định là true
    required this.controller,
    this.onChanged,
    this.onLooked,
    this.configTables
  });
  
  bool get haveVvar => vvar != null && vvar!.isNotEmpty;

  @override
  State<V6VvarTextBox> createState() => _V6VvarTextBoxState();
}

class _V6VvarTextBoxState extends State<V6VvarTextBox> {

  // Hàm mở CatalogPage và nhận kết quả (đã chuyển logic từ ItemEditPage sang)
  Future<void> _openCatalogLookup() async {
    // 1. Kiểm tra fvvar trước
    if (!widget.haveVvar) {
      return; // Không phải trường lookup
    }
    
    final filterValue = widget.noFilter ? null : widget.controller.text.trim();
    // Mở CatalogPage và đợi kết quả (selectedItem)
    final selectResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogPage(
          fvvar: widget.vvar!,
          type: '2', 
          filterValue: filterValue,
          advance: widget.controller.advanceFilter ?? '',
        ),
      ),
    );

    // Xử lý kết quả trả về
    if (selectResult != null) {
      Map<String, dynamic> selectedData = selectResult['selectedData'];
      Map<String, dynamic>? lookupInfo = selectResult['lookupInfo'];
      widget.controller.lookupInfo = lookupInfo;
      widget.controller.data = selectedData;
      String valueField = lookupInfo == null ? widget.fieldKey : (lookupInfo['vvalue'] ?? widget.fieldKey);
      final valueToSet = H.objectToString(H.getValue(selectedData, valueField, defaultValue: null));
      widget.controller.text = valueToSet;
      widget.controller.dataKey = valueToSet;

      // Gọi onLooked onChanged để thông báo cho Widget cha (ItemEditPage) tính toán lại
      if (widget.onLooked != null) {
        widget.onLooked!(widget, widget.controller.data!);
      }
      if (widget.onChanged != null) {
        widget.onChanged!(widget, widget.controller.text, true);
      }
    }
  }

  // VALIDATOR 
  String? _validator(String? v) {
    if (widget.isRequired) {
      if (v == null || v.trim().isEmpty) {
        return 'Trường ${widget.label} không được bỏ trống.';
      }
      
      // Validation kiểu số
      final isNumeric = widget.ftype.toUpperCase().startsWith('N');
      if (isNumeric) {
        // Thay thế dấu phẩy bằng dấu chấm để tryParse đúng
        final cleanValue = v.replaceAll(',', '.');
        if (double.tryParse(cleanValue) == null) {
          return 'Trường ${widget.label} phải là số.';
        }
      }
    }
    return null;
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    // Xác định icon tra cứu
    final lookupIcon = (widget.haveVvar)
        ? IconButton(
            icon: const Icon(Icons.search),
            onPressed: widget.enabled ? _openCatalogLookup : null,
          )
        : null;

    // Xác định kiểu bàn phím
    final isNumeric = widget.ftype.toUpperCase().startsWith('N');
    
    return TextFormField(
      enabled: widget.enabled,
      controller: widget.controller,
      onChanged: (value) => widget.onChanged?.call(widget, value, false),
      validator: _validator,
      
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.secondary),
        contentPadding: const EdgeInsets.fromLTRB(5, 2, 2, 2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.onPrimary,
        suffixIcon: lookupIcon, // lookup icon
        suffixText: widget.isRequired ? '*' : null, 
        suffixStyle: widget.isRequired ? const TextStyle(color: Colors.red) : null,
      ),
    );
  }
}