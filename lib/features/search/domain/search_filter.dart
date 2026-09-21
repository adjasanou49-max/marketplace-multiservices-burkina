class SearchFilter {
  const SearchFilter({this.query = '', this.categoryId, this.shopId});
  final String query;
  final String? categoryId;
  final String? shopId;
  bool get isEmpty => query.trim().isEmpty && categoryId == null && shopId == null;
}
