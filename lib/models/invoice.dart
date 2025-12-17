import 'package:v6_invoice_mobile/h.dart';

import 'data_handler.dart';
import 'invoice_item.dart';

class Invoice implements DataHandler {
  String get sttrec => H.objectToString(H.getValue(dataAPI, 'sttRec', defaultValue: ''));
  DateTime get ngayCt{return getDate('NGAY_CT') ?? DateTime.now();}
  /// Dữ liệu gốc theo API. Dữ liệu gán vào thông qua fieldV6 sẽ được mapping sang fieldAPI, Dữ liệu sẵn sàng để gửi lên API.
  Map<String, dynamic> dataAPI = {};
  List<InvoiceItem> detailDatas = [];

  /// Khởi tạo Invoice từ dữ liệu API, nếu không có dữ liệu thì tạo mới rỗng, chi tiết là List<Map<String,dynamic>> trong key 'ads'
  Invoice({Map<String, dynamic>? dataAPI})
  {
      this.dataAPI = dataAPI ?? {};
      
      if (this.dataAPI['ads'] != null) {
        readDetails(this.dataAPI['ads']);
      }
      else {
        detailDatas = [];
      }
  }

  List<Map<String,dynamic>> get getDetailDatasForAPI {
    List<Map<String,dynamic>> result = [];
    for (var item in detailDatas) {
      result.add(item.toDataAPI());
    }
    return result;
    // var ads = H.getValue(dataAPI, 'ads');
    // if (ads == null) {
    //   ads = [];
    //   dataAPI['ads'] = ads;
    // }
    // return ads;
  }

  void resetChanges() {
    //readMaster(dataTriTM);
    if (dataAPI['ads'] != null) {
      readDetails(dataAPI['ads']);
    }
    else {
      detailDatas = [];
    }
  }
  
  /// mapping trường key = fieldV6, value = fieldAPI
  Map<String, String> mapper = {
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
    return H.objectToString(H.getValue(dataAPI, fieldAPI(fieldV6), defaultValue: ''));
  }
  @override
  double getDouble(String fieldV6){
    return H.getDouble(dataAPI, fieldAPI(fieldV6), defaultValue: 0);
  }
  @override
  DateTime? getDate(String fieldV6){
    final value = H.getValue(dataAPI, fieldAPI(fieldV6));
    if (value is DateTime) return value;
    if (value is String) {
      return H.stringToDate(value, dateFormat: 'dd/MM/yyyy');
    }
    return null;
  }

  

  void addItem(InvoiceItem item) {
    detailDatas.add(item);
    //Map<String,dynamic> ad = item.toPostData();
    //getDetailDatasForAPI.add(ad);
  }

  String get soCt{
    return getString('SO_CT');
  }
  double tSL1 = 0;
  double tTIEN2 = 0;
  double tTHUE = 0;
  double tTT = 0;

  void calculateTotals() {
    // In this simple model, totals are calculated on-the-fly using getters.
    // If you need to store totals, you can implement that logic here.
    tSL1 = 0;
    for (var item in detailDatas) {
      tSL1 += item.getDouble('SO_LUONG1');
    }
    tTIEN2 = 0;
    for (var item in detailDatas) {
      tTIEN2 += item.getDouble('TIEN2');
    }
    tTHUE = 0;
    for (var item in detailDatas) {
      tTHUE += item.getDouble('THUE');
    }
    tTT = tTIEN2 + tTHUE;
  }

  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setString(fieldV6, String text) {
    dataAPI[fieldAPI(fieldV6)] = text;
  }
  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setDouble(fieldV6, double value) {
    dataAPI[fieldAPI(fieldV6)] = value;
  }
  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setDate(fieldV6, DateTime? value) {
    dataAPI[fieldAPI(fieldV6)] = value;
  }
  
  // void readMaster(Map<String, dynamic> data) {
  //   masterData = {};
  //   mapper.forEach((fieldV6, triTM) {
  //     var val = H.getValue(data, triTM);
  //     masterData[fieldV6] = val;
  //   });
  // }
  

  void readDetails(ads) {
    detailDatas = [];
    if (ads is List) {
      for (var item in ads) {
        if (item is Map<String, dynamic>) {
          detailDatas.add(InvoiceItem(triTMdata: item));
        }
      }
    }
  }
}