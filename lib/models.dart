// ignore_for_file: non_constant_identifier_names

import 'package:http/http.dart';
import 'package:v6_invoice_mobile/h.dart';

class ApiResponse{
  dynamic data;
  String? error;
  Response? response;
}

class InvoiceItem {
  final String id;
  final Map<String, dynamic> data;

  InvoiceItem({
    required this.id,
    required this.data,
  });

  dynamic operator [](String key) => data[key];
  void operator []=(String key, dynamic value) => data[key] = value;

  String stringOf(String field){
    return H.getValue(data, field, defaultValue: '');
  }

  Map<String, dynamic> toMap() => {'id': id, ...data};

  double valueOf(String field)
  {
    return H.getDouble(data, field, defaultValue: 0);
  }

  InvoiceItem copyWith({String? id, Map<String, dynamic>? data}) {
    return InvoiceItem(
      id: id ?? this.id,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }
}


class Invoice {
  String id;
  String number;
  DateTime date;
  String customerName;
  String notes;
  List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    this.customerName = '',
    this.notes = '',
    List<InvoiceItem>? items,
  }) : items = items ?? [];

  double T_SL1 = 0;
      //=> items.fold(0.0, (p, e) => p + e.valueOf('SO_LUONG'));

  double T_TIEN2 = 0;

  double T_THUE = 0;

  double T_TT = 0;

  void calculateTotals() {
    // In this simple model, totals are calculated on-the-fly using getters.
    // If you need to store totals, you can implement that logic here.
    T_SL1 = items.fold(0.0, (p, e) => p + e.valueOf('SO_LUONG1'));
    T_TIEN2 = items.fold(0.0, (p, e) => p + e.valueOf('TIEN2'));
    T_THUE = items.fold(0.0, (p, e) => p + e.valueOf('THUE'));
    T_TT = T_TIEN2 + T_THUE;
  }
}
