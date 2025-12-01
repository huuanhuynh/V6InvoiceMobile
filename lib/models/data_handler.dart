abstract class DataHandler {
  void setString(String fieldName, String value);
  void setDouble(String fieldName, double value);
  void setDate(String fieldName, DateTime? value);
  String getString(String fieldName);
  double getDouble(String fieldName);
  DateTime? getDate(String fieldName);
}