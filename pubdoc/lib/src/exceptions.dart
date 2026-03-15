class PubdocException implements Exception {
  final String message;
  PubdocException(this.message);

  @override
  String toString() => message;
}
