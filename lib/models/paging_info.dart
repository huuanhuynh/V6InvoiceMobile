class PagingInfo {
  int rowCount = 0;
  int totalRows = 0;
  int totalPages = 0;
  int currentPage = 0;
  int pageSize = 0;

  bool get hasPreviousPage => currentPage > 1;

  bool get hasMorePage => currentPage < totalPages;
}