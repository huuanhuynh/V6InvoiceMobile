import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/controls/textboxc.dart';
import 'package:v6_invoice_mobile/controls/v6_vvar_textbox.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/repository.dart';

import '../models/invoice_item.dart';

class InvoiceItemEditPage extends StatefulWidget {
  static const routeName = '/item_edit';
  final Map<String, dynamic> dataAM;
  final InvoiceItem? invoiceItem; // null => thêm mới

  const InvoiceItemEditPage({super.key, this.invoiceItem, required this.dataAM});

  @override
  State<InvoiceItemEditPage> createState() => _InvoiceItemEditPageState();
}

class _InvoiceItemEditPageState extends State<InvoiceItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextBoxC> _controllers = {};
  late Map<String, dynamic> dataAM;
  String? statusText;
  List<Map<String, dynamic>>? _alct1Tables;
  //List<Map<String, String>>? _configTables; // cùng phiên bản _alct1Tables
  bool _isLoading = true;
  String? _errorMessage;
  
  // Danh sách cấu hình đã lọc (chỉ chứa những trường visible = true)
  List<Map<String, dynamic>> visibleTables = [];

  @override
  void initState() {
    super.initState();
    dataAM = widget.dataAM;
    _setupData();
    return;
    // Khởi tạo Future, khi hoàn thành nó sẽ gọi setState (thông qua FutureBuilder)
    //_alct1Tables = await loadXmlTable('assets/data/alct1.xml');
    //final visibleTables = _alct1Tables.where((t) {
    //  final isVisible = t['visible']?.toLowerCase().trim() ?? 'true';
    //  return isVisible == 'true';
    //}).toList();
  }

  Future<void> _setupData() async {
    try {
      // 1. Load XML
      //_alct1Tables = await loadXmlTable('assets/data/alct1.xml');
      _alct1Tables = await loadAlct1();
      
      // 2. Lọc danh sách visible và chuẩn hóa key
      visibleTables = _alct1Tables!.where((t) {
        return t['fcolumn'] != null && t['fcolumn']!.trim().isNotEmpty;
      }).toList();

      // 3. Khởi tạo toàn bộ Controllers dựa trên cấu hình đã lọc
      for (var config in visibleTables) {
        final field = (config['fcolumn'] ?? '').toUpperCase().trim();
        final ftype = (config['ftype'] ?? 'C').trim();
        
        // Hàm này sẽ tạo mới và nạp luôn giá trị từ widget.invoiceItem (nếu có)
        _getController(field, createIfNotExist: true, ftype: ftype);
      }

      // gán thông tin filter nâng cao cho DVT1 nếu có
      final mavt = H.getValue(widget.invoiceItem?.data, 'MA_VT');
      if (mavt != null && mavt.toString().trim().isNotEmpty) {
        final dvt1Ctrl = _getController('DVT1');
        if (dvt1Ctrl != null) {
          dvt1Ctrl.advanceFilter = "MA_VT='${mavt.toString().replaceAll("'", "''")}'";
        }
      }
      // filter cho ma_kho_i
      final makhoCtrl = _getController('MA_KHO_I');
      if (makhoCtrl != null) {
        makhoCtrl.advanceFilter = "MA_DVCS='${H.getString(dataAM, 'MA_DVCS').replaceAll("'", "''")}'";
      }

      // 4. Kết thúc loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Hàm lấy hoặc tạo controller cho một fieldV6, mặc định không tạo mới nếu không tồn tại.
  TextBoxC? _getController(String fieldV6, {bool createIfNotExist = false, String ftype = '',}) {
    fieldV6 = fieldV6.toUpperCase().trim();
    if (_controllers.containsKey(fieldV6)) return _controllers[fieldV6]!;
    if (!createIfNotExist) return null;// throw Exception('Controller for $fieldV6 does not exist.');
    // Create new controller
    //bool isNew = !_controllers.containsKey(fieldV6);
    final ctrl = _controllers.putIfAbsent(fieldV6, () {
      //isNew = true;
      if (ftype.startsWith('N')) {
        return TextBoxN(fieldName: fieldV6);
      } else if (ftype.startsWith('D')) {
        return TextBoxD(fieldName: fieldV6);
      } else {
        return TextBoxS(fieldName: fieldV6);
      }
    });
    
    // Xử lý nạp dữ liệu chỉnh sửa ban đầu tại đây (nếu có)
    // Chỉ nạp dữ liệu ban đầu một lần.
    if (widget.invoiceItem != null) {
      final value = H.getValue(widget.invoiceItem!.data, fieldV6);
      if (value != null) {
          ctrl.setValue(value);
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

  // Future<List<Map<String, String>>> loadXmlTable(String path) async {
  //   // 1. Xử lý lỗi khi tải file
  //   String xmlString;
  //   try {
  //     xmlString = await rootBundle.loadString(path);
  //   } catch (e) {      
  //     statusText = 'Lỗi khi tải file XML từ assets tại $path: $e';
  //     return []; 
  //   }
  //   // 2. Xử lý lỗi khi phân tích cú pháp (Parsing)
  //   XmlDocument document;
  //   try {
  //     document = XmlDocument.parse(xmlString); 
  //   } on XmlParserException catch (e) {
  //     statusText = ('Lỗi phân tích cú pháp XML: $e');
  //     return [];
  //   } catch (e) {
  //     statusText = ('Lỗi không xác định khi phân tích XML: $e');
  //     return [];
  //   }    
  //   // 3. Xử lý các node (Table)
  //   final tables = <Map<String, String>>[];
  //   // findAllElements('Table') là đúng để lấy các node con trực tiếp.
  //   final tableNodes = document.findAllElements('Table');    
  //   for (final tableNode in tableNodes) {
  //     final map = <String, String>{};      
  //     for (final element in tableNode.children.whereType<XmlElement>()) {
  //       map[element.name.local] = element.innerText.trim();
  //     }      
  //     tables.add(map);
  //   }
  //   //_configTables = tables;
  //   return tables;
  // }

  Future<List<Map<String, dynamic>>> loadAlct1() async {
    final repo = context.read<InvoiceRepository>();
    final tables = await repo.getAlct1ListSOH();
    return tables;
  }

  
  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      final iData = Map<String, dynamic>.from(widget.invoiceItem?.data ?? {});
      
      for (final entry in _controllers.entries) {
        TextBoxC controller = entry.value;
        if (controller is TextBoxN) {
          H.setValue(iData, controller.fieldName, controller.decimalValue);
        }
        else if (controller is TextBoxD) {
          H.setValue(iData, controller.fieldName, controller.dateValue);
        }
        else {
          final fieldKey = entry.key;
          final textValue = entry.value.text;
          H.setValue(iData, fieldKey, textValue);
        }
        
        //H.setValue(iData, 'TEN_VT', H.getValue(_getController('ma_vt').data, 'ten_vt'));
        //H.setValue(iData, 'TEN_KHO', H.getValue(_getController('ma_kho_i').data, 'ten_kho'));
      }
      
      // cập nhập InvoiceItem nếu là edit, trả về InvoiceItem mới nếu là thêm.
      var savedItem = widget.invoiceItem == null
        ? InvoiceItem(dataV6: iData) : widget.invoiceItem!.readDataV6(iData);
      Navigator.pop(context, savedItem);
    }
  }

  static const String FIELD_SO_LUONG1 = 'SO_LUONG1';
  static const String FIELD_SO_LUONG = 'SO_LUONG';
  static const String FIELD_HE_SO1T = 'HE_SO1T';
  static const String FIELD_HE_SO1M = 'HE_SO1M';
  static const String FIELD_TY_GIA = 'TY_GIA';

  static const String FIELD_GIA_NT21 = 'GIA_NT21';
  static const String FIELD_GIA21 = 'GIA21';
  static const String FIELD_GIA_NT2 = 'GIA_NT2';
  static const String FIELD_GIA2 = 'GIA2';
  static const String FIELD_TIEN_NT2 = 'TIEN_NT2';
  //static const String FIELD_TIEN2 = 'TIEN2';

  static const String FIELD_THUE_SUAT_I = 'THUE_SUAT_I';
  static const String FIELD_THUE_NT = 'THUE_NT';
  static const String FIELD_THUE = 'THUE';

  void getThongTinVatTu(Map<String, dynamic> selectedData) {
    try {
      final tenVt = H.getValue(selectedData, 'ten_vt');
      if (tenVt != null) {
        final tenVtControl = _getController('TEN_VT');
        tenVtControl?.text = tenVt;
      }

      final dvt = H.getValue(selectedData, 'dvt');
      if (dvt != null) {
        _getController('DVT1')?..setValue(dvt)..advanceFilter = "MA_VT='${H.getValue(selectedData, 'ma_vt')}'";
        _getController('DVT')?.text = dvt;
      }
    } catch (e) {
      statusText = 'Lỗi khi lấy thông tin vật tư: $e';
    }
  }

  /// hàm getGia ảo
  void getGia() {
    try {
      final mavtControl = _getController('MA_VT')!;
      if (mavtControl.haveData) {
        //final mavt = mavtControl.text.trim().replaceAll("'", "''");
        // Giả sử lấy giá từ dữ liệu vật tư
        final giaNt21 = H.getDouble(mavtControl.data!, 'gia_nt21', defaultValue: 0);
        final donGiaCtrl = _getController(FIELD_GIA_NT21) as TextBoxN;
        donGiaCtrl.decimalValue = giaNt21;
      }
    } catch (e) {
      statusText = 'Lỗi khi lấy giá vật tư: $e';
    }
  }
  /// SO_LUONG = SO_LUONG1 * HE_SO1T / HE_SO1M
  void tinhSoLuong() {
    final soLuong1Ctrl = _getController(FIELD_SO_LUONG1) as TextBoxN;
    final soLuongCtrl = _getController(FIELD_SO_LUONG) as TextBoxN;
    final heSo1TCtrl = _getController(FIELD_HE_SO1T, createIfNotExist: true, ftype: 'N0') as TextBoxN;
    final heSo1MCtrl = _getController(FIELD_HE_SO1M, createIfNotExist: true, ftype: 'N0') as TextBoxN;

    final soLuong1 = soLuong1Ctrl.decimalValue;
    final heSo1T = heSo1TCtrl.decimalValue == Decimal.zero ? Decimal.one : heSo1TCtrl.decimalValue;
    final heSo1M = heSo1MCtrl.decimalValue == Decimal.zero ? Decimal.one : heSo1MCtrl.decimalValue;

    final soLuong = soLuong1 * (heSo1T / heSo1M).toDecimal();
    soLuongCtrl.decimalValue = soLuong;
  }
  /// Tính GIA_NT2 = GIA_NT21, GIA2 = GIA_NT2 * TY_GIA.
  void tinhGia() {
    final giaNt21Ctrl = _getController(FIELD_GIA_NT21) as TextBoxN;
    final giaNt2Ctrl = _getController(FIELD_GIA_NT2, ftype: 'N2', createIfNotExist: true) as TextBoxN; // Controller ẩn.
    final gia21Ctrl = _getController(FIELD_GIA21, ftype: 'N2', createIfNotExist: true) as TextBoxN;
    final gia2Ctrl = _getController(FIELD_GIA2, ftype: 'N2', createIfNotExist: true) as TextBoxN;
    
    final giaNt21 = giaNt21Ctrl.decimalValue;
    var tyGia = H.getDecimal(dataAM, FIELD_TY_GIA, defaultValue: 1);
    final gia21 = giaNt21 * tyGia; gia21Ctrl.decimalValue = gia21;
    final giaNt2 = giaNt21; giaNt2Ctrl.decimalValue = giaNt2;
    final gia2 = giaNt2 * tyGia; gia2Ctrl.decimalValue = gia2;
  }
  void tinhThanhTien() {
    final soLuongCtrl = _getController(FIELD_SO_LUONG) as TextBoxN;
    final donGiaNt21Ctrl = _getController(FIELD_GIA_NT21) as TextBoxN;
    final tienNt2Ctrl = _getController(FIELD_TIEN_NT2) as TextBoxN;
    final tien2Ctrl = _getController('TIEN2', ftype: 'N2', createIfNotExist: true) as TextBoxN; // Controller ẩn.
    

    final soLuong = soLuongCtrl.decimalValue;
    final donGiaNt21 = donGiaNt21Ctrl.decimalValue;
    
    var tyGia = H.getDecimal(widget.dataAM, 'TY_GIA', defaultValue: 1);

    final thanhTienNt = soLuong * donGiaNt21;
    tienNt2Ctrl.decimalValue = thanhTienNt;
    tien2Ctrl.decimalValue = thanhTienNt * tyGia;
  }

  void tinhTienThue() {
    var thueSuatCtrl = _getController(FIELD_THUE_SUAT_I);
    if (thueSuatCtrl == null) return;
    thueSuatCtrl = thueSuatCtrl as TextBoxN;
    final tienNt2Ctrl = _getController(FIELD_TIEN_NT2) as TextBoxN;
    final thueNtCtrl = _getController(FIELD_THUE_NT, ftype: 'N2', createIfNotExist: true) as TextBoxN;
    final thueCtrl = _getController(FIELD_THUE, ftype: 'N2', createIfNotExist: true) as TextBoxN;
    
    final tienNt2 = tienNt2Ctrl.decimalValue;
    final thueSuat = thueSuatCtrl.decimalValue;
    var tyGia = H.getDecimal(widget.dataAM, FIELD_TY_GIA, defaultValue: 1);

    final thueNt2 = tienNt2 * thueSuat / Decimal.fromInt(100);
    thueNtCtrl.decimalValue = thueNt2;
    thueCtrl.decimalValue = thueNt2.toDecimal() * tyGia;
  }

  // Hàm xử lý sự kiện chung cho tất cả các control
  void _handleValueChanged(V6VvarTextBox sender , String newValue, bool isLookup) {
    
    String senderFIELD = sender.fieldKey.toUpperCase().trim();
    
    if (senderFIELD == FIELD_SO_LUONG1) {
      tinhSoLuong();
      tinhThanhTien();
      tinhTienThue();
    }
    if (senderFIELD == FIELD_GIA_NT21) {
      tinhGia();
      tinhThanhTien();
      tinhTienThue();
    }
        
    if (senderFIELD == 'MA_VT') {
      if (!isLookup) {
        // Nếu gõ tay MA_VT, tự lấy TEN_VT và DVT (gán vào DVT1, gọi DVT1 onChanged)
        final mavtControl = _getController('MA_VT')!;
        if (mavtControl.haveData) {
          final mavt = mavtControl.text.trim().replaceAll("'", "''");
          final dvt1Control = _getController('DVT1')!;
          dvt1Control.text = H.getValue(mavtControl.data, 'dvt', defaultValue: '').toString();
          dvt1Control.advanceFilter = "MA_VT='$mavt'";
        }
        else{
          mavtControl.getVvarDataAndHandleOnChanged("MA_VT", (textbox, data) {
            getThongTinVatTu(data);
            getGia();
            tinhThanhTien();
            tinhTienThue();
          });
        }
      }
      else {
        // Đã lookup, xử lý trong _handleFieldLooked
        getGia();
        tinhThanhTien();
        tinhTienThue();
      }
    } // end if MA_VT
    
    if (senderFIELD == FIELD_SO_LUONG1) {
      tinhSoLuong();
      tinhThanhTien();
      tinhTienThue();
    }

    
    
  }

  void _handleFieldLooked(V6VvarTextBox sender, Map<String, dynamic> selectedData) {
    try{
      switch (sender.fieldKey.toUpperCase().trim()) {
          case 'MA_VT':
            getThongTinVatTu(selectedData);
            
            break;
          case 'DVT1':
            final dvt = H.getValue(selectedData, 'dvt');
            if (dvt != null) {
              final dvtControl = _getController('DVT')!;
              dvtControl.text = dvt;
              // Gán thêm HE_SO1T và HE_SO1M nếu có và tính toán lại SỐ_LƯỢNG từ SỐ_LƯỢNG1
              var heSo1T = H.getDecimal(selectedData, 'he_sot', defaultValue: 1);
              var heSo1M = H.getDecimal(selectedData, 'he_som', defaultValue: 1);
              if (heSo1T == Decimal.zero) heSo1T = Decimal.one; var htc = _getController("HE_SO1T"); htc?.setValue(heSo1T);
              if (heSo1M == Decimal.zero) heSo1M = Decimal.one; var hmc = _getController("HE_SO1M"); hmc?.setValue(heSo1M);

              final soLuong1Control = _getController('SO_LUONG1') as TextBoxN;
              final soLuongControl = _getController('SO_LUONG') as TextBoxN;
              final soLuong1 = soLuong1Control.decimalValue;
              if (heSo1M != Decimal.zero && heSo1T != Decimal.zero) {
                final soLuong = soLuong1 * heSo1T / heSo1M;
                soLuongControl.decimalValue = soLuong;
              }
            }
            break;
          case 'MA_KHO_I':
            final tenKho = H.getValue(selectedData, 'ten_kho');
            if (tenKho != null) {
              final tenKhoControl = _getController('TEN_KHO');
              tenKhoControl?.text = tenKho;
            }
            break;
          case 'MA_THUE_I':
            var maThueControl = _getController('MA_THUE');
            if (maThueControl != null) {
              final maThue = H.getValue(selectedData, 'ma_thue');
              if (maThue != null) {
                maThueControl.text = maThue;
              }
            }
            final thueSuat = H.getValue(selectedData, 'THUE_SUAT');
            if (thueSuat != null) {
              final thueSuatControl = _getController('THUE_SUAT_I');
              thueSuatControl?.setValue(thueSuat);
              tinhTienThue();
            }
            break;
        }
    } catch (e) {
      statusText = 'Lỗi khi xử lý lookup cho trường ${sender.fieldKey}: $e';
    }
    finally {
      // Gọi hàm xử lý thay đổi để cập nhật các trường liên quan
      _handleValueChanged(sender, sender.controller.text, true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Lỗi: $_errorMessage')),
      );
    }
    
    final editing = widget.invoiceItem != null;
    return Scaffold(
      appBar: AppBar(
        title: Text((editing ? 'Sửa${widget.invoiceItem!.getString('STT_REC0')}' : 'Thêm')),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: visibleTables.length,
          itemBuilder: (context, index) {
            final configMap = visibleTables[index];
            final field = (configMap['fcolumn'] ?? '').toUpperCase().trim();
            final ftype = (configMap['ftype'] ?? 'C').trim();
            final controller = _controllers[field]!; // Chắc chắn đã khởi tạo ở initState
//final controller = _getController(field, createIfNotExist: true, ftype: ftype)!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: V6VvarTextBox(
                label: (configMap['caption'] ?? '').trim() + ' (' + field + ')',
                fieldKey: field,
                ftype: ftype,
                vvar: configMap['fvvar'] ?? '',
                isRequired: H.objectToBool(configMap['notempty']),
                controller: controller,
                configTables: configMap,
                onChanged: _handleValueChanged,
                onLooked: _handleFieldLooked,
              ),
            );
          },
        ),
      ),
    );
  }
   
  

}
