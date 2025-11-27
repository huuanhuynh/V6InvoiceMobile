// lib/pages/invoice_page.dart
// dự định: khởi tại 3 danh sách controller cho 3 tab các thông tin chung, khách hàng, ghi chú, sau đó build theo 3 danh sách đó.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/controls/v6_vvar_textbox.dart';
import 'package:v6_invoice_mobile/h.dart';
import '../models.dart';
import '../repository.dart';
import 'item_edit_page.dart';
import 'dart:math';

enum InvoiceMode { view, edit, add }

class InvoicePage extends StatefulWidget {
  final String mact; // ví dụ: SOH
  final Invoice? _invoice; // nếu null => tạo mới
  const InvoicePage({
    super.key,
    required this.mact,
    Invoice? invoice,
  }) : _invoice = invoice;

  static const routeName = '/invoice';

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}


// Định nghĩa các key cho Map Controllers
enum Tab0Field { so_ct, ngay_ct, ma_kh, ma_sonb }
enum Tab1Field { ten_kh, ghi_chu }
enum Tab2Field { dien_giai }
enum InvoiceStatus { A, B, C } // Giả định các trạng thái

class _InvoicePageState extends State<InvoicePage>
    with TickerProviderStateMixin {
  late Invoice invoice;
  late InvoiceMode mode;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // controllers cho phần đầu
  final Map<Tab0Field, TextBoxC> _tab0Controls = {
    Tab0Field.so_ct: TextBoxC(),
    Tab0Field.ma_kh: TextBoxC(),
    Tab0Field.ma_sonb: TextBoxC(),
  };
  final Map<Tab1Field, TextBoxC> _tab1Controls = {
    Tab1Field.ten_kh: TextBoxC(),
    Tab1Field.ghi_chu: TextBoxC(),
  };
  final Map<Tab2Field, TextBoxC> _tab2Controls = {
    Tab2Field.dien_giai: TextBoxC(),
  };
  DateTime? _date;
  InvoiceStatus _status = InvoiceStatus.A; // Trạng thái chứng từ

  @override
  void initState() {
    super.initState();
    // khởi tạo tab controller
    _tabController = TabController(length: 3, vsync: this);

    if (widget._invoice == null) {
      // tạo mới
      final now = DateTime.now();
      invoice = Invoice(
        id: 'inv${now.millisecondsSinceEpoch}',
        number: 'NEW-${now.year}-${Random().nextInt(9999).toString().padLeft(4, '0')}',
        date: now,
      );
      mode = InvoiceMode.add;
    } else {
      // sửa
      invoice = widget._invoice!;
      mode = InvoiceMode.edit;
    }

    _tab0Controls[Tab0Field.so_ct]!.text = invoice.number;
    _tab1Controls[Tab1Field.ten_kh]!.text = invoice.customerName;
    _tab1Controls[Tab1Field.ghi_chu]!.text = invoice.notes;
    // Gán giá trị giả định cho Mã khách hàng (vì chưa có trong Invoice model gốc)
    _tab0Controls[Tab0Field.ma_kh]!.text = 'CUST001'; 
    
    _date = invoice.date;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var ctrl in _tab0Controls.values) {
      ctrl.dispose();
    }
    
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // invoice.number = _ctrlNumber.text;
    // invoice.customerName = _ctrlCustomer.text;
    // invoice.notes = _ctrlNotes.text;
    
    // Cập nhật lại invoice object
    invoice.number = _tab0Controls[Tab0Field.so_ct]!.text;
    invoice.customerName = _tab1Controls[Tab1Field.ten_kh]!.text;
    invoice.notes = _tab1Controls[Tab1Field.ghi_chu]!.text;
    invoice.date = _date ?? invoice.date;
    // Bổ sung: Gán trạng thái và Mã KH (nếu có trong model)
    // invoice.status = _status.name; 
    // invoice.customerCode = _controllers[InvoiceField.customerCode]!.text;

    final repo = context.read<InvoiceRepository>();
    if (mode == InvoiceMode.add) {
      repo.createInvoice(invoice);
    } else {
      repo.updateInvoice(invoice);
    }

    setState(() => mode = InvoiceMode.view);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu chứng từ')));
  }

  // Hàm xử lý Scan QR MỚI
  void _scanQR() async {
    // Hành động giả lập: Mở trang quét QR (có thể là một Dialog/Page riêng)
    // Thay thế bằng hoặc `mobile_scanner` thực tế
    final qrData = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quét QR (Giả lập)'),
        content: const Text('Chức năng quét QR đang được gọi...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, '{"MA_VT":"FAKE-SP","TEN_VT":"Sản phẩm QR","SO_LUONG1":5.0,"GIA_NT21":100000.0}'),
            child: const Text('Giả lập QR thành công'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (qrData != null) {
      try {
        final Map<String, dynamic> data = Map.from(jsonDecode(qrData));
        // Tạo InvoiceItem mới từ dữ liệu QR
        final newItem = InvoiceItem(
          id: 'item${DateTime.now().millisecondsSinceEpoch}',
          data: data,
        );
        
        setState(() {
          invoice.items.add(newItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm ${newItem.stringOf("TEN_VT")} từ QR')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đọc dữ liệu QR: $e')),
        );
      }
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addItem() async {
    final item = await Navigator.push<InvoiceItem>(
      context,
      MaterialPageRoute(builder: (_) => const ItemEditPage()),
    );
    if (item != null) {
      setState(() {
        invoice.items.add(item);
        invoice.calculateTotals();
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
          invoice.calculateTotals();
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
      invoice.calculateTotals();
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
                            // Hàng 1: Ngày & Mã nội bộ
                            Row(
                              children: [
                                // Cột 1: Ngày chứng từ
                                Expanded(
                                  child: InkWell(
                                    onTap: mode == InvoiceMode.view ? null : _pickDate,
                                    child: InputDecorator(                                      
                                      decoration: const InputDecoration(labelText: 'Ngày chứng từ', border: OutlineInputBorder()),
                                      child: Text(_date?.toIso8601String().split('T').first ?? ''),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cột 2: Mã nội bộ (Giả sử là MA_NB)
                                Expanded(
                                  child:
                                  V6VvarTextBox(label: 'Mã nội bộ', fieldKey: 'MA_SONB', ftype: 'ftype', controller: _tab0Controls[Tab0Field.ma_sonb]!,
                                    vvar: 'MA_SONB',
                                    isRequired: true,
                                    enabled: mode != InvoiceMode.view,
                                    onLooked: (sender, selectedItem) {
                                      // Xử lý sau khi lookup nếu cần
                                    },
                                    onChanged: (fieldKey, newValue) {
                                      // Xử lý khi mã nội bộ thay đổi (nếu cần)
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Hàng 2: Mã KH & Số chứng từ
                            Row(
                              children: [
                                // Cột 1: Mã Khách hàng (Thêm mới)
                                Expanded(
                                  child: V6VvarTextBox(label: 'Mã khách hàng', fieldKey: 'MA_KH', ftype: 'ftype', controller: _tab0Controls[Tab0Field.ma_kh]!,
                                    vvar: 'MA_KH',
                                    isRequired: true,
                                    enabled: mode != InvoiceMode.view,
                                    onLooked: (sender, selectedItem) {
                                      // Gán tên khách hàng sau khi lookup
                                      final tenKh = H.getValue(selectedItem, 'TEN_KH', defaultValue: '').toString();
                                      _tab1Controls[Tab1Field.ten_kh]!.text = tenKh;
                                    },
                                    onChanged: (fieldKey, newValue) {
                                      // Xử lý khi mã khách hàng thay đổi (nếu cần)
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cột 2: Số chứng từ
                                Expanded(
                                  child: TextFormField(
                                    controller: _tab0Controls[Tab0Field.so_ct],
                                    decoration: const InputDecoration(labelText: 'Số chứng từ', border: OutlineInputBorder()),
                                    enabled: mode != InvoiceMode.view,
                                    validator: (v) => v == null || v.isEmpty ? 'Yêu cầu' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Hàng 3: Diễn giải dài
                            TextFormField(
                              controller: _tab1Controls[Tab1Field.ghi_chu],
                              decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
                              enabled: mode != InvoiceMode.view,
                              maxLines: 2, // Cho phép nhiều dòng
                            ),
                            const SizedBox(height: 16),
                            
                            // Hàng 4: Dropdown Trạng thái
                            DropdownButtonFormField<InvoiceStatus>(
                              decoration: const InputDecoration(
                                labelText: 'Trạng thái',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                              ),
                              initialValue: _status,
                              onChanged: mode == InvoiceMode.view ? null : (v) => setState(() => _status = v!),
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
                        padding: const EdgeInsets.all(8),
                        child: TextFormField(
                          controller: _tab1Controls[Tab1Field.ten_kh],
                          decoration: const InputDecoration(labelText: 'Tên Khách hàng', border: OutlineInputBorder()),
                          enabled: mode != InvoiceMode.view,
                        ),
                      ),
                      // Tab diễn giải
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: TextFormField(
                          controller: _tab2Controls[Tab2Field.dien_giai],
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
                                  Text('${it.stringOf("MA_VT")} — ${it.stringOf("TEN_VT")}'),
                              subtitle: Text(
                                  'Đơn giá: ${it.valueOf("GIA_NT21").toStringAsFixed(0)} × ${it.valueOf("SO_LUONG1").toStringAsFixed(2)} = ${it.valueOf("TIEN_NT2").toStringAsFixed(0)}'),
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
                                        'Mô tả: ${it.stringOf("TEN_VT")}\nĐơn giá: ${it.valueOf("GIA_NT21")}\nSố lượng: ${it.valueOf("SO_LUONG1")}\nThuế: ${(it.valueOf("THUE_SUAT") * 100).toStringAsFixed(0)}%'),
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
                        'Tổng SL1: ${invoice.T_SL1.toStringAsFixed(2)}')),
                Expanded(
                    child: Text(
                        'Thành tiền: ${invoice.T_TIEN2.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Thuế: ${invoice.T_THUE.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Ttt: ${invoice.T_TT.toStringAsFixed(0)}')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
