import 'package:decimal/decimal.dart';
import 'package:v6_invoice_mobile/h.dart';

class InvoiceItem {
  String get sttRec0 => H.getValue(data, 'STT_REC0', defaultValue: '');
  /// Dữ liệu gốc của InvoiceItem theo fieldV6
  Map<String, dynamic> data = {};

  InvoiceItem({
    Map<String,dynamic>? dataAPI,
    Map<String, dynamic>? dataV6
  }){
    if (dataV6 != null) {
      readDataV6(dataV6);
    }
    else if (dataAPI != null) {
      readData(dataAPI);
    }
  }

  //dynamic operator [](String key) => data[key];
  //void operator []=(String key, dynamic value) => data[key] = value;

  String getString(String fieldV6){
    return H.objectToString(H.getValue(data, fieldV6, defaultValue: ''));
  }
  int getInt(String fieldV6)
  {
    return H.getInt(data, fieldV6, defaultValue: 0);
  }
  Decimal getDecimal(String fieldV6)
  {
    return H.getDecimal(data, fieldV6, defaultValue: 0);
  }
  void setValue(String fieldV6, dynamic value){
    H.setValue(data, fieldV6, value);
  }
  /// Các trường dữ liệu chi tiết của InvoiceItem, ánh xạ từ fieldV6 sang fieldAPI
  Map<String, String> mapper = {
    'STT_REC': 'sttRec',
    'STT_REC0': 'sttRec0',
    'MA_VT': 'maVt',
    'TEN_VT': 'tenVt',
    'DVT': 'dvt',
    'DVT1': 'dvt1',
    'MA_KHO': 'maKho',
    'TEN_KHO': 'tenKho',
    'MA_KHO_I': 'maKhoI',
    'SO_LUONG': 'soLuong',
    'SO_LUONG1': 'soLuong1',
    'GIA_NT21': 'giaNt21',
    'GIA_NT2': 'giaNt2',
    'GIA2': 'gia2',
    'TIEN_NT2': 'tienNt2',
    'TIEN2': 'tien2',
    'THUE': 'thue',
    'THUE_NT': 'thueNt',
    'MA_THUE': 'maThue',
    'MA_THUE_I': 'maThueI',
    'GHI_CHU': 'ghiChu',
  };
  String fieldAPI(String fieldV6){
    return H.getValue(mapper, fieldV6, defaultValue: fieldV6);
  }
  
  /// Chuyển đổi dữ liệu sang định dạng API để gửi lên API
  Map<String, dynamic> toDataAPI() {
    Map<String, dynamic> dataAPI = {};
    data.forEach((key, value) {
      dataAPI[fieldAPI(key)] = value;
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