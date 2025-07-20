class BidException implements Exception {
  final String errorMessageCode;

  BidException({required this.errorMessageCode});

  @override
  String toString() => errorMessageCode;
}
