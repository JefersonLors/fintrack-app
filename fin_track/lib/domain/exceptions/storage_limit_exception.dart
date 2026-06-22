class StorageLimitException implements FormatException {
  const StorageLimitException(this.message);

  @override
  final String message;

  @override
  Object? get source => null;

  @override
  int? get offset => null;

  @override
  String toString() => message;
}
