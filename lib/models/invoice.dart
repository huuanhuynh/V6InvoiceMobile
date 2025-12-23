import 'package:v6_invoice_mobile/h.dart';

import 'data_handler.dart';
import 'invoice_item.dart';

class Invoice implements DataHandler {
  /// MA_CT
  String get maCt => H.objectToString(H.getValue(dataV6, 'MA_CT', defaultValue: ''));
  String get soCt => getString('SO_CT');
  /// STT_REC
  String get sttrec => H.objectToString(H.getValue(dataV6, 'STT_REC', defaultValue: ''));
  DateTime get ngayCt => getDate('NGAY_CT') ?? DateTime.now();
  String get time0 => H.objectToString(H.getValue(dataV6, 'TIME0', defaultValue: '00:00:00'));

  /// Dữ liệu gốc theo API. Dữ liệu gán vào thông qua fieldV6 sẽ được mapping sang fieldAPI, Dữ liệu sẵn sàng để gửi lên API.
  //Map<String, dynamic> dataAPI = {};
  /// Dữ liệu gốc theo fieldV6
  Map<String, dynamic> dataV6 = {};
  /// Dữ liệu gốc theo fieldV6 trước khi sửa đổi
  Map<String, dynamic> dataV6Old = {};
  /// Danh sách chi tiết InvoiceItem
  List<InvoiceItem> detailDatas = [];
  /// Danh sách chi tiết InvoiceItem trước khi sửa đổi
  List<InvoiceItem> detailDatasOld = [];

  /// Khởi tạo Invoice từ dữ liệu kiểu trường API hoặc V6
  Invoice({Map<String, dynamic>? dataAPI, Map<String, dynamic>? dataV6})
  {
    if (dataV6 != null) {
      this.dataV6 = dataV6;
      if (dataV6['ads'] != null) {
        readDetails(dataV6: dataV6['ads']);
      }
      else {
        detailDatas = [];
      }
    }
    else if (dataAPI != null) {
      this.dataV6 = {};
      if (dataAPI['ads'] != null) {
        readDetails(dataAPI: dataAPI['ads']);
      }
      else {
        detailDatas = [];
      }
    }
  }

  bool get canEdit {
    String redit = getString('REDIT').toUpperCase();
    return H.objectToBool(redit);
  }

  bool get canDelete {
    String rdel = getString('RDEL').toUpperCase();
    return H.objectToBool(rdel);
  }

  Map<String,dynamic> get getMasterDataForAPI {
    Map<String, dynamic> masterData = {};
    dataV6.forEach((key, value) {
      if (key != 'ads') {
        masterData[fieldAPI(key)] = value;
      }
    });
    return masterData;
  }

  List<Map<String,dynamic>> get getDetailDatasForAPI {
    List<Map<String,dynamic>> result = [];
    for (var item in detailDatas) {
      result.add(item.toDataAPI());
    }
    return result;
  }

  /// Lưu lại dữ liệu cũ trước khi sửa đổi
  void keepOldData() {
    dataV6Old = Map<String, dynamic>.from(dataV6);
    detailDatasOld = [];
    for (var item in detailDatas) {
      detailDatasOld.add(InvoiceItem(dataV6: Map<String, dynamic>.from(item.data)));
    }
  }
  /// Khôi phục dữ liệu cũ trước khi sửa đổi
  void resetChanges() {
    dataV6 = Map<String, dynamic>.from(dataV6Old);
    detailDatas = [];
    for (var item in detailDatasOld) {
      detailDatas.add(InvoiceItem(dataV6: Map<String, dynamic>.from(item.data)));
    }
  }
  
  /// mapping trường key = fieldV6, value = fieldAPI
  Map<String, String> mapper = {
    'MA_CT': 'maCt',
    'STT_REC': 'sttRec',
    'MA_DVCS': 'maDvcs',
    'NGAY_CT': 'ngayCt',
    'SO_CT': 'soCt',
    'MA_SONB': 'maSonb',
    'TEN_SONB': 'tenSonb',
    'MA_KH': 'maKh',
    'DIA_CHI': 'diaChi',
    'KIEU_POST': 'kieuPost',
    'TEN_POST': 'tenPost',
    'DIEN_GIAI': 'dienGiai',
    'TEN_KH': 'tenKh',
    'MA_SO_THUE': 'maSoThue',
    'USER_ID0': 'userId0',
    'DATE0': 'date0',
    'TIME0': 'time0',
    'DATE2': 'date2',
    'TIME2': 'time2',
    'USER_ID2': 'userId2',
    'RDEL': 'rdel',
    'REDIT': 'redit',
    
  };
  /// ánh xạ tên fieldV6 => fieldAPI, không phân biệt hoa thường (nhờ hàm H.getValue)
  String fieldAPI(String fieldV6){
    return H.getValue(mapper, fieldV6, defaultValue: fieldV6);
  }
  @override
  String getString(String fieldV6){
    return H.objectToString(H.getValue(dataV6, fieldV6, defaultValue: ''));
  }
  @override
  double getDouble(String fieldV6){
    return H.getDouble(dataV6, fieldV6, defaultValue: 0);
  }
  @override
  DateTime? getDate(String fieldV6){
    final value = H.getValue(dataV6, fieldV6);
    if (value is DateTime) return value;
    if (value is String) {
      return H.stringToDate(value, dateFormat: 'dd/MM/yyyy');
    }
    return null;
  }

  void addItem(InvoiceItem item) {
    detailDatas.add(item);
  }

  

  double get tSoLuong1 {
    double total = 0;
    for (var item in detailDatas) {
      total += item.getDouble('SO_LUONG1');
    }
    return total;
  }

  double get tSoLuong{
    double total = 0;
    for (var item in detailDatas) {
      total += item.getDouble('SO_LUONG');
    }
    return total;
  }
  double get tTien2 {
    double total = 0;
    for (var item in detailDatas) {
      total += item.getDouble('TIEN_NT2');
    }
    return total;
  }

  double get tThueNt {
    double total = 0;
    for (var item in detailDatas) {
      total += item.getDouble('THUE_NT');
    }
    return total;
  }

  double get tTT {
    return tTien2 + tThueNt;
  }

  void calculateTotals() {
    // In this simple model, totals are calculated on-the-fly using getters.
    // If you need to store totals, you can implement that logic here.
    
  }

  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setString(fieldV6, String text) {
    H.setValue(dataV6, fieldV6, text);
  }
  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setDouble(fieldV6, double value) {
    H.setDouble(dataV6, fieldV6, value);
  }
  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setDate(fieldV6, DateTime? value) {
    H.setValue(dataV6, fieldV6, value);
  }
  @override
  void setValue(fieldV6, dynamic value) {
    H.setValue(dataV6, fieldV6, value);
  }
  
  // void readMaster(Map<String, dynamic> data) {
  //   masterData = {};
  //   mapper.forEach((fieldV6, triTM) {
  //     var val = H.getValue(data, triTM);
  //     masterData[fieldV6] = val;
  //   });
  // }
  

  void readDetails({dynamic? dataAPI, dynamic? dataV6}) {
    detailDatas = [];
    if (dataV6 != null && dataV6 is List) {
      for (var item in dataV6) {
        if (item is Map<String, dynamic>) {
          //var sttRec1 = H.getValue(item, fieldAPI('stt_rec'), defaultValue: '');
          //if (sttrec == sttRec1)
          {
            detailDatas.add(InvoiceItem(dataV6: item));
          }
        }
      }
    }
    else if (dataAPI is List) {
      for (var item in dataAPI) {
        if (item is Map<String, dynamic>) {
          //var sttRec1 = H.getValue(item, fieldAPI('stt_rec'), defaultValue: '');
          //if (sttrec == sttRec1)
          {
            detailDatas.add(InvoiceItem(dataAPI: item));
          }
        }
      }
    }
  }
}