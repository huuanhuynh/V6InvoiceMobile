import 'package:v6_invoice_mobile/h.dart';

import 'data_handler.dart';
import 'invoice_item.dart';

class Invoice implements DataHandler {
  String id;
  
  DateTime get date{return getDate('NGAY_CT') ?? DateTime.now();}
  Map<String, dynamic> amData = {};
  List<InvoiceItem> items = [];

  Invoice({
    required this.id,
    required String number,
    required DateTime date,
    List<InvoiceItem>? items,
  }) {
     items = items ?? [];
      setString('SO_CT', number);
      setDate('NGAY_CT', date);
  }

  @override
  String getString(String field){
    return H.objectToString(H.getValue(amData, field, defaultValue: ''));
  }
  @override
  double getDouble(String field){
    return H.getDouble(amData, field, defaultValue: 0);
  }
  @override
  DateTime? getDate(String field){
    final value = H.getValue(amData, field);
    if (value is DateTime) return value;
    if (value is String) {
      return H.stringToDate(value, dateFormat: 'dd/MM/yyyy');
    }
    return null;
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
    tSL1 = items.fold(0.0, (p, e) => p + e.getDouble('SO_LUONG1'));
    tTIEN2 = items.fold(0.0, (p, e) => p + e.getDouble('TIEN2'));
    tTHUE = items.fold(0.0, (p, e) => p + e.getDouble('THUE'));
    tTT = tTIEN2 + tTHUE;
  }

  @override
  void setString(fieldKey, String text) {
    amData[fieldKey.toUpperCase()] = text;
  }
  @override
  void setDouble(fieldKey, double value) {
    amData[fieldKey.toUpperCase()] = value;
  }
  @override
  void setDate(fieldKey, DateTime? value) {
    amData[fieldKey.toUpperCase()] = value;
  }
}