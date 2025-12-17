// lib/pages/invoice_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/core/config/app_colors.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
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
  List<Invoice> _results = [];
  

  @override
  void initState() {
    super.initState();
    from = to = DateTime.now();
    _fullSearch();
  }

  // Hàm tìm kiếm khi người dùng nhấn nút Tìm
  void _search() {
    final repo = context.read<InvoiceRepository>();
    final list = repo.search(from: from, to: to, keyword: _ctrlKeyword.text);
    setState(() => _results = list);
  }

  void _fullSearch() async {
    final repo = context.read<InvoiceRepository>();
    final list = await repo.searchInvoiceList(from: from, to: to, searchValue: _ctrlKeyword.text);
    setState(() => _results = list);
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
      appBar: AppBar(title: const Text('Danh sách Chứng từ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrlKeyword,
                      decoration:  _fieldDecoration('Từ khóa tìm kiếm'),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _fullSearch,
                    child: const Text('Tìm'),
                  )
                ]),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _search(),
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, idx) {
                  final inv = _results[idx];
                  return ListTile(
                    title: Text(inv.soCt),
                    subtitle: Text('${inv.getString('TEN_KH')} • ${inv.ngayCt.toIso8601String().split('T')[0]}'),
                    trailing: Text(inv.tTT.toStringAsFixed(0)),
                    onTap: ()=> editCurrentInvoice('SOH', inv),
                  );
                },
              ),
            ),
          )
        ],
      ),
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
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: _search,
            child: const Icon(Icons.refresh),
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
    //newInv.setString("STT_REC", newSttRec);
    newInv.setString("MA_DVCS", AppSession.madvcs!);
    newInv.setString("KIEU_POST", "0");
    newInv.setDate("NGAY_CT", DateTime.now());
    newInv.setString("MA_NT", "VND");
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
        builder: (_) => InvoicePage(mact: 'SOH', invoice: inv, mode: InvoiceMode.edit),
      ),
    );
    _search();
  }
}
