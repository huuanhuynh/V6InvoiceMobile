import 'package:v6_invoice_mobile/h.dart';

class InvoiceItem {
  String get sttRec0 => H.getValue(data, 'STT_REC0', defaultValue: '');
  /// Dữ liệu gốc của InvoiceItem theo fieldV6
  Map<String, dynamic> data = {};

  InvoiceItem({
    Map<String,dynamic>? triTMdata,
    Map<String, dynamic>? v6Data
  }){
    if (v6Data != null) {
      readDataV6(v6Data);
    }
    else if (triTMdata != null) {
      readData(triTMdata);
    }
  }

  dynamic operator [](String key) => data[key];
  void operator []=(String key, dynamic value) => data[key] = value;

  String getString(String fieldV6){
    return H.objectToString(H.getValue(data, fieldV6, defaultValue: ''));
  }

  

  double getDouble(String fieldV6)
  {
    return H.getDouble(data, fieldV6, defaultValue: 0);
  }
  /// Các trường dữ liệu chi tiết của InvoiceItem, ánh xạ từ fieldV6 sang fieldAPI
  Map<String, String> mapper = {
    'STT_REC': 'sttRec',
    'STT_REC0': 'sttRec0',
    'MA_VT': 'maVt',
    'TEN_VT': 'tenVt',
    'MA_KHO': 'maKho',
    'MA_KHOI': 'maKhoi',
    'SO_LUONG': 'soLuong',
    'SO_LUONG1': 'soLuong1',
    'GIA_NT2': 'giaNt2',
    'TIEN_NT2': 'tienNt2',
    'THUE_NT': 'thueNt',
    'MA_THUE': 'maThue',
    'GHI_CHU': 'ghiChu',
  };
  String m(String fieldV6){
    return H.getValue(mapper, fieldV6, defaultValue: fieldV6);
  }
  
  /// Chuyển đổi dữ liệu sang định dạng API để gửi lên API
  Map<String, dynamic> toDataAPI() {
    Map<String, dynamic> dataAPI = {};
    data.forEach((key, value) {
      dataAPI[m(key)] = value;
    });
    return dataAPI;
  }
  
  InvoiceItem readData(Map<String, dynamic> triTMdata) {
    data = {};
    mapper.forEach((fieldV6, fieldTriTM) {
      data[fieldV6] = H.getValue(triTMdata, fieldTriTM);
    });
    return this;
  }
  InvoiceItem readDataV6(Map<String, dynamic> v6data) {
    data = v6data;
    return this;
  }
}