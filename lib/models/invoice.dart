import 'package:decimal/decimal.dart';
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
  Decimal getDecimal(String fieldV6){
    return H.getDecimal(dataV6, fieldV6);
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

  

  Decimal get tSoLuong1 {
    Decimal total = Decimal.zero;
    for (var item in detailDatas) {
      total += item.getDecimal('SO_LUONG1');
    }
    return total;
  }

  Decimal get tSoLuong{
    Decimal total = Decimal.zero;
    for (var item in detailDatas) {
      total += item.getDecimal('SO_LUONG');
    }
    return total;
  }
  Decimal get tTien2 {
    Decimal total = Decimal.zero;
    for (var item in detailDatas) {
      total += item.getDecimal('TIEN_NT2');
    }
    return total;
  }

  Decimal get tThueNt {
    Decimal total = Decimal.zero;
    for (var item in detailDatas) {
      total += item.getDecimal('THUE_NT');
    }
    return total;
  }

  Decimal get tTT {
    return tTien2 + tThueNt;
  }

  bool get isCkChung{
    return H.objectToBool(H.getValue(dataV6, 'LOAI_CK', defaultValue: 0));
  }
  bool get isThueChung{
    return H.objectToBool(H.getValue(dataV6, 'SUA_THUE', defaultValue: 0));
  }

  /// Tính tổng thanh toán và cập nhật vào dataV6, phải đảm bảo các giá trị liên quan (ty_gia, thue_suat ) đã cập nhật.
  void tinhTongThanhToan() {
    try {
      Decimal tyGia = H.getDecimal(dataV6, 'TY_GIA', defaultValue: 1);
      // Tính tổng values, 
      Decimal tTienHangNT = Decimal.zero;
      Decimal tThueNT = Decimal.zero;
      Decimal tCkNT = Decimal.zero;
      Decimal tSoLuong = Decimal.zero;
      for (var item in detailDatas) {
        tTienHangNT += H.getDecimal(item.data, 'TIEN_NT', defaultValue: 0);
        tThueNT += H.getDecimal(item.data, 'THUE_NT', defaultValue: 0);
        tCkNT += H.getDecimal(item.data, 'CK_NT', defaultValue: 0);
        tSoLuong += H.getDecimal(item.data, 'SO_LUONG', defaultValue: 0);
      }
      // Nhân tỷ giá
      Decimal tTienHang = tTienHangNT * tyGia;
      Decimal tThue = tThueNT * tyGia;
      Decimal tCk = tCkNT * tyGia;
      // Tính chiết khấu
      if (isCkChung){
        Decimal ckChungPercent = H.getDecimal(dataV6, 'PT_CK', defaultValue: 0);
        tCkNT = (tTienHangNT * ckChungPercent) * Decimal.parse("0.01");
        tCk = tCkNT * tyGia;
      }
      // Tính giảm giá

      // Tính thuế
      if (isThueChung){
        tThueNT = (tTienHangNT - tCkNT) * (H.getDecimal(dataV6, 'THUE_SUAT', defaultValue: 0) * Decimal.parse("0.01"));
      }
      // Cập nhật tổng vào dataV6
      H.setValue(dataV6, 'T_TIEN_NT2', tTienHangNT);
      H.setValue(dataV6, 'T_TIEN2', tTienHang);
      H.setValue(dataV6, 'T_THUE_NT', tThueNT);
      H.setValue(dataV6, 'T_THUE', tThue);
      H.setValue(dataV6, 'T_CK_NT', tCkNT);
      H.setValue(dataV6, 'T_CK', tCk);

    } catch (e) {
      //print('Error in calculateTotals: $e');
    }
  }

  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setString(fieldV6, String text) {
    H.setValue(dataV6, fieldV6, text);
  }
  /// Gán giá trị vào Invoice theo fieldV6, dataAPI sẽ được mapping sang fieldAPI.
  @override
  void setDecimal(fieldV6, Decimal value) {
    H.setDecimal(dataV6, fieldV6, value);
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