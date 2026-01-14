class KeyValuePair {
  final String key;
  final String value;

  KeyValuePair({
    required this.key,
    required this.value,
  });

  factory KeyValuePair.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug
    print('Parsing KeyValuePair from JSON: $json');

    return KeyValuePair(
      key: json['key']?.toString() ?? json['id']?.toString() ?? '',
      value: json['value']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  @override
  String toString() => value;
}
