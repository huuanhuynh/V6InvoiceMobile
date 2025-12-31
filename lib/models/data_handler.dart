import 'package:decimal/decimal.dart';

abstract class DataHandler {
  void setString(String fieldV6, String value);
  void setDecimal(String fieldName, Decimal value);
  void setDate(String fieldName, DateTime? value);
  void setValue(String fieldV6, dynamic value);
  String getString(String fieldV6);
  Decimal getDecimal(String fieldV6);
  DateTime? getDate(String fieldV6);
}