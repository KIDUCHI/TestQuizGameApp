class TenderException implements Exception {
  final String errorMessageCode;

  TenderException({required this.errorMessageCode, errorMessageKey});

  @override
  String toString() => errorMessageCode;
}
