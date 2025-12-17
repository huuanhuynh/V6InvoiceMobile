// lib/repository.dart
import 'package:flutter/foundation.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/api_response.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/invoice_item.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
/// Quản lý dữ liệu hóa đơn trong ứng dụng.
class InvoiceRepository extends ChangeNotifier {
  final List<Invoice> _invoices = [];

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  InvoiceRepository() {
    // real data loading can be done here
    searchInvoiceList();
  }

  // 1. Thay đổi kiểu trả về thành Future<List<Invoice>>
  Future<List<Invoice>> searchInvoiceList({
    DateTime? from,
    DateTime? to,
    String? searchValue,
  }) async { // 2. Thêm từ khóa 'async'
    final today = DateTime.now();
    var searhFrom = from ?? today.subtract(const Duration(days: 7));
    var searchTo = to ?? today;
    
    try {
      // 3. Sử dụng 'await' để chờ kết quả API
      final response = await ApiService.getInvoiceList(
        maCt: 'SOH', 
        fromDate: H.objectToString(searhFrom, dateFormat : 'yyyyMMdd'),
        toDate: H.objectToString(searchTo, dateFormat : 'yyyyMMdd'),
        maDvcs: AppSession.madvcs!,
        pageIndex: 1,
        pageSize: 100,
      );
      
      // Logic chuyển đổi data
      List<Invoice> fetchedInvoices = [];
      if (response['data']['items'] != null) {
        for (var item in response['data']['items']) {
          Invoice inv = Invoice(dataAPI: item);
          fetchedInvoices.add(inv);
        }
      }
      
      // Cập nhật danh sách hóa đơn và thông báo thay đổi (Giữ lại nếu đây là Change Notifier)
      _invoices.clear();
      _invoices.addAll(fetchedInvoices);
      notifyListeners();
      
      // 4. Trả về kết quả cuối cùng (được bao bọc trong Future)
      return _invoices; 
      
    } catch (error) {
      // Xử lý và ném lỗi (hoặc trả về danh sách rỗng nếu lỗi không nghiêm trọng)
      if (kDebugMode) {
        print('Error fetching invoices: $error');
      }
      // Có thể ném lỗi hoặc trả về danh sách rỗng tùy logic
      // throw Exception('Failed to load invoices'); 
      return []; // Trả về list rỗng khi có lỗi
    }
  }
  // Hàm _getInvoiceList lấy dữ liệu từ API hoặc nguồn dữ liệu thực tế.
  List<Invoice> searchInvoiceList_Old({DateTime? from, DateTime? to, String? searchValue}) {
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
    ).then((response) {
      // Giả sử data là danh sách các hóa đơn nhận được từ API
      // Cần chuyển đổi data thành danh sách Invoice
      List<Invoice> fetchedInvoices = []; // Chuyển đổi data thành danh sách Invoice ở đây
      if (response['data']['items'] != null) {
        for (var item in response['data']['items']) {
          Invoice inv = Invoice(dataAPI: item);
          fetchedInvoices.add(inv);
        }
      }
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
      if (startOfFromDay != null && inv.ngayCt.isBefore(startOfFromDay)) {
        return false;
      }
      if (endOfToDay != null && inv.ngayCt.isAfter(endOfToDay)) {
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
      ..sort((a, b) => b.ngayCt.compareTo(a.ngayCt));
  }

  Future<ApiResponse> addInvoice(Invoice invoice) async {
    try {
      var response = await ApiService.postNewInvoice(invoice); // Giả định có _apiService
      if (response.error != null) {
        throw Exception('Lỗi khi thêm hóa đơn: ${response.error}');
      }
      else if (response.isSuccess) {
        // Cập nhật sttrec từ response nếu cần
        var returnedData = response.data;
        if (returnedData != null && returnedData['sttRec'] != null) {
          invoice.setString('STT_REC', returnedData['sttRec']);
        }
        _invoices.add(invoice);
      }
      
      notifyListeners(); 
      return response;
    } catch (e) {
      throw Exception('Lỗi khi thêm hóa đơn: ${e.toString()}');
    }
  }

  Future<ApiResponse> updateInvoice(Invoice invoice) async {
    try {
      // 1. GỌI API: Thực hiện PUT/PATCH data lên máy chủ
      var response = await ApiService.putUpdateInvoice(invoice);
      if (response.error != null) {
        throw Exception('Lỗi khi cập nhật hóa đơn: ${response.error}');
      }
      else if (response.isSuccess) {
        final idx = _invoices.indexWhere((i) => i.sttrec == invoice.sttrec);
        if (idx != -1) {
          _invoices[idx] = invoice;
        }  
      }
      
      notifyListeners();
      return response;

    } catch (e) {
      throw Exception('Lỗi khi cập nhật hóa đơn: ${e.toString()}');
    }
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((i) => i.sttrec == id);
    notifyListeners();
  }

  void addItem(String invoiceId, InvoiceItem item) {
    final inv = _invoices.firstWhere((i) => i.sttrec == invoiceId);
    inv.addItem(item);
    notifyListeners();
  }

  void updateItem(String invoiceId, InvoiceItem item) {
    final inv = _invoices.firstWhere((i) => i.sttrec == invoiceId);
    final idx = inv.detailDatas.indexWhere((it) => it.sttRec0 == item.sttRec0);
    if (idx != -1) {
      inv.detailDatas[idx] = item;
      notifyListeners();
    }
  }

  void deleteItem(String sttRec, String sttRec0) {
    final inv = _invoices.firstWhere((i) => i.sttrec == sttRec);
    inv.detailDatas.removeWhere((it) => it.sttRec0 == sttRec0);
    notifyListeners();
  }
}
