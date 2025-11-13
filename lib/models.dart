import 'package:http/src/response.dart';
import 'package:v6_invoice_mobile/H.dart';

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

  String? stringOf(String field){
    if (data.containsKey(field)) return data[field];
    return null;
  }
  Map<String, dynamic> toMap() => {'id': id, ...data};
  double valueOf(String field)
  {
    if (data.containsKey(field)) return H.objectToDecimal(data[field]);
    return 0;
  }

  InvoiceItem copyWith({String? id, Map<String, dynamic>? data}) {
    return InvoiceItem(
      id: id ?? this.id,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }
}

class InvoiceItem_Old {
  String id;
  String productCode;
  String description;
  double unitPrice;
  double quantity;
  double taxRate; // e.g. 0.1 for 10%

  InvoiceItem_Old({
    required this.id,
    required this.productCode,
    this.description = '',
    required this.unitPrice,
    required this.quantity,
    this.taxRate = 0.0,
  });

  double get lineTotal => unitPrice * quantity;
  double get taxAmount => lineTotal * taxRate;
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
