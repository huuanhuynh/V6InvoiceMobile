// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/controls/v6_vvar_textbox.dart';
import 'package:v6_invoice_mobile/pages/catalog_page.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:xml/xml.dart';
import '../models.dart';

class ItemEditPage extends StatefulWidget {
  static const routeName = '/item_edit';
  final InvoiceItem? item; // null => thêm mới

  const ItemEditPage({super.key, this.item});

  @override
  State<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends State<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextBoxC> _controllers = {};
  String? statusText;
  late Future<List<Map<String, String>>> _alct1Tables;
  List<Map<String, String>>? _configTables; // cùng phiên bản _alct1Tables

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future, khi hoàn thành nó sẽ gọi setState (thông qua FutureBuilder)
    _alct1Tables = loadXmlTable('assets/data/alct1.xml');
    
    // Sửa chữa quan trọng:
    // Bạn cần TẠO controllers khi cần (trong _getController) và GÁN giá trị
    // sau khi _configTables có sẵn. Tuy nhiên, để tránh lỗi, 
    // ta cần phải đảm bảo _getController hoạt động trong _buildBody.
  }

  // Sửa chữa: Đặt hàm _getController ở đây
  TextBoxC _getController(String name) {
    // Luôn luôn tạo controller nếu nó chưa tồn tại.
    final ctrl = _controllers.putIfAbsent(name, () => TextBoxC());
    
    // Xử lý nạp dữ liệu chỉnh sửa ban đầu tại đây (nếu có)
    // Chỉ nạp dữ liệu ban đầu một lần.
    if (widget.item != null && ctrl.text.isEmpty) {
        final key = name; // Tên trường (fcolumn)
        final value = widget.item!.data[key];
        if (value != null) {
            ctrl.text = value.toString();
        }
    }
    return ctrl;
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, String>>> loadXmlTable(String path) async {
    // 1. Xử lý lỗi khi tải file
    String xmlString;
    try {
      xmlString = await rootBundle.loadString(path);
    } catch (e) {      
      statusText = 'Lỗi khi tải file XML từ assets tại $path: $e';
      return []; 
    }

    // 2. Xử lý lỗi khi phân tích cú pháp (Parsing)
    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString); 
    } on XmlParserException catch (e) {
      statusText = ('Lỗi phân tích cú pháp XML: $e');
      return [];
    } catch (e) {
      statusText = ('Lỗi không xác định khi phân tích XML: $e');
      return [];
    }
    
    // 3. Xử lý các node (Table)
    final tables = <Map<String, String>>[];
    // findAllElements('Table') là đúng để lấy các node con trực tiếp.
    final tableNodes = document.findAllElements('Table');
    
    for (final tableNode in tableNodes) {
      final map = <String, String>{};      
      for (final element in tableNode.children.whereType<XmlElement>()) {
        map[element.name.local] = element.innerText.trim();
      }
      
      tables.add(map);
    }
    _configTables = tables;
    return tables;
  }

  
  dynamic _getConvertedValue(String fieldKey, String textValue) {
    if (textValue.trim().isEmpty) {
      // Trả về null nếu trống (hoặc 0 nếu là kiểu số, tùy logic nghiệp vụ)
      return null; 
    }

    // Tìm cấu hình của trường này
    final config = _configTables?.firstWhere(
      (c) => c['fcolumn']?.trim() == fieldKey,
      orElse: () => {},
    );
    
    final ftype = config?['ftype']?.trim().toUpperCase() ?? 'C0';
    
    if (ftype.startsWith('N')) {
      // Xử lý kiểu số (N2, N4, v.v.)
      // Thay thế dấu phẩy bằng dấu chấm để đảm bảo parse đúng format double của Dart
      final cleanValue = textValue.replaceAll(',', '.');
      return double.tryParse(cleanValue) ?? 0.0; // Trả về 0.0 nếu parse lỗi
    }
    // chưa xử lý kiểu DateTime
    // Mặc định cho kiểu chuỗi (C0, C1,...) hoặc các kiểu khác
    return textValue; 
  }


  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      // 1. Lấy dữ liệu GỐC
      final originalData = Map<String, dynamic>.from(widget.item?.data ?? {});
      
      // 2. Ghi đè (overwrite) các giá trị đã được CHUYỂN ĐỔI
      for (final entry in _controllers.entries) {
        final fieldKey = entry.key;
        final textValue = entry.value.text;
        
        // Sử dụng hàm chuyển đổi kiểu
        final convertedValue = _getConvertedValue(fieldKey, textValue);
        
        // Chỉ lưu nếu giá trị không phải null (có thể điều chỉnh logic này)
        if (convertedValue != null) { 
            originalData[fieldKey] = convertedValue; 
        } else {
            // Nếu giá trị là null và đã có key gốc, có thể xóa key đó
            // originalData.remove(fieldKey); // Tùy thuộc vào yêu cầu nghiệp vụ
        }

        // Lấy thêm dữ liệu trong tag
        final tag = _getController('MA_VT').tag;
        if (tag != null) {
          originalData['ten_vt'] = H.getValue(tag, 'ten_vt');
        }
      }
      
      // 3. Tạo InvoiceItem mới
      final item = InvoiceItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        data: originalData, 
      );
      
      Navigator.pop(context, item);
    }
  }

  static const String FIELD_SO_LUONG1 = 'SO_LUONG1';
  static const String FIELD_GIA_NT21 = 'GIA_NT21';
  static const String FIELD_TIEN_NT2 = 'TIEN_NT2';
  // Hàm xử lý sự kiện chung cho tất cả các control
  void _handleFieldChange(V6VvarTextBox sender , String newValue) {
    
      // Cần đảm bảo rằng chỉ tính toán khi SO_LUONG1 HOẶC GIA_NT21 thay đổi
      if (sender.fieldKey == FIELD_SO_LUONG1 || sender.fieldKey == FIELD_GIA_NT21) {
          
          // 1. Lấy giá trị hiện tại của cả hai trường từ controllers
          // (Sử dụng hàm _getConvertedValue an toàn hơn, nhưng ta có thể tạm dùng tryParse đơn giản ở đây)
          final soLuongController = _getController(FIELD_SO_LUONG1);
          final donGiaController = _getController(FIELD_GIA_NT21);

          // 2. Chuyển đổi sang kiểu số để tính toán
          // Sử dụng hàm tryParse an toàn và xử lý dấu thập phân
          final soLuong = H.objectToDecimal(soLuongController.text);
          final donGia = double.tryParse(donGiaController.text.replaceAll(',', '.')) ?? 0.0;

          // 3. Tính toán Thành tiền: TIEN_NT2 = SO_LUONG1 * GIA_NT21
          final thanhTien = soLuong * donGia;

          // 4. Cập nhật Controller của trường Thành tiền (TIEN_NT2)
          final thanhTienController = _getController(FIELD_TIEN_NT2);

          // Định dạng kết quả (ví dụ: làm tròn 2 chữ số thập phân)
          // LƯU Ý: Không cần gọi setState vì việc thay đổi controller đã tự động cập nhật TextFormField
          thanhTienController.text = thanhTien.toStringAsFixed(2);
      }
      
      // Bất kỳ logic xử lý chung nào khác (ví dụ: tính thuế, kiểm tra giới hạn) sẽ được thêm vào đây.
  }

  void _handleFieldLooked(V6VvarTextBox sender, Map<String, dynamic> selectedItem) {
    try{
      switch (sender.fieldKey.toUpperCase().trim()) {
          case 'MA_VT':
            // Gán thêm tên vật tư từ tag
            final dvt = H.getValue(selectedItem, 'dvt');
            if (dvt != null) {
              final dvtControl = _getController('DVT');
              dvtControl.text = dvt;
            }
            break;
          case 'MA_THUE_I':
            // Gán thêm thuế suất từ selectedItem
            final thueSuat = H.getValue(selectedItem, 'THUE_SUAT');
            if (thueSuat != null) {
              final thueSuatControl = _getController('THUE_SUAT_I');
              thueSuatControl.text = thueSuat;
            }
            break;
        }
    } catch (e) {
      statusText = 'Lỗi khi xử lý lookup cho trường ${sender.fieldKey}: $e';
    }
    finally {
      // Gọi hàm xử lý thay đổi để cập nhật các trường liên quan
      _handleFieldChange(sender, sender.controller.text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Sửa chi tiết' : 'Thêm chi tiết'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      //body: Text("data"),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _alct1Tables,
        builder: (context, snapshot) {
          // 1. Xử lý trạng thái LỖI (Quan trọng!)
          if (snapshot.hasError) {
            statusText = ('Lỗi FutureBuilder: ${snapshot.error}'); // In lỗi ra console
            return Center(
              child: Text('Đã xảy ra lỗi khi tải dữ liệu: ${snapshot.error}'),
            );
          }
          
          // 2. Xử lý trạng thái LOADING
          if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Dữ liệu đã tải thành công (hasData là true)
          final tables = snapshot.data!;
          
          // 3. Xử lý trạng thái DỮ LIỆU RỖNG
          if (tables.isEmpty) {
            return const Center(child: Text('Không tìm thấy bản ghi nào.'));
          }
          
          // 4. Xử lý trạng thái THÀNH CÔNG và có dữ liệu
          return _buildBody(tables);
        },
      ),
    );
  }

    
  Widget _buildBody(List<Map<String, String>> tables) {
    // Lọc các trường có visible = 'true' (giả định đã trim() khi load XML)
    final visibleTables = tables.where((t) {
      // Nếu 'visible' bị thiếu hoặc là 'true' (tương đương true), thì hiển thị.
      // Lưu ý: Cần đảm bảo dữ liệu trong Map không còn khoảng trắng (ví dụ: 'true ')
      final isVisible = t['visible']?.toLowerCase().trim() ?? 'true';
      return isVisible == 'true';
    }).toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...visibleTables.map((configMap) {
            final label = configMap['caption']?.trim() ?? '';
            final field = configMap['fcolumn']?.trim() ?? '';
            final ftype = configMap['ftype']?.trim() ?? ''; // Ví dụ: N2, N4, C0
            final isRequired = (configMap['notempty']?.toLowerCase().trim() ?? 'false') == 'true';
            final fvvar = configMap['fvvar']?.trim();
            
            final controller = _getController(field);
            // XÁC ĐỊNH ICON TRA CỨU
            // final lookupIcon = (fvvar != null && fvvar.isNotEmpty) 
            //     ? IconButton(
            //         icon: const Icon(Icons.search),
            //         onPressed: () => _openCatalogLookup(field, fvvar),
            //       ) 
            //     : null; // Không hiển thị nếu không có fvvar
            // final isNumeric = ftype.startsWith('N');
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: V6VvarTextBox(
                label: label,
                fieldKey: field,
                ftype: ftype,
                vvar: fvvar,
                isRequired: isRequired,
                controller: controller,
                
                // Truyền toàn bộ cấu hình để V6LookupField có thể tự tìm valueField (tùy vào logic V6)
                // Hoặc chỉ cần truyền configMap:
                configTables: configMap,
                
                // Gọi hàm xử lý thay đổi giá trị và tính toán
                onChanged: _handleFieldChange,
                onLooked: _handleFieldLooked,
              ),
            );
          }).toList(), // Chuyển sang List để dùng trong children
        ],
      ),
    );
  }

}
