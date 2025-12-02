import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool? _autoScan; // dùng nullable để biết đã load chưa

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('AutoScan') ?? false;
    setState(() => _autoScan = value);
  }

  Future<void> _saveSettings() async {
    if (_autoScan == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('AutoScan', _autoScan!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: _autoScan == null
          ? const Center(child: CircularProgressIndicator()) // chờ load xong
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Tự động quét (AutoScan)'),
                  subtitle: const Text('Tự động nhận mã khi camera phát hiện'),
                  value: _autoScan!,
                  onChanged: (val) {
                    setState(() => _autoScan = val);
                    _saveSettings();
                  },
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
    );
  }
}
