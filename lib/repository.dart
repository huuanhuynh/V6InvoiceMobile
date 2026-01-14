// lib/repository.dart
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:v6_invoice_mobile/app_session.dart';
import 'package:v6_invoice_mobile/h.dart';
import 'package:v6_invoice_mobile/models/api_response.dart';
import 'package:v6_invoice_mobile/models/invoice.dart';
import 'package:v6_invoice_mobile/models/invoice_item.dart';
import 'package:v6_invoice_mobile/models/paging_info.dart';
import 'package:v6_invoice_mobile/services/api_service.dart';
/// Quản lý dữ liệu hóa đơn trong ứng dụng.
class InvoiceRepository extends ChangeNotifier {
  final List<Invoice> _invoices = [];
  final List<Map<String, dynamic>> _alct1SOH = [];
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  PagingInfo pagingInfo = PagingInfo();
  // Khởi tạo GetStorage
  final _storage = GetStorage();
  final String _invoiceKey = 'cached_invoices_soh';
  final String _configKey = 'cached_alct1_soh';

  InvoiceRepository() {
    // Tải với giá trị mặc định khi khởi tạo
    //searchInvoiceList();
    _loadFromStorage();
  }

  // --- LOGIC LƯU TRỮ (GET_STORAGE) ---

  void _loadFromStorage() {
    // 1. Tải danh sách hóa đơn đã lưu
    final storedInvoices = _storage.read<List>(_invoiceKey);
    if (storedInvoices != null) {
      _invoices.clear();
      for (var item in storedInvoices) {
        // Giả sử Invoice có constructor fromJson hoặc chuyển đổi từ Map
        _invoices.add(Invoice(dataV6: Map<String, dynamic>.from(item)));
      }
    }

    // 2. Tải cấu hình Alct1 đã lưu
    final storedConfig = _storage.read<List>(_configKey);
    if (storedConfig != null) {
      _alct1SOH.clear();
      _alct1SOH.addAll(storedConfig.cast<Map<String, dynamic>>());
    }
    notifyListeners();
  }

  void _saveInvoicesToStorage() {
    // Chuyển danh sách Invoice thành List các Map để lưu vào GetStorage
    // Lưu ý: dataV6 là field bạn đang dùng để chứa raw data từ server
    final dataToSave = _invoices.map((inv) => inv.dataV6).toList();
    _storage.write(_invoiceKey, dataToSave);
  }

  // Thay đổi kiểu trả về thành Future<List<Invoice>>
  Future<List<Invoice>> searchInvoiceList({
    DateTime? from,
    DateTime? to,
    String? searchValue,
  }) async {
    final today = DateTime.now();
    var searhFrom = from ?? today.subtract(const Duration(days: 7));
    var searchTo = to ?? today;
    
    try {
      
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
      _invoices.addAll(fetchedInvoices..sort((a, b) => b.ngayCt.compareTo(a.ngayCt)));
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

  Future<List<Invoice>> searchInvoiceListSOH({
    DateTime? from,
    DateTime? to,
    String? searchValue,
    int pageIndex = 1,
    int pageSize = 100,
  }) async { // 2. Thêm từ khóa 'async'
    final today = DateTime.now();
    var searhFrom = from ?? today.subtract(const Duration(days: 7));
    var searchTo = to ?? today;
    
    try {
      
      final response = await ApiService.getInvoiceListSOH(
        fromDate: H.objectToString(searhFrom, dateFormat : 'yyyyMMdd'),
        toDate: H.objectToString(searchTo, dateFormat : 'yyyyMMdd'),
        maDvcs: AppSession.madvcs!,
        advance: searchValue,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
      
      // Logic chuyển đổi data
      List<Invoice> fetchedInvoices = [];
      if (response['invoiceMasterData'] != null && response['invoiceDetailData'] != null) {
        for (var item in response['invoiceMasterData']) {
          item['ads'] = [];
          for (var detail in response['invoiceDetailData']) {
            if (detail['stt_rec'] == item['stt_rec']) {
              item['ads'].add(detail);
            }
          }
          Invoice inv = Invoice(dataV6: item);
          fetchedInvoices.add(inv);
        }
      }
      
      // Cập nhật danh sách hóa đơn và thông báo thay đổi (Giữ lại nếu đây là Change Notifier)
      _invoices.clear();
      _invoices.addAll(fetchedInvoices..sort((a, b) {
        int cmp = b.ngayCt.compareTo(a.ngayCt);
        if (cmp == 0) {
          return b.time0.compareTo(a.time0);
        }
        return cmp;
      }));
      // LƯU VÀO STORAGE SAU KHI TẢI THÀNH CÔNG
      _saveInvoicesToStorage();
      notifyListeners();

      // Cập nhật thông tin phân trang
      var pageInfoData = response['paginationInfo'];
      if (pageInfoData != null) {
        pagingInfo.rowCount = _invoices.length;
        pagingInfo.totalRows = H.getInt(pageInfoData, 'totalRows');
        pagingInfo.totalPages = H.getInt(pageInfoData, 'totalPages');
        pagingInfo.currentPage = H.getInt(pageInfoData, 'currentPage');
        pagingInfo.pageSize = H.getInt(pageInfoData, 'pageSize');
      }
      
      // 4. Trả về kết quả cuối cùng (được bao bọc trong Future)
      return _invoices; 
      
    } catch (error) {
      // Xử lý và ném lỗi (hoặc trả về danh sách rỗng nếu lỗi không nghiêm trọng)
      if (kDebugMode) {
        print('Error fetching invoices: $error');
      }
      // Có thể ném lỗi hoặc trả về danh sách rỗng tùy logic
      // throw Exception('Failed to load invoices'); 
      //return []; // Trả về list rỗng khi có lỗi
      return _invoices; // Trả về danh sách hiện có khi có lỗi
    }
  }

  Future<List<Map<String, dynamic>>> getAlct1ListSOH() async {
    if (_alct1SOH.isNotEmpty) {
      return _alct1SOH;
    }
    try {
      final response = await ApiService.getAlct1Config(
        mact: 'SOH',
        magd: '',
      );
      // Logic chuyển đổi data
      List<Invoice> fetchedInvoices = [];
      if (response['data'] != null) {
        _alct1SOH.clear();
        for (var item in response['data']) {
          _alct1SOH.add(item as Map<String, dynamic>);
        }
      }
      // LƯU CẤU HÌNH VÀO STORAGE
      _storage.write(_configKey, _alct1SOH);
      return _alct1SOH;
      
    } catch (error) {
      if (kDebugMode) {
        print('Error getting config data: $error');
      }
      return []; // Trả về list rỗng khi có lỗi
    }
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
      _saveInvoicesToStorage(); // Cập nhật storage
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
      _saveInvoicesToStorage(); // Cập nhật storage
      notifyListeners();
      return response;

    } catch (e) {
      throw Exception('Lỗi khi cập nhật hóa đơn: ${e.toString()}');
    }
  }

  Future<ApiResponse> deleteInvoice(Invoice invoice) async {
    try {
      var response = await ApiService.deleteInvoiceSOH(invoice);
      
      if (H.objectToBool(response.data)) {
        _invoices.removeWhere((i) => i.sttrec == invoice.sttrec);
        _saveInvoicesToStorage(); // Cập nhật storage
        notifyListeners();
      }
      return response;
    } catch (e) {
      throw Exception('Lỗi khi xóa hóa đơn: ${e.toString()}');
    }
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
