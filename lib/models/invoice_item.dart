import 'package:v6_invoice_mobile/h.dart';

class InvoiceItem {
  final String id;
  final Map<String, dynamic> data;

  InvoiceItem({
    required this.id,
    required this.data,
  });

  dynamic operator [](String key) => data[key];
  void operator []=(String key, dynamic value) => data[key] = value;

  String getString(String field){
    return H.objectToString(H.getValue(data, field, defaultValue: ''));
  }

  Map<String, dynamic> toMap() => {'id': id, ...data};

  double getDouble(String field)
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