import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:v6_invoice_mobile/pages/catalog_page.dart';
import 'package:v6_invoice_mobile/v6_convert.dart';
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
  final Map<String, TextEditingController> _controllers = {};

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
  TextEditingController _getController(String name) {
    // Luôn luôn tạo controller nếu nó chưa tồn tại.
    final ctrl = _controllers.putIfAbsent(name, () => TextEditingController());
    
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
      print('Lỗi khi tải file XML từ assets tại $path: $e');
      return []; 
    }

    // 2. Xử lý lỗi khi phân tích cú pháp (Parsing)
    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString); 
    } on XmlParserException catch (e) {
      print('Lỗi phân tích cú pháp XML: $e');
      return [];
    } catch (e) {
      print('Lỗi không xác định khi phân tích XML: $e');
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

  // Thêm hàm này vào _ItemEditPageState
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
      }
      
      // 3. Tạo InvoiceItem mới
      final item = InvoiceItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        data: originalData, 
      );
      
      Navigator.pop(context, item);
    }
  }

  static const String FIELD_SO_LUONG = 'SO_LUONG1';
    static const String FIELD_DON_GIA = 'GIA_NT21';
    static const String FIELD_THANH_TIEN = 'TIEN_NT2';
  // Hàm xử lý sự kiện chung cho tất cả các control
  void _handleFieldChange(String fieldKey, String newValue) {
      
      // Cần đảm bảo rằng chỉ tính toán khi SO_LUONG1 HOẶC GIA_NT21 thay đổi
      if (fieldKey == FIELD_SO_LUONG || fieldKey == FIELD_DON_GIA) {
          
          // 1. Lấy giá trị hiện tại của cả hai trường từ controllers
          // (Sử dụng hàm _getConvertedValue an toàn hơn, nhưng ta có thể tạm dùng tryParse đơn giản ở đây)
          final soLuongController = _getController(FIELD_SO_LUONG);
          final donGiaController = _getController(FIELD_DON_GIA);

          // 2. Chuyển đổi sang kiểu số để tính toán
          // Sử dụng hàm tryParse an toàn và xử lý dấu thập phân
          final soLuong = V6Convert.objectToDecimal(soLuongController.text);
          final donGia = double.tryParse(donGiaController.text.replaceAll(',', '.')) ?? 0.0;

          // 3. Tính toán Thành tiền: TIEN_NT2 = SO_LUONG1 * GIA_NT21
          final thanhTien = soLuong * donGia;

          // 4. Cập nhật Controller của trường Thành tiền (TIEN_NT2)
          final thanhTienController = _getController(FIELD_THANH_TIEN);

          // Định dạng kết quả (ví dụ: làm tròn 2 chữ số thập phân)
          // LƯU Ý: Không cần gọi setState vì việc thay đổi controller đã tự động cập nhật TextFormField
          thanhTienController.text = thanhTien.toStringAsFixed(2);
      }
      
      // Bất kỳ logic xử lý chung nào khác (ví dụ: tính thuế, kiểm tra giới hạn) sẽ được thêm vào đây.
  }

  // Hàm mở CatalogPage và nhận kết quả
  Future<void> _openCatalogLookup(String fieldKey, String fvvar) async {
    final controller = _getController(fieldKey);
    // Lấy giá trị hiện tại của ô nhập liệu (để lọc trước)
    final currentFilterValue = controller.text.trim();
    // 1. Mở CatalogPage và đợi kết quả (selectedItem)
    final selectedItem = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogPage(
          fvvar: fvvar, // Mã danh mục cần lookup
          type: '2',    // Loại lookup (ví dụ)
          filterValue: currentFilterValue.isNotEmpty ? currentFilterValue : null,
        ),
      ),
    );

    // 2. Kiểm tra nếu có item được chọn
    if (selectedItem != null) {
      final config = _configTables?.firstWhere(
        (c) => c['fcolumn']?.trim() == fieldKey,
        orElse: () => {},
      );
      String? valueField = config != null? config['fvvar'] : fieldKey; // Cần sửa lại, có cấu hình từ catalog để lấy valueField;
      // 3. Lấy giá trị của item đã chọn. 
      // Giả định khóa cần gán là 'fcolumn' (fieldKey)
      final valueToSet = selectedItem[valueField];  // bị thiếu V6Lookup Config nên sai trường lấy data ở đây.

      if (valueToSet != null) {
        // 4. Gán giá trị vào controller của trường hiện tại
        //final controller = _getController(fieldKey);
        
        // Chuyển đổi giá trị sang chuỗi (sử dụng logic tương tự V6Convert)
        controller.text = valueToSet.toString().trim(); 

        // Nếu bạn muốn tự động tính toán sau khi gán (ví dụ: tính thành tiền)
        // có thể gọi _handleFieldChange(fieldKey, controller.text); ở đây
      }
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
            print('Lỗi FutureBuilder: ${snapshot.error}'); // In lỗi ra console
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

  // Giả định _getController, _formKey và các import đã được định nghĩa
  // Giả định: _getController(field) trả về TextEditingController cho field đó
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
          ...visibleTables.map((col) {
            final label = col['caption']?.trim() ?? '';
            final field = col['fcolumn']?.trim() ?? '';
            final ftype = col['ftype']?.trim() ?? ''; // Ví dụ: N2, N4, C0
            final isRequired = (col['notempty']?.toLowerCase().trim() ?? 'false') == 'true';
            final fvvar = col['fvvar']?.trim();
            
            final controller = _getController(field);
            // XÁC ĐỊNH ICON TRA CỨU
            final lookupIcon = (fvvar != null && fvvar.isNotEmpty) 
                ? IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _openCatalogLookup(field, fvvar),
                  ) 
                : null; // Không hiển thị nếu không có fvvar

            // Xác định kiểu bàn phím: Bất kỳ ftype nào bắt đầu bằng 'N' (Number)
            final isNumeric = ftype.startsWith('N');
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextFormField(
                controller: controller,
                onChanged: (value) => _handleFieldChange(field, value),
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  suffixIcon: lookupIcon, // lookup icon
                  suffixText: isRequired ? '*' : null, // Hiển thị (*) nếu là trường bắt buộc
                  suffixStyle: isRequired ? const TextStyle(color: Colors.red) : null,// Thêm một chút màu sắc cho trường bắt buộc nếu cần
                ),
                
                // SỬA CHỮA: Dùng ftype để xác định kiểu bàn phím
                keyboardType: isNumeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                    
                // SỬA CHỮA: Dùng trường 'notempty' để quyết định validation
                validator: isRequired
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Trường $label không được bỏ trống.';
                        }
                        // Thêm validation kiểu số nếu là trường số
                        if (isNumeric && double.tryParse(v) == null) {
                          return 'Trường $label phải là số.';
                        }
                        return null;
                      }
                    : null, // Nếu không bắt buộc, trả về null (không validation)
              ),
            );
          }).toList(), // Chuyển sang List để dùng trong children
        ],
      ),
    );
  }

}
