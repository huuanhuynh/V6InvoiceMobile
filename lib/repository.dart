// lib/repository.dart
import 'package:flutter/foundation.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/invoice_item.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';

class InvoiceRepository extends ChangeNotifier {
  final List<Invoice> _invoices = [];

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  InvoiceRepository() {
    // real data loading can be done here
    searchInvoiceList();
  }

  // Hàm _getInvoiceList lấy dữ liệu từ API hoặc nguồn dữ liệu thực tế.
  List<Invoice> searchInvoiceList({DateTime? from, DateTime? to, String? searchValue}) {
    final today = DateTime.now();
    var searhFrom = from ?? today.subtract(const Duration(days: 7));
    var searchTo = to ?? today;
    
    ApiService.getInvoiceList(
      maCt: 'SOH', // Ví dụ: mã chứng từ cho hóa đơn bán hàng
      fromDate: H.objectToString(searhFrom, dateFormat : 'yyyyMMdd'),
      toDate: H.objectToString(searchTo, dateFormat : 'yyyyMMdd'),
      maDvcs: AppSession.madvcs!,
      pageIndex: 1,
      pageSize: 100,
    ).then((data) {
      // Giả sử data là danh sách các hóa đơn nhận được từ API
      // Cần chuyển đổi data thành danh sách Invoice
      List<Invoice> fetchedInvoices = []; // Chuyển đổi data thành danh sách Invoice ở đây

      // Cập nhật danh sách hóa đơn và thông báo thay đổi
      _invoices.clear();
      _invoices.addAll(fetchedInvoices);
      notifyListeners();
    }).catchError((error) {
      // Xử lý lỗi nếu cần
      if (kDebugMode) {
        print('Error fetching invoices: $error');
      }
    });
    return _invoices;
  }

  // Tìm kiếm trên danh sách sẵn có.
  List<Invoice> search({DateTime? from, DateTime? to, String? keyword,
  }) {
    final DateTime? startOfFromDay = from != null  ? DateTime(from.year, from.month, from.day) : null;
    final DateTime? endOfToDay = to != null ? DateTime(to.year, to.month, to.day).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1))
        : null;

    return _invoices.where((inv) {
      if (startOfFromDay != null && inv.date.isBefore(startOfFromDay)) {
        return false;
      }
      if (endOfToDay != null && inv.date.isAfter(endOfToDay)) {
         return false;
      }
      // --- Lọc theo Từ khóa ---
      if (keyword != null && keyword.trim().isNotEmpty) {
        final k = keyword.toLowerCase();
        if (!(inv.soCt.toLowerCase().contains(k) ||
              inv.getString('TEN_KH').toLowerCase().contains(k) ||
              inv.getString('GHI_CHU').toLowerCase().contains(k))) {
          return false;
        }
      }
      
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addInvoice(Invoice invoice) async {
    try {
      await ApiService.postNewInvoice(invoice); // Giả định có _apiService
      _invoices.add(invoice);
      notifyListeners(); 
    } catch (e) {
      throw Exception('Lỗi khi thêm hóa đơn: ${e.toString()}');
    }
  }

  Future<void> updateInvoice(Invoice invoice) async {
    try {
      // 1. GỌI API: Thực hiện PUT/PATCH data lên máy chủ
      await ApiService.putUpdateInvoice(invoice); 
      
      // 2. LƯU CỤC BỘ: Nếu API thành công, cập nhật đối tượng trong danh sách
      // ... (logic tìm và cập nhật trong _invoices)
      final idx = _invoices.indexWhere((i) => i.id == invoice.id);
      if (idx != -1) {
        _invoices[idx] = invoice;
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Lỗi khi cập nhật hóa đơn: ${e.toString()}');
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
