// lib/repository.dart
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'dart:math';

class InvoiceRepository extends ChangeNotifier {
  final List<Invoice> _invoices = [];

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  InvoiceRepository() {
    // sample data
    _seed();
  }

  void _seed() {
    final rnd = Random();
    for (int i = 1; i <= 6; i++) {
      final inv = Invoice(
        id: 'inv$i',
        number: 'INV-2025-00$i',
        date: DateTime.now().subtract(Duration(days: i * 2)),
        customerName: 'Khách hàng $i',
        notes: 'Ghi chú $i',
      );
      for (int j = 1; j <= 3; j++) {        
        inv.items.add(InvoiceItem(
          id: 'it${i}_$j',
          data: {
            'MA_VT': 'P$i$j',
            'TEN_VT': 'Mặt hàng $i-$j',
            'GIA_NT2': (rnd.nextDouble() * 1000).roundToDouble(),
            'SO_LUONG': (rnd.nextInt(10) + 1).toDouble(),
            'THUE_SUAT': 0.1,
          }
        ));
      }
      _invoices.add(inv);
    }
  }

  List<Invoice> search({
    DateTime? from,
    DateTime? to,
    String? keyword,
  }) {
    return _invoices.where((inv) {
      if (from != null && inv.date.isBefore(from)) return false;
      if (to != null && inv.date.isAfter(to)) return false;
      if (keyword != null && keyword.trim().isNotEmpty) {
        final k = keyword.toLowerCase();
        if (!(inv.number.toLowerCase().contains(k) ||
            inv.customerName.toLowerCase().contains(k) ||
            inv.notes.toLowerCase().contains(k))) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Invoice createInvoice(Invoice invoice) {
    _invoices.add(invoice);
    notifyListeners();
    return invoice;
  }

  void updateInvoice(Invoice invoice) {
    final idx = _invoices.indexWhere((i) => i.id == invoice.id);
    if (idx != -1) {
      _invoices[idx] = invoice;
      notifyListeners();
    }
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void addItem(String invoiceId, InvoiceItem item) {
    final inv = _invoices.firstWhere((i) => i.id == invoiceId);
    inv.items.add(item);
    notifyListeners();
  }

  void updateItem(String invoiceId, InvoiceItem item) {
    final inv = _invoices.firstWhere((i) => i.id == invoiceId);
    final idx = inv.items.indexWhere((it) => it.id == item.id);
    if (idx != -1) {
      inv.items[idx] = item;
      notifyListeners();
    }
  }

  void deleteItem(String invoiceId, String itemId) {
    final inv = _invoices.firstWhere((i) => i.id == invoiceId);
    inv.items.removeWhere((it) => it.id == itemId);
    notifyListeners();
  }
}
