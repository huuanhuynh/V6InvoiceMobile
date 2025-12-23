abstract class DataHandler {
  void setString(String fieldV6, String value);
  void setDouble(String fieldName, double value);
  void setDate(String fieldName, DateTime? value);
  void setValue(String fieldV6, dynamic value);
  String getString(String fieldV6);
  double getDouble(String fieldName);
  DateTime? getDate(String fieldV6);
}