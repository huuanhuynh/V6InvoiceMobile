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

  double get T_SL =>
      items.fold(0.0, (p, e) => p + e.valueOf('SO_LUONG'));

  double get T_TIEN2 =>
      items.fold(0.0, (p, e) => p + e.valueOf('TIEN2'));

  double get T_THUE =>
      items.fold(0.0, (p, e) => p + e.valueOf('THUE'));

  double get totalPayable => T_TIEN2 + T_THUE;
}
