// lib/pages/invoice_page.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/controls/v6_vvar_textbox.dart';
import 'package:v6_invoice_mobile/core/config/app_colors.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/api_response.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/invoice_item.dart';
import 'package:v6_invoice_mobile/models/scan_item.dart';
import 'package:v6_invoice_mobile/screens/qr_scan_screen.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
import '../repository.dart';
import 'invoice_item_edit_page.dart';
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


// Khóa truy cập Controller trong trang.
enum ControlField { so_ct, ngay_ct, ma_kh, ma_sonb ,ten_kh, nguoi_dai_dien, dia_chi, dien_giai, ma_so_thue, thong_tin_them, status, ma_nt, ty_gia}
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
    ControlField.dien_giai: TextBoxS(fieldName: 'DIEN_GIAI'),
    ControlField.status: TextBoxS(fieldName: 'TRANG_THAI'),
    ControlField.ma_nt: TextBoxS(fieldName: 'MA_NT'),
    ControlField.ty_gia: TextBoxN(fieldName: 'TY_GIA', decimalPlaces: 2),
  };
  
  //InvoiceStatus _status = InvoiceStatus.A; // Trạng thái chứng từ

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    // khởi tạo tab controller
    _tabController = TabController(length: 4, vsync: this);
    invoice = widget._invoice;
    invoice.keepOldData();
    _controllers[ControlField.ma_sonb]!.advanceFilter = "dbo.VFV_InList0('${widget.mact}',MA_CTNB,',')=1";
    // Load giá trị từ invoice vào controllers dựa theo ctrl.fieldName
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

  TextBoxD get ngayCtController => _controllers[ControlField.ngay_ct]! as TextBoxD;
  TextBoxN get tyGiaController => _controllers[ControlField.ty_gia]! as TextBoxN;
  DateTime? get ngayCt => ngayCtController.dateValue;
  set tyGia(Object? value) {
    // 1. Chuyển đổi giá trị dynamic/Object? thành String đã định dạng
    //    Hàm H.objectToString sẽ xử lý null, double, int, v.v., và áp dụng định dạng.
    tyGiaController.text = H.objectToString(
      value,
      thousandSeparator: ' ', 
      decDecimalPlaces: 2
    );
  }

  void _prepareEdit() {
    if (invoice.canEdit){
      invoice.keepOldData();
    setState(() => mode = InvoiceMode.edit);
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền sửa.')),
      );
    }
  }

  void _cancelEdit() {
    invoice.resetChanges();
    // Load lại giá trị từ invoice vào controllers dựa theo ctrl.fieldName
    for (var ctrl in _controllers.values) {
      ctrl.loadValueFrom(invoice);
    }
    setState(() => mode = InvoiceMode.view);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Cập nhập các giá trị AM.
    _updateFormValuesToInvoice();
    

    final repo = context.read<InvoiceRepository>();
    try {
      if (mode == InvoiceMode.add) {
        var response = await repo.addInvoice(invoice);
        if (response.error != null) {
          throw Exception(response.error);
        }
      } else if (mode == InvoiceMode.edit) {
        var response = await repo.updateInvoice(invoice);
        if (response.error != null) {
          throw Exception(response.error);
        }
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
          dataV6:
          {
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
        invoice.detailDatas.addAll(scanedItems);
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

  void _deleteInvoiceClick() {
    if (!invoice.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền xóa.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa chứng từ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              ApiResponse response = await context.read<InvoiceRepository>().deleteInvoice(invoice);
              if (response.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xóa thất bại: ${response.error}')),
                );
                Navigator.pop(context);
                return;
              }
              else {
                if (H.objectToBool(response.data)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa chứng từ thành công.')),
                  );
                  Navigator.pop(context);await Future.delayed(const Duration(milliseconds: 500));
                  Navigator.pop(context);
                }
              }
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
    final initialDate = ngayCtController.dateValue ?? DateTime.now();
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

  String _createNewSttRec0() {
    final maxSttRec0 = invoice.detailDatas.map((e) => H.objectToInt(e.getInt('STT_REC0'))).fold<int>(0, (prev, element) => element > prev ? element : prev);
    return (maxSttRec0 + 1).toString().padLeft(5, '0');
  }
  void _addItem() async {
    _updateFormValuesToInvoice();
    var dataV6 = invoice.dataV6;
    final newItem = await Navigator.push<InvoiceItem>(
      context,
      MaterialPageRoute(builder: (_) => InvoiceItemEditPage(dataAM: dataV6)),
    );

    if (newItem != null) {
      // Check stt_rec0 unique
      if (newItem.sttRec0.isEmpty) {
        final newSttRec0 = _createNewSttRec0();
        newItem.setValue('STT_REC0', newSttRec0);
      }
      setState(() {
        invoice.addItem(newItem);
        _tinhTongThanhToan();
      });
      //context.read<InvoiceRepository>().addItem(invoice.id, item);
    }
  }

  void _editItem(InvoiceItem item) async {
    if (mode == InvoiceMode.view){
       return;
    }
    _updateFormValuesToInvoice();
    var dataV6 = invoice.dataV6;
    final savedItem = await Navigator.push<InvoiceItem>(
      context,
      MaterialPageRoute(builder: (_) => InvoiceItemEditPage(invoiceItem: item, dataAM: dataV6)),
    );
    if (savedItem != null) {
      if (savedItem.sttRec0.isEmpty) {
        final newSttRec0 = _createNewSttRec0();
        savedItem.setValue('STT_REC0', newSttRec0);
      }
      setState(() {
        final index = invoice.detailDatas.indexOf(item);

        if (index != -1) {
          // Thay thế item cũ bằng item mới (result)
          //invoice.detailDatas[index] = savedItem; item đã được cập nhật trực tiếp trong trang edit
          _tinhTongThanhToan();
        }
      });
      //context.read<InvoiceRepository>().updateItem(invoice.id, result);
    }
  }

  void _deleteItem(InvoiceItem item) {
    if (mode == InvoiceMode.view){
       return;
    }
    //context.read<InvoiceRepository>().deleteItem(invoice.id, item.id);
    setState(() {
      invoice.detailDatas.removeWhere((it) => it.sttRec0 == item.sttRec0);
      _tinhTongThanhToan();
    });
  }

  void _updateFormValuesToInvoice() {
    for (var ctrl in _controllers.values) {
      ctrl.setValueTo(invoice);
    }
  }

  void _tinhTongThanhToan() {
    setState(() {
      _updateFormValuesToInvoice();
      invoice.tinhTongThanhToan();
    });
  }

  @override
  Widget build(BuildContext context) {
    // invoice = context
    //     .watch<InvoiceRepository>()
    //     .invoices
    //     .firstWhere((i) => i.sttrec == invoice.sttrec, orElse: () => invoice);

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
              onPressed: _prepareEdit,
              icon: invoice.canEdit ? const Icon(Icons.edit) : const Icon(Icons.edit_off),
            ),
          if (mode != InvoiceMode.view)
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _deleteInvoiceClick();
              if (v == 'cancel') _cancelEdit();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Xóa')),
              const PopupMenuItem(value: 'cancel', child: Text('Hủy')),
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
                    Tab(text: 'Tiền tệ'),
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
                                  V6VvarTextBox(label: 'Mã nội bộ', fieldKey: 'MA_SONB', ftype: 'C0',
                                    controller: _controllers[ControlField.ma_sonb]!,
                                    vvar: 'MA_SONB',
                                    isRequired: true,
                                    enabled: mode != InvoiceMode.view,
                                    onLooked: (sender, selectedData) {
                                      String mact = H.getValue(selectedData, 'MA_CTNB', defaultValue: '').toString();
                                      if (mact.isNotEmpty) {
                                        invoice.setString('MA_CT', mact);
                                      }
                                      _controllers[ControlField.so_ct]!.setValue('$mact-GEN001');
                                    },
                                    onChanged: (fieldKey, newValue, isLookup) {
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
                                    onChanged: (fieldKey, newValue, isLookup) {
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
                            // Hàng 5: switch chiết khấu chung, thuế chung
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Chiết khấu chung'),
                                    value: invoice.isCkChung,
                                    onChanged: mode == InvoiceMode.view ? null : (v) {
                                      setState(() {
                                        invoice.setValue('LOAI_CK', v);
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Nhập tiền Thuế'),
                                    value: invoice.isThueChung,
                                    onChanged: mode == InvoiceMode.view ? null : (v) {
                                      setState(() {
                                        invoice.setValue('SUA_THUE', v);
                                      });
                                    },
                                  ),
                                ),
                              ]
                            )
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
                      // Tab Tiền tệ
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(12), // Tăng padding lên 12 để đẹp hơn
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // Đảm bảo các trường chiếm toàn bộ chiều rộng
                          children: [
                            Row(children: [
                              Expanded(
                                child: V6VvarTextBox(label: 'Mã nguyên tệ', fieldKey: 'MA_NT', ftype: 'C0', controller: _controllers[ControlField.ma_nt]!,
                                  vvar: 'MA_NT',
                                  isRequired: true, noFilter: true, enabled: mode != InvoiceMode.view,
                                  onLooked: (sender, selectedItem) async {
                                    tyGiaController.decimalValue = await ApiService.getTyGia(
                                        H.getValue(selectedItem, 'MA_NT', defaultValue: 'VND').toString(), ngayCt ?? DateTime.now());
                                  },
                                  onChanged: (fieldKey, newValue, isLookup) {
                                    
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _controllers[ControlField.ty_gia], // Ví dụ: bạn cần định nghĩa Tab1Field.ma_so_thue
                                  decoration: _fieldDecoration('Tỷ giá'),
                                  enabled: mode != InvoiceMode.view,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],),
                            // Các trường tiền tệ khác nếu cần
                          ],
                        ),
                      ), // end Tab Tiền tệ
                      
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
                      if (mode != InvoiceMode.view)
                        IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                Expanded(
                  child: invoice.detailDatas.isEmpty
                      ? const Center(child: Text('Chưa có chi tiết.'))
                      : ListView.builder(
                          itemCount: invoice.detailDatas.length,
                          itemBuilder: (context, idx) {
                            final it = invoice.detailDatas[idx];
                            return ListTile(
                              title:
                                  Text('${it.getString("MA_VT")} — ${it.getString("TEN_VT")}'),
                              subtitle: Text(
                                  'Đơn giá: ${it.getDecimal("GIA_NT21").toStringAsFixed(0)} × ${it.getDecimal("SO_LUONG1").toStringAsFixed(2)} = ${it.getDecimal("TIEN_NT2").toStringAsFixed(0)}'),
                              trailing: mode == InvoiceMode.view ? null : PopupMenuButton<String>(
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
                                    title: Text('Chi tiết ${it.getString("MA_VT")}'),
                                    content: Text(
                                        'Mô tả: ${it.getString("TEN_VT")}\nĐơn giá: ${it.getDecimal("GIA_NT21")}\nSố lượng: ${it.getDecimal("SO_LUONG1")}\nThuế: ${(it.getDecimal("THUE_SUAT") * Decimal.fromInt(100)).toStringAsFixed(0)}%'),
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
                        'Tổng SL1: ${invoice.tSoLuong1.toStringAsFixed(2)}')),
                Expanded(
                    child: Text(
                        'Thành tiền: ${invoice.tTien2.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Thuế: ${invoice.tThueNt.toStringAsFixed(0)}')),
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
