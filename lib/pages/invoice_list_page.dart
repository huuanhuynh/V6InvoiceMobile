// lib/pages/invoice_list_page.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/core/config/app_colors.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/paging_info.dart';
import '../repository.dart';
import 'invoice_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});
  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
  static const routeName = '/invoicelist';
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  DateTime? from;
  DateTime? to;
  final _ctrlKeyword = TextEditingController();
  List<Invoice> _invList = [];
  //int _currentPage = 1;
  PagingInfo _pageInfo = PagingInfo();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    from = to = DateTime.now();
    from = from!.subtract(const Duration(days: 7));
    _apiSearch2();
  }

  // Hàm tìm kiếm khi người dùng nhấn nút Tìm
  void _search() {
    final repo = context.read<InvoiceRepository>();
    final list = repo.search(from: from, to: to, keyword: _ctrlKeyword.text);
    setState(() => _invList = list);
  }
  /// Tìm bằng hàm chung của Trí_TM
  void _apiSearch() async {
    final repo = context.read<InvoiceRepository>();
    final list = await repo.searchInvoiceList(from: from, to: to, searchValue: _ctrlKeyword.text);
    setState(() => _invList = list);
  }
  /// Tìm bằng hàm riêng cho SOH của V6 Invoice
  void _apiSearch2() async {
    _apiSearchSOH(null);
  }
  void _apiSearchSOH(int? pageIndex) async {
    int loadPage = pageIndex ?? 1;
    setState(() => loading = true);
    final repo = context.read<InvoiceRepository>();
    final list = await repo.searchInvoiceListSOH(from: from, to: to, searchValue: _ctrlKeyword.text, pageIndex: loadPage, pageSize: 10);
    _pageInfo = repo.pagingInfo;
    setState(() {
      loading = false;
      _invList = list;
    });
  }
  void _prevPage() {
    if (_pageInfo.hasPreviousPage) {
      _apiSearchSOH(_pageInfo.currentPage - 1);
    }
  }
  void _nextPage() {
    if (_pageInfo.hasMorePage) {
      _apiSearchSOH(_pageInfo.currentPage + 1);
    }
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: from ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => from = picked);
    }
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: to ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => to = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách đơn đặt hàng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickFrom,
                        child: InputDecorator(
                          decoration: _fieldDecoration('Từ ngày'),
                          child: Text(from != null ? '${from!.day}/${from!.month}/${from!.year}' : '—'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTo,
                        child: InputDecorator(
                          decoration: _fieldDecoration('Đến ngày'),
                          child: Text(to != null ? '${to!.day}/${to!.month}/${to!.year}' : '—'),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          from = null;
                          to = null;
                          _ctrlKeyword.clear();
                        });
                        _search();
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa bộ lọc',
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrlKeyword,
                      decoration:  _fieldDecoration('Từ khóa tìm kiếm'),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // ElevatedButton(
                  //   onPressed: _apiSearch,
                  //   child: const Text('Tìm'),
                  // ),
                  //const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _apiSearch2,
                    child: const Text('Tìm SOH'),
                  )
                ])
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _search(),
              child: ListView.builder(
                itemCount: _invList.length,
                itemBuilder: (context, idx) {
                  final inv = _invList[idx];
                  return _buildListTile(inv);
                },
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: ()=> createNewInvoice('SOH'),
            label: const Text('Thêm'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          // FloatingActionButton(
          //   heroTag: 'refresh',
          //   onPressed: _search,
          //   child: const Icon(Icons.refresh),
          // ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cột trái: hiển thị lỗi (bấm để copy)
          

          // Cột giữa: số trang
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${_pageInfo.rowCount} dòng. Trang ${_pageInfo.currentPage}/${_pageInfo.totalPages} của ${_pageInfo.totalRows} dòng'),
          ),

          // Cột phải: điều hướng
          Row(
            children: [
              ElevatedButton(
                onPressed: _pageInfo.hasPreviousPage && !loading ? _prevPage : null,
                child: const Text('← Trước'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _pageInfo.hasMorePage && !loading ? _nextPage : null,
                child: const Text('Sau →'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  InputDecoration _fieldDecoration(
    String label, {
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.secondary),
      contentPadding: const EdgeInsets.fromLTRB(5, 2, 2, 2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.onPrimary,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  Future<void> createNewInvoice(String mact) async {
    //var newSttRec = ApiService.getNewSttRec(mact);
    final newInv = Invoice(
      dataAPI: null,
    );
    // Thiết lập các giá trị mặc định cho hóa đơn mới
    newInv.setString("MA_CT", mact);
    newInv.setDate("NGAY_CT", DateTime.now());
    newInv.setString("MA_DVCS", AppSession.madvcs!);
    newInv.setString("KIEU_POST", "0");
    newInv.setString("MA_NT", "VND");
    newInv.setDecimal("TY_GIA", 1.toDecimal());
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(mact: mact, invoice: newInv, mode: InvoiceMode.add),
      ),
    );
    _search();
  }

  Future<void> editCurrentInvoice(String mact, Invoice inv) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(mact: 'SOH', invoice: inv, mode: inv.canEdit ? InvoiceMode.edit : InvoiceMode.view),
      ),
    );
    // Sau khi edit thông tin, _search sẽ cập nhập lại trạng thái danh sách
    _search();
  }

  void _invTap(Invoice inv) {
      editCurrentInvoice('SOH', inv);
  }
  
  String _buildInvText2(Invoice inv) {
    String result = '';
    result += inv.getString('TEN_KH');
    if (inv.detailDatas.isNotEmpty) {
      result += ' ••• ${inv.detailDatas[0].getString('TEN_VT')} x ${inv.detailDatas[0].getDecimal('SO_LUONG').toStringAsFixed(0)}';
      if (inv.detailDatas.length > 1) {
        result += ' .....';
      }
    }
    return result;
  }
  
  _buildListTile(Invoice inv) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: inv.canEdit ? AppColors.primary : AppColors.bottomTabsBackground,
        child: Text(inv.tSoLuong.toStringAsFixed(0), style: const TextStyle(color: Colors.white)),
      ),
      title: Text('${inv.soCt} • ${inv.ngayCt.toIso8601String().split('T')[0]}'),
      subtitle: Text(_buildInvText2(inv)),
      //trailing: Text(inv.tSoLuong.toStringAsFixed(0)), //Text bên phải.
      onTap: ()=> _invTap(inv),
    );
  }

  
  
}
