// lib/controls/textboxc.dart
import 'package:flutter/widgets.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/data_handler.dart';

abstract class TextBoxC extends TextEditingController {
  dynamic tag;
  String fieldName = '';
  TextBoxC({super.text, this.fieldName = ''});
  ///Gán giá trị từ control vào DataHandler(Invoice)
  void setValueTo(DataHandler handler);
  ///Lấy giá trị từ DataHandler(Invoice) gán vào control
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
  double get doubleValue {
    return H.stringToDouble(text);
  }
  set setValue(Object? value) {
    text = H.objectToString(value, thousandSeparator: ' ', decDecimalPlaces: decimalPlaces);
  }

  @override
  void setValueTo(DataHandler handler) {
    handler.setDouble(fieldName, doubleValue);
  }
  
  @override
  void loadValueFrom(DataHandler invoice) {
    final val = invoice.getDouble(fieldName);
    text = H.objectToString(val);
  }
}
///  Date TextBox
class TextBoxD extends TextBoxC {
  String dateFormat;
  TextBoxD({super.text, super.fieldName = '', this.dateFormat = 'dd/MM/yyyy'});
  
  DateTime? get getDate {
    if (text.isEmpty) return null;
    return H.stringToDate(text, dateFormat: dateFormat);
  }
  
  @override
  void setValueTo(DataHandler handler) {
    handler.setDate(fieldName, getDate);
  }
  
  @override
  void loadValueFrom(DataHandler invoice) {
    final val = invoice.getDate(fieldName);
    text = H.objectToString(val, dateFormat: dateFormat);
  }
}