class OperationCancelledException implements Exception {
  const OperationCancelledException([this.message = 'Operação cancelada.']);

  final String message;

  @override
  String toString() => message;
}

bool isOperationCancelled(Object error) {
  return error is OperationCancelledException;
}
