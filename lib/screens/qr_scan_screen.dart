import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
//import 'package:huuan_flutter_app1/item_list_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v6_invoice_mobile/models/scan_item.dart';
import 'package:v6_invoice_mobile/screens/setting_page.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final AudioPlayer _player = AudioPlayer(); // thêm player
  bool _isScanning = false;
  bool _autoScan = false; // ⚙️ đọc từ setting
  final List<ScanItem> _scannedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoScan = prefs.getBool('AutoScan') ?? false;
    });
  }
  Future<void> _saveAutoScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('AutoScan', value);
    setState(() => _autoScan = value);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_autoScan && !_isScanning) return; // chỉ xử lý khi đang quét
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    final existing = _scannedItems.where((e) => e.code == code).toList();

    if (_autoScan){ // tự scan chỉ lấy mã chưa quét.
      if (existing.isEmpty){
        setState(() {
          _scannedItems.add(ScanItem(code: code));
        });
        _playBeep('scanner-beep.mp3');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã quét: $code')),
        );
      }
    }
    else{ // bấm nút (_isScanning) mới scan
      _isScanning = false; // dừng sau khi quét xong 1 mã khi không auto
      if (existing.isEmpty) {        
        setState(() {
          _scannedItems.add(ScanItem(code: code));
        });
        _playBeep('scanner-beep.mp3');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã quét: $code')),
        );
      }
      else if (existing.isNotEmpty){
        setState(() {
          existing.first.quantity++;
        });
        _playBeep('beep.mp3');
      }
    }

    
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
  }
  Future<void> _playBeep(String filename) async {
    final path = 'assets/sounds/$filename';
    try {
      // Thử load asset trước để kiểm tra có tồn tại hay không
      await rootBundle.load(path);

      // Nếu không lỗi → phát âm thanh
      await _player.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // Nếu lỗi (asset không tồn tại hoặc không load được)
      debugPrint('⚠️ Không tìm thấy âm thanh: $path ($e)');
    }
  }

  //void _stopScan() {
  //  _cameraController.stop();
  //}

  void _deleteItem(ScanItem item) {
    setState(() {
      _scannedItems.remove(item);
    });
  }
  void _editItem(ScanItem item) async {
    final controller = TextEditingController(text: item.code);
    final newCode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa mã'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
    if (newCode != null && newCode.isNotEmpty) {
      setState(() => item.code = newCode);
    }
  }

  void _sendItem(ScanItem code) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đang gửi: $code')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR / Barcode')),
      body: Column(
        children: [
          // Nửa trên: Camera
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: MobileScanner(
                controller: _cameraController,
                onDetect: _onDetect,
              ),
            ),
          ),

          // 🔘 Nút Quét + AutoScan
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(_isScanning ? 'Đang quét...' : 'Bắt đầu quét'),
                  onPressed: (_isScanning || _autoScan) ? null : _startScan,
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('AutoScan'),
                    Switch(
                      value: _autoScan,
                      onChanged: (v) => _saveAutoScan(v),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách item quét được
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _scannedItems.length,
              itemBuilder: (context, index) {
                final item  = _scannedItems[index];
                return Slidable(
                  key: ValueKey(item.code),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editItem(item),
                        backgroundColor: Colors.orange,
                        icon: Icons.edit,
                        label: 'Sửa',
                      ),
                      SlidableAction(
                        onPressed: (_) => _sendItem(item),
                        backgroundColor: Colors.blue,
                        icon: Icons.send,
                        label: 'Gửi',
                      ),
                      SlidableAction(
                        onPressed: (_) => _deleteItem(item),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Xóa',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text(item.code),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: (){                          
                          setState(() {
                            if (item.quantity > 1) item.quantity--;
                          });
                        }),
                        Text('${item.quantity}'),
                        IconButton(
                          onPressed: (){setState(() {
                            item.quantity++;
                          });},
                          icon: const Icon(Icons.add)
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Thanh công cụ dưới cùng
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context, MaterialPageRoute(builder: (_)=>const SettingPage())
                ).then((_)=>_loadSettings());
              }),
            // IconButton(
            //   icon: const Icon(Icons.list_alt),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ItemListPage(items: _scannedItems),
            //       ),
            //     );
            //   },
            // ),
            IconButton(icon: const Icon(Icons.send), onPressed: _acceptItems),
          ],
        ),
      ),
    );
  }

  void _acceptItems() {
    Navigator.pop(context, _scannedItems);
  }
}
