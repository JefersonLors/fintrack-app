enum SemanticIndexTaskStatus {
  pending('PENDENTE'),
  processing('PROCESSANDO'),
  completed('CONCLUIDO'),
  failed('FALHA');

  const SemanticIndexTaskStatus(this.persistedValue);

  final String persistedValue;

  static SemanticIndexTaskStatus fromPersisted(String value) {
    return SemanticIndexTaskStatus.values.firstWhere(
      (status) => status.persistedValue == value,
      orElse: () => SemanticIndexTaskStatus.pending,
    );
  }
}

class SemanticIndexTask {
  const SemanticIndexTask({
    required this.receiptId,
    required this.status,
    required this.attempts,
    required this.updatedAt,
    this.errorDescription,
  });

  final int receiptId;
  final SemanticIndexTaskStatus status;
  final int attempts;
  final DateTime updatedAt;
  final String? errorDescription;
}
