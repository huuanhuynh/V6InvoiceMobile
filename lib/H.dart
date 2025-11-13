import 'dart:math';
import 'package:intl/intl.dart';

/// Lớp hỗ trợ chuyển đổi và định dạng dữ liệu tương tự như bản C#
class H {
  static const String systemDecimalSymbol = '.'; // mặc định hệ thống
  static const _defaultDateFormat = 'dd/MM/yyyy';

  /// Chuyển số thành chuỗi có định dạng
  static String numberToString(
    num number,
    int decimals,
    String decimalSeparator, {
    String thousandSeparator = ' ',
    bool show0 = false,
  }) {
    if (number == 0 && !show0) return '';
    if (decimalSeparator.isEmpty) {
      throw Exception('DecimalSeparator empty.');
    }

    final fmt = NumberFormat()
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;

    var numberString = fmt.format(number);
    numberString = numberString.replaceAll('.', '#');
    numberString = numberString.replaceAll(',', thousandSeparator);
    numberString = numberString.replaceAll('#', decimalSeparator);
    return numberString;
  }

  static String numberToStringObj(
    dynamic number,
    int decimals,
    String decimalSeparator, {
    String thousandSeparator = ' ',
    bool show0 = false,
  }) {
    return numberToString(objectToDecimal(number), decimals, decimalSeparator,
        thousandSeparator: thousandSeparator, show0: show0);
  }

  /// Chuẩn hoá chuỗi số có dấu , hoặc . thành đúng dấu hệ thống
  static String stringToSystemDecimalSymbolStringNumber(String numberString) {
    numberString = numberString.trim().replaceAll(' ', '');
    final indexOfComma = numberString.indexOf(',');
    final indexOfDot = numberString.indexOf('.');
    if (indexOfComma > 0 && indexOfDot > 0 && indexOfComma < indexOfDot) {
      numberString = numberString.replaceAll(',', '');
    } else if (indexOfDot > 0 && indexOfComma > 0 && indexOfDot < indexOfComma) {
      numberString = numberString.replaceAll('.', '');
    }
    return numberString
        .replaceAll(',', systemDecimalSymbol)
        .replaceAll('.', systemDecimalSymbol);
  }

  /// Chuyển object thành DateTime?
  static DateTime? objectToDate(dynamic o, {String dateFormat = _defaultDateFormat}) {
    if (o == null || o == 0 || o.toString().trim().isEmpty) return null;

    if (o is DateTime) {
      return o.year <= 1900 ? null : o;
    }

    final t = o.toString().trim();

    // ISO 2023-04-12T00:00:00
    if (t.contains('T') && t.indexOf('T') > 6) {
      return DateTime.tryParse(t);
    }

    // dd/MM/yyyy
    try {
      final fmt = DateFormat(dateFormat);
      return fmt.parseStrict(t);
    } catch (_) {
      // fallback
      final parts = t.split(RegExp(r'[\/\-]'));
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]) ?? 1;
        final m = int.tryParse(parts[1]) ?? 1;
        final y = int.tryParse(parts[2]) ?? DateTime.now().year;
        return DateTime(y, m, d);
      }
    }

    return null;
  }

  static DateTime objectToFullDateTime(dynamic o, {String dateFormat = _defaultDateFormat}) {
    return objectToDate(o, dateFormat: dateFormat) ?? DateTime.now();
  }

  /// 1 / true / yes
  static bool objectToBool(dynamic o) {
    if (o == null) return false;
    final d = objectToDecimal(o);
    if (d == 1) return true;
    final s = objectToString(o).trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static double objectToDecimal(dynamic o) {
    if (o == null) return 0;
    if (o is bool) return o ? 1 : 0;
    if (o is num) return o.toDouble();
    if (o is DateTime) return o.dayOfYear.toDouble();

    final str = stringToSystemDecimalSymbolStringNumber(o.toString());
    return double.tryParse(str) ?? 0;
  }

  static double objectToFloat(dynamic o) => objectToDecimal(o);

  static int objectToInt(dynamic o) {
    if (o == null) return 0;
    if (o is bool) return o ? 1 : 0;
    if (o is int) return o;
    if (o is num) return o.toInt();
    if (o is DateTime) return o.dayOfYear;
    final str = stringToSystemDecimalSymbolStringNumber(o.toString());
    return int.tryParse(str) ?? 0;
  }

  static int objectToInt64(dynamic o) => objectToInt(o);

  /// Chuyển o thành chuỗi có định dạng
  static String objectToString(
    dynamic o, {
    String dateFormat = 'dd/MM/yyyy',
    String thousandSeparator = ' ',
    int decDecimalPlaces = 2,
  }) {
    if (o == null) return '';

    if (o is num) {
      // Nếu là số nguyên (ví dụ 100 hoặc 100.0)
      if (o is int) {
        return numberToString(o, 0, ',', thousandSeparator: thousandSeparator, show0: true);
      } else {
        return numberToString(o, decDecimalPlaces, ',', thousandSeparator: thousandSeparator, show0: true);
      }
    }

    if (o is DateTime) {
      return DateFormat(dateFormat).format(o);
    }

    if (o is List) {
      return o.join(';');
    }

    return o.toString();
  }

  static DateTime stringToDate(String s, {String dateFormat = 'd/M/yyyy'}) {
    try {
      if (s.contains('T') && s.indexOf('T') > 6) {
        return DateTime.parse(s);
      }
      return DateFormat(dateFormat).parseStrict(s);
    } catch (_) {
      return DateTime(1900, 1, 1);
    }
  }

  static double stringToDecimal(String s) {
    if (s.isEmpty) return 0;
    final clean = stringToSystemDecimalSymbolStringNumber(s);
    return double.tryParse(clean) ?? 0;
  }

  static dynamic objectTo(Type type, dynamic value) {
    if (type == String) return objectToString(value);
    if (type == bool) return objectToBool(value);
    if (type == DateTime) return objectToDate(value);
    if (type == int) return objectToInt(value);
    if (type == double) return objectToDecimal(value);
    return value;
  }

  /// lấy giá trị trong map với key không phân biệt hoa thường
  static dynamic getValue(
    Map<String, dynamic> map, 
    String key, {
    dynamic defaultValue,
  }) {
    key = key.toLowerCase();
    for (final mapKey in map.keys) {
      if (mapKey.toLowerCase() == key) {
        return map[mapKey];
      }
    }

    // 5. Nếu không tìm thấy, trả về giá trị mặc định
    return defaultValue;
  }

  Map<String, dynamic> normalizeMapKeys(Map<String, dynamic> originalMap) {
    final Map<String, dynamic> normalizedMap = {};
    
    originalMap.forEach((key, value) {
      // Thêm key đã chuyển thành chữ thường vào Map mới
      normalizedMap[key.toLowerCase()] = value;
    });
    
    return normalizedMap;
  }


}

extension _DateDayOfYear on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}
