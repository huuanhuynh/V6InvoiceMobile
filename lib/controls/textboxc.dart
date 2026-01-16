// lib/controls/textboxc.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/data_handler.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';

abstract class TextBoxC extends TextEditingController {
  Map<String, dynamic>? data;
  String? dataKey;
  /// Filter khi lookup (cú pháp sql WHERE)
  String? advanceFilter;
  String fieldName = '';

  //String? vvar;
  bool noFilter = false;
  Map<String, dynamic>? lookupInfo;
  //Function? lookupComplete;
  //Function? onChanged;
  
  TextBoxC({super.text, this.fieldName = ''});

  setValue(dynamic value) {
      text = H.objectToString(value);
  }

  bool get haveData {
    if (data != null && text.toLowerCase() == dataKey?.toLowerCase()) {
      return true;
    }
    return false;
  }

  //bool get haveVvar => vvar != null && vvar!.isNotEmpty;

  void getVvarDataAndHandleOnChanged(String vvar, Function onChanged) async {
    var apiResponse = await ApiService.catalogs(vvar: vvar,
        filterValue: text.trim(),
        type: '2',
        pageIndex: 1,
        pageSize: 10,
        advance: advanceFilter ?? '',
      );
    if (apiResponse.data != null && apiResponse.data['items'] != null && apiResponse.data['items']!.length > 0) {
      if (apiResponse.data['items']!.length > 1) {
        //H.log('Warning: TextBoxC.getVvarDataAndHandleOnChanged - more than one record returned for vvar $vvar with filter $advanceFilter');
        String errorMsg = 'Có nhiều hơn một bản ghi trả về cho vvar $vvar với bộ lọc $advanceFilter';
        data = apiResponse.data['items']![0];
      }
      else{
        data = apiResponse.data['items']![0];
        dataKey = text.trim();
      }
    } else {
      data = null;
    }

    if (haveData) {
      onChanged(this, data);
    }
  }

  ///Gán giá trị từ control vào DataHandler Invoice theo fieldName => fieldV6
  void setValueTo(DataHandler handler);
  ///Lấy giá trị từ DataHandler Invoice gán vào control với fieldV6 = fieldName
  void loadValueFrom(DataHandler invoice);

}

///  String TextBox
class TextBoxS extends TextBoxC {
  TextBoxS({super.text, required super.fieldName});

  @override
  void setValueTo(DataHandler handler) {
    handler.setString(fieldName, text);
  }
  
  @override
  void loadValueFrom(DataHandler invoice) {
    text = invoice.getString(fieldName);
  }
}


///  Numeric TextBox
class TextBoxN extends TextBoxC {
  int decimalPlaces=0;
  TextBoxN({super.text, super.fieldName = '', this.decimalPlaces = 0});
  /// Lấy giá trị số đã convert từ TextBox
  Decimal get decimalValue {
    return H.objectToDecimal(text);
  }
  /// Gán giá trị số vào TextBox, chuỗi hiển thị tự động format theo decimalPlaces
  set decimalValue(Object? value) {
    text = H.objectToString(value, thousandSeparator: ' ', decDecimalPlaces: decimalPlaces);
  }

  @override
  setValue(value) {
    decimalValue = H.objectToDecimal(value);
  }

  @override
  void setValueTo(DataHandler handler) {
    handler.setDecimal(fieldName, decimalValue);
  }
  
  @override
  void loadValueFrom(DataHandler invoice) {
    final val = invoice.getDecimal(fieldName);
    text = H.objectToString(val);
  }
}


///  Date TextBox
class TextBoxD extends TextBoxC {
  String dateFormat;
  TextBoxD({super.text, super.fieldName = '', this.dateFormat = 'dd/MM/yyyy'});
  
  DateTime? get dateValue {
    if (text.isEmpty) return null;
    return H.stringToDate(text, dateFormat: dateFormat);
  }

  set dateValue(DateTime? value) {
    text = H.objectToString(value, dateFormat: dateFormat);
  }

  @override
  setValue(value) {
    dateValue = H.objectToDate(value);
  }
  
  @override
  void setValueTo(DataHandler handler) {
    handler.setDate(fieldName, dateValue);
  }
  
  @override
  void loadValueFrom(DataHandler invoice) {
    final val = invoice.getDate(fieldName);
    text = H.objectToString(val, dateFormat: dateFormat);
  }
}