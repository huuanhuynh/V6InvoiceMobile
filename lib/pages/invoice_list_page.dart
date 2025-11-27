// lib/pages/invoice_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository.dart';
import '../models.dart';
import 'invoice_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});
  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  DateTime? from;
  DateTime? to;
  final _ctrlKeyword = TextEditingController();
  List<Invoice> _results = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    final repo = context.read<InvoiceRepository>();
    final list = repo.search(from: from, to: to, keyword: _ctrlKeyword.text);
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
                      decoration: const InputDecoration(
                        labelText: 'Từ khóa (số/họ tên/ghi chú)',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _search,
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
                          decoration:
                              const InputDecoration(labelText: 'Từ ngày'),
                          child: Text(
                              from != null ? '${from!.day}/${from!.month}/${from!.year}' : '—'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTo,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Đến ngày'),
                          child: Text(
                              to != null ? '${to!.day}/${to!.month}/${to!.year}' : '—'),
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
                    title: Text(inv.number),
                    subtitle: Text('${inv.customerName} • ${inv.date.toIso8601String().split('T')[0]}'),
                    trailing: Text(inv.T_TT.toStringAsFixed(0)),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoicePage(mact: 'SOH', invoice: inv), // sửa
                        ),
                      );
                      _search();
                    },
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
            onPressed: () async {
              final newInv = Invoice(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                date: DateTime.now(),
              );
              context.read<InvoiceRepository>().createInvoice(newInv);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePage(mact: 'SOH', invoice: newInv), // sửa
                ),
              );
              _search();
            },
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
}
