import 'cloud_provider.dart';

enum BackupStatus {
  pending('PENDENTE', 'Pendente'),
  synced('SINCRONIZADO', 'Sincronizado'),
  failure('FALHA', 'Falha');

  const BackupStatus(this.persistedValue, this.label);

  final String persistedValue;
  final String label;
}

enum BackupAvailability {
  active('ATIVO', 'Ativo'),
  inactive('INATIVO', 'Inativo'),
  deleted('EXCLUIDO', 'Excluído');

  const BackupAvailability(this.persistedValue, this.label);

  final String persistedValue;
  final String label;
}

enum BackupOperation {
  export('EXPORTACAO', 'Backup'),
  restore('RESTAURACAO', 'Restauração');

  const BackupOperation(this.persistedValue, this.label);

  final String persistedValue;
  final String label;
}

class BackupRecord {
  const BackupRecord({
    required this.id,
    required this.createdAt,
    this.operation = BackupOperation.export,
    required this.status,
    required this.totalReceipts,
    this.errorDescription,
    required this.configurationId,
    CloudProvider? cloudProvider,
    this.linkedCloudAccount,
    required this.availability,
  }) : cloudProvider =
           cloudProvider ??
           (linkedCloudAccount != null ? CloudProvider.googleDrive : null);

  final int id;
  final DateTime createdAt;
  final BackupOperation operation;
  final BackupStatus status;
  final int totalReceipts;
  final String? errorDescription;
  final int configurationId;
  final CloudProvider? cloudProvider;
  final String? linkedCloudAccount;
  final BackupAvailability availability;

  BackupRecord copyWith({
    int? id,
    DateTime? createdAt,
    BackupOperation? operation,
    BackupStatus? status,
    int? totalReceipts,
    String? errorDescription,
    int? configurationId,
    CloudProvider? cloudProvider,
    String? linkedCloudAccount,
    BackupAvailability? availability,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      totalReceipts: totalReceipts ?? this.totalReceipts,
      errorDescription: errorDescription ?? this.errorDescription,
      configurationId: configurationId ?? this.configurationId,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      linkedCloudAccount: linkedCloudAccount ?? this.linkedCloudAccount,
      availability: availability ?? this.availability,
    );
  }
}
