class PubdocException implements Exception {
  PubdocException(this.message);
  final String message;

  @override
  String toString() => message;
}
