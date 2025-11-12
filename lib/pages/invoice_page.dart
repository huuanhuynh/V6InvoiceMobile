// lib/pages/invoice_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
enum InvoiceField { number, customerName, customerCode, notes }
enum InvoiceStatus { A, B, C } // Giả định các trạng thái

class _InvoicePageState extends State<InvoicePage>
    with TickerProviderStateMixin {
  late Invoice invoice;
  late InvoiceMode mode;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // controllers cho phần đầu
  final Map<InvoiceField, TextEditingController> _controllers = {
    InvoiceField.number: TextEditingController(),
    InvoiceField.customerName: TextEditingController(),
    InvoiceField.customerCode: TextEditingController(), // Mã KH
    InvoiceField.notes: TextEditingController(),
  };
  //final _ctrlNumber = TextEditingController();
  //final _ctrlCustomer = TextEditingController();
  //final _ctrlNotes = TextEditingController();
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

    //_ctrlNumber.text = invoice.number;
    //_ctrlCustomer.text = invoice.customerName;
    //_ctrlNotes.text = invoice.notes;
    // Khởi tạo giá trị cho Map Controllers
    _controllers[InvoiceField.number]!.text = invoice.number;
    _controllers[InvoiceField.customerName]!.text = invoice.customerName;
    _controllers[InvoiceField.notes]!.text = invoice.notes;
    // Gán giá trị giả định cho Mã khách hàng (vì chưa có trong Invoice model gốc)
    _controllers[InvoiceField.customerCode]!.text = 'CUST001'; 
    
    _date = invoice.date;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var ctrl in _controllers.values) {
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
    invoice.number = _controllers[InvoiceField.number]!.text;
    invoice.customerName = _controllers[InvoiceField.customerName]!.text;
    invoice.notes = _controllers[InvoiceField.notes]!.text;
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

  // Thêm hàm giả này để mô phỏng hành động Lookup
void _fakeLookup(InvoiceField fieldKey, String fvvar) async {
  // Lấy controller tương ứng
  final controller = _controllers[fieldKey]!;
  
  // Dữ liệu giả định sẽ được trả về từ CatalogPage
  final Map<String, dynamic> fakeSelectedItem = {
    "MA_KH": "KH007",
    "TEN_KH": "Công ty TNHH Phần Mềm V6",
    "SO_CT": "INV2025/001",
    // Giả định khóa cần gán là 'MA_KH' hoặc 'SO_CT' tùy vào fieldKey
    // Nếu fieldKey là 'customerCode' (MA_KH), ta lấy 'MA_KH'
    // Nếu fieldKey là 'number' (SO_CT), ta lấy 'SO_CT'
  };

  // Chọn key tương ứng để gán giá trị
  final keyToAssign = fieldKey == InvoiceField.customerCode ? "MA_KH" : 
                      fieldKey == InvoiceField.number ? "SO_CT" : null;

  if (keyToAssign != null) {
    final valueToSet = fakeSelectedItem[keyToAssign];

    if (valueToSet != null) {
      // Gán giá trị vào controller mà không cần setState()
      controller.text = valueToSet.toString();
      
      // Nếu có controller khác liên quan (ví dụ: gán tên khách hàng sau khi chọn mã)
      if (fieldKey == InvoiceField.customerCode) {
         _controllers[InvoiceField.customerName]!.text = fakeSelectedItem["TEN_KH"].toString();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lookup giả lập thành công: ${valueToSet.toString()}')),
      );
    }
  }
}

  // Hàm xử lý Scan QR MỚI
  void _scanQR() async {
    // Hành động giả lập: Mở trang quét QR (có thể là một Dialog/Page riêng)
    // Thay thế bằng gói `qr_code_scanner` hoặc `mobile_scanner` thực tế
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
    context.read<InvoiceRepository>().deleteItem(invoice.id, item.id);
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
                                      decoration: const InputDecoration(labelText: 'Ngày chứng từ'),
                                      child: Text(_date?.toIso8601String().split('T').first ?? ''),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cột 2: Mã nội bộ (Giả sử là MA_NB)
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[InvoiceField.number],
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: mode != InvoiceMode.view 
                                          ? () => _fakeLookup(InvoiceField.customerCode, 'DM_KH') 
                                          : null,
                                      ) , // lookup icon
                                      labelText: 'Mã nội bộ'
                                    ),
                                    enabled: mode != InvoiceMode.view,
                                    validator: (v) => v == null || v.isEmpty ? 'Yêu cầu' : null,
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
                                  child: TextFormField(
                                    controller: _controllers[InvoiceField.customerCode],
                                    decoration: const InputDecoration(labelText: 'Mã Khách hàng'),
                                    enabled: mode != InvoiceMode.view,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cột 2: Số chứng từ
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[InvoiceField.number],
                                    decoration: const InputDecoration(labelText: 'Số chứng từ'),
                                    enabled: mode != InvoiceMode.view,
                                    validator: (v) => v == null || v.isEmpty ? 'Yêu cầu' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Hàng 3: Diễn giải dài
                            TextFormField(
                              controller: _controllers[InvoiceField.notes],
                              decoration: const InputDecoration(labelText: 'Diễn giải/Ghi chú'),
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
                              value: _status,
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
                          controller: _controllers[InvoiceField.customerName],
                          decoration: const InputDecoration(labelText: 'Tên Khách hàng'),
                          enabled: mode != InvoiceMode.view,
                        ),
                      ),
                      // Tab Ghi chú
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: TextFormField(
                          //controller: _ctrlNotes,
                          decoration:
                              const InputDecoration(labelText: 'Ghi chú'),
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
                                        'Mô tả: ${it.stringOf("GHI_CHU")}\nĐơn giá: ${it.valueOf("GIA_NT21")}\nSố lượng: ${it.valueOf("SO_LUONG1")}\nThuế: ${(it.valueOf("THUE_SUAT") * 100).toStringAsFixed(0)}%'),
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
                        'Tổng SL: ${invoice.T_SL.toStringAsFixed(2)}')),
                Expanded(
                    child: Text(
                        'Thành tiền: ${invoice.T_TIEN2.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Thuế: ${invoice.T_THUE.toStringAsFixed(0)}')),
                Expanded(
                    child: Text(
                        'Thanh toán: ${invoice.totalPayable.toStringAsFixed(0)}')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
