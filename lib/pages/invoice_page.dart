// lib/pages/invoice_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/controls/v6_vvar_textbox.dart';
import 'package:v6_invoice_mobile/core/config/app_colors.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/invoice_item.dart';
import 'package:v6_invoice_mobile/models/scan_item.dart';
import 'package:v6_invoice_mobile/screens/qr_scan_screen.dart';
import '../repository.dart';
import 'item_edit_page.dart';
//import 'dart:math';

enum InvoiceMode { view, edit, add }

class InvoicePage extends StatefulWidget {
  final String mact; // ví dụ: SOH
  final Invoice _invoice; // nếu null => tạo mới
  final InvoiceMode mode;

  const InvoicePage({
    super.key,
    required this.mact,
    required Invoice invoice,
    required this.mode,    
  }): _invoice = invoice;

  static const routeName = '/invoice';

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}


// Định nghĩa các key cho Map Controllers
enum ControlField { so_ct, ngay_ct, ma_kh, ma_sonb ,ten_kh, nguoi_dai_dien, dia_chi, dien_giai, ma_so_thue, thong_tin_them, status}
enum InvoiceStatus { A, B, C } // Giả định các trạng thái

class _InvoicePageState extends State<InvoicePage>
    with TickerProviderStateMixin {
  late Invoice invoice;
  late InvoiceMode mode;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // controllers
  final Map<ControlField, TextBoxC> _controllers = {
    ControlField.so_ct: TextBoxS(fieldName: 'SO_CT'),
    ControlField.ngay_ct: TextBoxD(fieldName: 'NGAY_CT', dateFormat: 'dd/MM/yyyy'),
    ControlField.ma_kh: TextBoxS(fieldName: 'MA_KH'),
    ControlField.ma_sonb: TextBoxS(fieldName: 'MA_SONB'),
    ControlField.ten_kh: TextBoxS(fieldName: 'TEN_KH'),
    ControlField.nguoi_dai_dien: TextBoxS(fieldName: 'ONG_BA'),
    ControlField.dia_chi: TextBoxS(fieldName: 'DIA_CHI'),
    ControlField.ma_so_thue: TextBoxS(fieldName: 'MA_SO_THUE'),
    ControlField.thong_tin_them: TextBoxS(fieldName: 'THONG_TIN_THEM'),
    //ControlField.ghi_chu: TextBoxS(fieldName: 'GHI_CHU'),
    ControlField.dien_giai: TextBoxS(fieldName: 'DIEN_GIAI'),
    ControlField.status: TextBoxS(fieldName: 'TRANG_THAI'),
  };
  
  //InvoiceStatus _status = InvoiceStatus.A; // Trạng thái chứng từ

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    // khởi tạo tab controller
    _tabController = TabController(length: 3, vsync: this);
    invoice = widget._invoice;
    for (var ctrl in _controllers.values) {
      ctrl.loadValueFrom(invoice);
    }
    
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    for (var ctrl in _controllers.values) {
      ctrl.setValueTo(invoice);
    }
    final repo = context.read<InvoiceRepository>();
    try {
      if (widget.mode == InvoiceMode.add) {
        await repo.addInvoice(invoice);
      } else {
        await repo.updateInvoice(invoice);
      }
      
      // THÀNH CÔNG: Chỉ đổi trạng thái và hiển thị SnackBar khi tác vụ thành công
      if (mounted) {
        setState(() => mode = InvoiceMode.view);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu chứng từ thành công!')));
      }
    } catch (error) {
      // 4. LỖI: HIỂN THỊ LỖI và KHÔNG thay đổi trạng thái (mode)
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
              content: Text('Lưu thất bại: ${error.toString()}'),
              backgroundColor: Colors.red,
            ));
        // Trạng thái (mode) vẫn được giữ nguyên (add/edit)
      }
    }
  }

  // Hàm xử lý Scan QR MỚI
  void _scanQR() async {
    // 1. Mở trang quét và sử dụng 'await' để đợi kết quả
    //final result = await Navigator.push(context, QrScanPage());
    final result = await Navigator.push<List<ScanItem>>(
      context,
      MaterialPageRoute(builder: (_) => QrScanScreen()),
    );
    // 2. Kiểm tra và gán kết quả trả về
    if (result != null && result.isNotEmpty) {
      final codeList = result.map((e) => e.code).join(', ');
      final scanedItems = List<InvoiceItem>.empty(growable: true);
      for (var scanItem in result) {
        final item = InvoiceItem(
          id: H.generateId(),
          data: {
            'MA_VT': scanItem.code,
            'TEN_VT': 'Hàng hóa ${scanItem.code}', // Giả định tên hàng, hoặc hàm lookup by code
            'SO_LUONG1': scanItem.quantity,
            //'GIA_NT21': 100000, // Giá giả định  // giá và tiền lấy mặc định theo code.
            //'TIEN_NT2': scanItem.quantity * 100000,
            //'THUE_SUAT': 0.1, // Thuế suất giả định 10%
          },
        );
        scanedItems.add(item);
      }
      setState(() {
        invoice.items.addAll(scanedItems);
      });
      // Tùy chọn: Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã nhận kết quả: $codeList')),
      );
    } else {
      // Xử lý trường hợp người dùng đóng trang mà không nhấn Save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quét mã bị hủy hoặc không có dữ liệu.')),
      );
    }

  }

  void _deleteInvoice() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa chứng từ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<InvoiceRepository>().deleteInvoice(invoice.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Future<void> _pickDate_Old() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _date ?? DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null) setState(() => _date = picked);
  // }
  Future<void> _pickDate() async {
    var ngayCtController = _controllers[ControlField.ngay_ct] as TextBoxD;
    final initialDate = ngayCtController.getDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      ngayCtController.text = H.objectToString(picked, dateFormat: ngayCtController.dateFormat); 
      
      // 2. Không cần gọi setState vì việc cập nhật TextEditingController tự động 
      // làm mới TextFormField.
    }
  }

  void _addItem() async {
    final item = await Navigator.push<InvoiceItem>(
      context,
      MaterialPageRoute(builder: (_) => const ItemEditPage()),
    );
    if (item != null) {
      setState(() {
        invoice.items.add(item);
        _calSummary();
      });
      //context.read<InvoiceRepository>().addItem(invoice.id, item);
    }
  }

  void _editItem(InvoiceItem item) async {
    final result = await Navigator.push<InvoiceItem>(
      context,
      MaterialPageRoute(builder: (_) => ItemEditPage(item: item)),
    );
    if (result != null) {
      setState(() {
        final index = invoice.items.indexOf(item);

        if (index != -1) {
          // Thay thế item cũ bằng item mới (result)
          invoice.items[index] = result; 
          _calSummary();
          // Hoặc nếu bạn muốn đảm bảo tính bất biến tốt hơn (Immutable approach):
          /*
          _invoice = _invoice.copyWith(
            items: List.of(_invoice.items) 
              ..removeAt(index)
              ..insert(index, result),
          );
          */
        }
      });
      //context.read<InvoiceRepository>().updateItem(invoice.id, result);
    }
  }

  void _deleteItem(InvoiceItem item) {
    //context.read<InvoiceRepository>().deleteItem(invoice.id, item.id);
    setState(() {
      invoice.items.removeWhere((it) => it.id == item.id);
      _calSummary();
    });
  }

  void _calSummary() {
    setState(() {
      invoice.calculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    invoice = context
        .watch<InvoiceRepository>()
        .invoices
        .firstWhere((i) => i.id == invoice.id, orElse: () => invoice);

    final title = mode == InvoiceMode.add
        ? 'Thêm chứng từ ${widget.mact}'
        : mode == InvoiceMode.edit
            ? 'Sửa chứng từ ${widget.mact}'
            : 'Xem chứng từ ${widget.mact}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (mode == InvoiceMode.view)
            IconButton(
              onPressed: () => setState(() => mode = InvoiceMode.edit),
              icon: const Icon(Icons.edit),
            ),
          if (mode != InvoiceMode.view)
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _deleteInvoice();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Form thông tin chung
          Form(
            key: _formKey,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Colors.blue,        // màu chữ khi tab được chọn
                  unselectedLabelColor: Colors.black54, // màu chữ khi tab chưa chọn
                  indicatorColor: Colors.blue,    // màu gạch chân chỉ báo tab
                  tabs: const [
                    Tab(text: 'Chung'),
                    Tab(text: 'Khách hàng'),
                    Tab(text: 'Ghi chú'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Chung
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            // Hàng 1: Mã nội bộ và Số chứng từ
                            Row(
                              children: [
                                // Cột 1: Mã số nội bộ
                                Expanded(
                                  child:
                                  V6VvarTextBox(label: 'Mã nội bộ', fieldKey: 'MA_SONB', ftype: 'ftype', controller: _controllers[ControlField.ma_sonb]!,
                                    vvar: 'MA_SONB',
                                    isRequired: true,
                                    enabled: mode != InvoiceMode.view,
                                    onLooked: (sender, selectedItem) {
                                      _controllers[ControlField.so_ct]!.text = H.getValue(selectedItem, 'MA_CTNB', defaultValue: 'NEW_001').toString();  
                                    },
                                    onChanged: (fieldKey, newValue) {
                                      // Xử lý khi mã nội bộ thay đổi (nếu cần)
                                    },
                                  ),
                                ),
                                // Cột 2: Số chứng từ
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[ControlField.so_ct],
                                    decoration: _fieldDecoration('Số chứng từ'),
                                    enabled: mode != InvoiceMode.view,
                                    validator: (v) => v == null || v.isEmpty ? 'Yêu cầu' : null,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Hàng 2: Ngày ct, Mã KH
                            Row(
                              children: [
                                // Cột 1: Ngày chứng từ
                                Expanded(
                                  child: TextFormField(
                                    // Sử dụng TextBoxD Controller
                                    controller: _controllers[ControlField.ngay_ct], 
                                    
                                    // Gán hàm _pickDate cho sự kiện nhấn vào icon Lịch
                                    readOnly: true, // Không cho phép nhập thủ công
                                    onTap: widget.mode == InvoiceMode.view ? null : _pickDate, // Cho phép nhấn nếu không phải chế độ xem
                                    enabled: widget.mode != InvoiceMode.view, // Vô hiệu hóa khi ở chế độ xem
                                    keyboardType: TextInputType.datetime,
                                    decoration: _fieldDecoration('Ngày chứng từ',
                                      // Thêm icon Lịch (Icon Button)
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        // Gọi _pickDate khi nhấn icon
                                        onPressed: widget.mode == InvoiceMode.view ? null : _pickDate, 
                                      ),
                                    ),
                                  ),
                                ),
                                // Cột 2: Mã Khách hàng (Thêm mới)
                                Expanded(
                                  child: V6VvarTextBox(label: 'Mã khách hàng', fieldKey: 'MA_KH', ftype: 'ftype', controller: _controllers[ControlField.ma_kh]!,
                                    vvar: 'MA_KH',
                                    isRequired: true,
                                    enabled: mode != InvoiceMode.view,
                                    onLooked: (sender, selectedItem) {
                                      // Gán tên khách hàng sau khi lookup
                                      final tenKh = H.getValue(selectedItem, 'TEN_KH', defaultValue: '').toString();
                                      _controllers[ControlField.ten_kh]!.text = tenKh;
                                    },
                                    onChanged: (fieldKey, newValue) {
                                      // Xử lý khi mã khách hàng thay đổi (nếu cần)
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Hàng 3: Tên Khách hàng
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _controllers[ControlField.ten_kh],
                                decoration: _fieldDecoration('Tên khách hàng'),
                                enabled: mode != InvoiceMode.view,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Hàng 4: Dropdown Trạng thái
                            DropdownButtonFormField<InvoiceStatus>(
                              decoration: const InputDecoration(
                                labelText: 'Trạng thái',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                              ),
                              initialValue: InvoiceStatus.values.firstWhere(
                                // Tìm enum khớp với chuỗi đang lưu trong controller, nếu không tìm thấy thì dùng giá trị mặc định (first)
                                (status) => status.name == _controllers[ControlField.status]!.text,
                                orElse: () => InvoiceStatus.values.first, 
                              ),
                              onChanged: mode == InvoiceMode.view ? null : (v) => setState(() => _controllers[ControlField.status]!.text=v!.name),
                              items: InvoiceStatus.values.map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      // Tab Khách hàng
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(12), // Tăng padding lên 12 để đẹp hơn
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // Đảm bảo các trường chiếm toàn bộ chiều rộng
                          children: [
                            

                            // 2. Ông bà (Người đại diện)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _controllers[ControlField.nguoi_dai_dien], // Ví dụ: bạn cần định nghĩa Tab1Field.nguoi_dai_dien
                                decoration: const InputDecoration(labelText: 'Người đại diện', border: OutlineInputBorder()),
                                enabled: mode != InvoiceMode.view,
                              ),
                            ),

                            // 3. Địa chỉ
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _controllers[ControlField.dia_chi], // Ví dụ: bạn cần định nghĩa Tab1Field.dia_chi
                                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
                                enabled: mode != InvoiceMode.view,
                                maxLines: 3, // Cho phép nhập nhiều dòng cho Địa chỉ
                              ),
                            ),

                            // 4. Mã số thuế
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _controllers[ControlField.ma_so_thue], // Ví dụ: bạn cần định nghĩa Tab1Field.ma_so_thue
                                decoration: const InputDecoration(labelText: 'Mã số thuế', border: OutlineInputBorder()),
                                enabled: mode != InvoiceMode.view,
                                keyboardType: TextInputType.number,
                              ),
                            ),

                            // 5. Thông tin thêm
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _controllers[ControlField.thong_tin_them], // Ví dụ: bạn cần định nghĩa Tab1Field.thong_tin_them
                                decoration: const InputDecoration(labelText: 'Thông tin thêm', border: OutlineInputBorder()),
                                enabled: mode != InvoiceMode.view,
                                maxLines: 5, // Cho phép nhập nhiều dòng cho Thông tin thêm
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tab diễn giải
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: TextFormField(
                          controller: _controllers[ControlField.dien_giai],
                          decoration:
                              const InputDecoration(labelText: 'Diễn giải', border: OutlineInputBorder()),
                          enabled: mode != InvoiceMode.view,
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Danh sách chi tiết hàng hóa
          Expanded(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Chi tiết hàng hóa'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mode != InvoiceMode.view) // Chỉ hiện khi ở chế độ edit/add
                        IconButton(onPressed: _scanQR, icon: const Icon(Icons.qr_code_scanner)),
                      IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                Expanded(
                  child: invoice.items.isEmpty
                      ? const Center(child: Text('Chưa có chi tiết.'))
                      : ListView.builder(
                          itemCount: invoice.items.length,
                          itemBuilder: (context, idx) {
                            final it = invoice.items[idx];
                            return ListTile(
                              title:
                                  Text('${it.getString("MA_VT")} — ${it.getString("TEN_VT")}'),
                              subtitle: Text(
                                  'Đơn giá: ${it.getDouble("GIA_NT21").toStringAsFixed(0)} × ${it.getDouble("SO_LUONG1").toStringAsFixed(2)} = ${it.getDouble("TIEN_NT2").toStringAsFixed(0)}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _editItem(it);
                                  if (v == 'delete') _deleteItem(it);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Sửa')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Xóa')),
                                ],
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('Chi tiết ${it['MA_VT']}'),
                                    content: Text(
                                        'Mô tả: ${it.getString("TEN_VT")}\nĐơn giá: ${it.getDouble("GIA_NT21")}\nSố lượng: ${it.getDouble("SO_LUONG1")}\nThuế: ${(it.getDouble("THUE_SUAT") * 100).toStringAsFixed(0)}%'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Đóng'))
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Tổng cộng
          Container(
            color: Colors.grey.shade100,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        'Tổng SL1: ${invoice.tSL1.toStringAsFixed(2)}')),
                Expanded(
                    child: Text(
                        'Thành tiền: ${invoice.tTIEN2.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Thuế: ${invoice.tTHUE.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Ttt: ${invoice.tTT.toStringAsFixed(0)}')),
              ],
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
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
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }
}
