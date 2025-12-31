import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v6_invoice_mobile/custom_scroll_behavior.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
import 'package:v6_invoice_mobile/h.dart';

class CatalogPage extends StatefulWidget {
  final String fvvar;
  final String type;
  final String? filterValue;
  final String advance;

  const CatalogPage({
    super.key,
    required this.fvvar,
    required this.type,
    this.filterValue,
    this.advance = '',
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool loading = false;
  String? error;
  int pageIndex = 1; int totalPages = 0; int totalRows = 0;
  int pageSize = 20;
  bool hasMorePage = false; bool hasPreviousPage = false;
  
  Map<String, dynamic>? selectedData;
  Map<String, dynamic> lookupInfo = {};
  
  String filterValue = '';
  final TextEditingController _filterCtrl = TextEditingController();
  final ValueNotifier<List<Map<String, dynamic>>> itemsNotifier = ValueNotifier([]);
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    if (widget.filterValue != null && widget.filterValue!.isNotEmpty) {
      filterValue = widget.filterValue!;
    }
    _filterCtrl.text = filterValue;
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _filterCtrl.dispose();
    super.dispose();
  }

  // Debounced load: chờ 400ms sau lần gõ cuối cùng mới gọi API
  void _onFilterChanged(String value) {
    filterValue = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      pageIndex = 1; // reset về trang 1 khi filter thay đổi
      _loadData();
    });
    // NOTE: Không gọi setState ở đây để tránh mất focus; chỉ cập nhật controller.
  }

  Future<void> _loadData() async {
    loading = true;
    error = null;
    if (mounted) setState(() {});
    try {
      final apiResponse = await ApiService.catalogs(
        vvar: widget.fvvar,
        filterValue: filterValue,
        type: widget.type,
        pageIndex: pageIndex,
        pageSize: pageSize,
        advance: widget.advance,
      );
      if (apiResponse.error == null){
        final parsed = apiResponse.data;
        List<dynamic> listData = parsed is List ? parsed : (parsed['items'] ?? parsed['data'] ?? []);
        //int pageNumber = parsed['pageNumber'];
        totalPages = parsed['totalPages'];
        totalRows = parsed['totalRows'];
        hasMorePage = parsed['hasNextPage'];
        hasPreviousPage = parsed['hasPreviousPage'];
        lookupInfo = parsed['lookupInfo'] ?? {};
        itemsNotifier.value = List.from(listData); // chỉ cập nhật bảng
      }
      else{
        error = apiResponse.error;
        totalPages = 0; hasMorePage = false; hasPreviousPage = false;
        itemsNotifier.value = []; // chỉ cập nhật bảng
      }
    } catch (e) {
      error = e.toString();
      itemsNotifier.value = [];
    } finally {
      loading = false;
      if (mounted) setState(() {});
    }
  }

  void _nextPage() {
    setState(() => pageIndex++);
    _loadData();
  }

  void _prevPage() {
    if (pageIndex > 1) {
      setState(() => pageIndex--);
      _loadData();
    }
  }

  void _viewItem() {
    if (selectedData != null) {
      Navigator.pushNamed(context, '/catalog/view', arguments: selectedData);
    }
  }

  void _editItem() {
    if (selectedData != null) {
      Navigator.pushNamed(context, '/catalog/edit', arguments: selectedData);
    }
  }

  void _selectItem() {
    if (selectedData != null) {
      Navigator.pop(context, {"selectedData": selectedData, "lookupInfo": lookupInfo});
    } else {
      // Thông báo nếu chưa chọn item nào
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một mục.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorSelected = Theme.of(context).colorScheme.primary.withValues(alpha: 30);

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh mục: ${widget.fvvar}'),
        actions: [
          // NÚT NHẬN MỚI
          IconButton(
           icon: const Icon(Icons.check), 
             onPressed: selectedData != null ? _selectItem : null, // Chỉ cho phép nhận khi đã chọn
          ),
          IconButton(icon: const Icon(Icons.visibility), onPressed: _viewItem),
          IconButton(icon: const Icon(Icons.edit), onPressed: _editItem),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _filterCtrl,
              decoration: InputDecoration(
                labelText: 'Lọc dữ liệu',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filterCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterCtrl.clear();
                          _onFilterChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onFilterChanged,
            ),
          ),

          if (loading)
            const LinearProgressIndicator(minHeight: 2),

          // 👇 Chỉ phần này rebuild khi itemsNotifier.value thay đổi
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: itemsNotifier,
              builder: (context, items, _) {
                if (error != null) {
                  return Center(child: Text('Lỗi: $error'));
                } else if (items.isEmpty && !loading) {
                  return const Center(child: Text('Không có dữ liệu'));
                }

                return ScrollConfiguration(
                  behavior: AppScrollBehavior(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: _buildColumns(items),
                        rows: _buildRows(items, colorSelected),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }



  List<DataColumn> _buildColumns(List<dynamic> items) {
    if (items.isEmpty) {
      return [const DataColumn(label: Text('Chưa có dữ liệu'))];
    }
    //if (items.isEmpty) return [];
    final first = items.first as Map<String, dynamic>;
    return first.keys.map((k) => DataColumn(label: Text(k))).toList();
  }

  List<DataRow> _buildRows(List<dynamic> items, Color selectedColor) {
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final isSelected = selectedData == item;

      // 1. TẠO CÁC Ô DỮ LIỆU ĐÃ BỌC BẰNG GESTUREDETECTOR
      final cellsWithTap = map.values.map((v) {
        return DataCell(
          onTap: () => {
            if (isSelected){
              _selectItem()
            }
            else{
              setState(() {
                selectedData = item; // Chọn hàng này khi nhấn vào ô
              }),
            }
          },
          // Bọc nội dung bằng GestureDetector để bắt sự kiện double-tap
          GestureDetector(
            // Kích hoạt khi có double-click/double-tap
            onDoubleTap: () {
              // 1. Cập nhật selectedItem nếu chưa được chọn (cần setState)
              // LƯU Ý: Vì đang ở trong hàm map, ta cần đảm bảo logic setState là an toàn.
              // Tốt nhất là gọi setState để cập nhật selectedItem, sau đó gọi _selectItem.
              setState(() {
                selectedData = item; // Chọn hàng này
                // Ngay sau khi setState, gọi _selectItem
                _selectItem();
              });
            },
            // Đảm bảo nội dung căn chỉnh và chiếm đủ không gian DataCell
            child: Container(
              alignment: Alignment.centerLeft, 
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(H.objectToString(v)),
            ),
          ),
        );
      }).toList();


      return DataRow(
        color: WidgetStatePropertyAll(isSelected ? selectedColor : null),
        selected: isSelected,
        // 2. GIỮ onSelectChanged cho chức năng chọn một lần
        onSelectChanged: (_) {
          setState(() => selectedData = item);
        },
        
        // 3. Sử dụng danh sách DataCell đã tích hợp double-tap
        cells: cellsWithTap,
      );
    }).toList();
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cột trái: hiển thị lỗi (bấm để copy)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (error != null && error!.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: error!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã copy lỗi vào clipboard')),
                  );
                }
              },
              child: Text(
                error != null ? 'Error: $error' : '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),

          // Cột giữa: số trang
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${itemsNotifier.value.length} dòng. Trang $pageIndex/$totalPages của $totalRows dòng'),
          ),

          // Cột phải: điều hướng
          Row(
            children: [
              ElevatedButton(
                onPressed: hasPreviousPage && !loading ? _prevPage : null,
                child: const Text('← Trước'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: hasMorePage && !loading ? _nextPage : null,
                child: const Text('Sau →'),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
