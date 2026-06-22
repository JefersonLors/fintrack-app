import 'dart:typed_data';

import '../entities/cloud_provider.dart';

class CloudAccount {
  const CloudAccount({required this.email, required this.linkedAt});

  final String email;
  final DateTime linkedAt;
}

class CloudStorageFailure implements Exception {
  const CloudStorageFailure(this.userMessage, {this.technicalDetail});

  final String userMessage;
  final String? technicalDetail;

  @override
  String toString() {
    final detail = technicalDetail;
    if (detail == null || detail.isEmpty) {
      return userMessage;
    }
    return '$userMessage ($detail)';
  }
}

abstract class ICloudStorage {
  Future<CloudAccount> linkAccount();
  Future<void> unlinkAccount();
  Future<bool> verifyToken();
  Future<void> upload(List<Uint8List> files);
  Future<List<Uint8List>> download();
  Future<void> deleteBackup();
}

class CloudProviderOption {
  const CloudProviderOption({
    required this.provider,
    required this.available,
    this.unavailableReason,
  });

  final CloudProvider provider;
  final bool available;
  final String? unavailableReason;
}

abstract class ICloudStorageRegistry {
  List<CloudProviderOption> providers();
  ICloudStorage storageFor(CloudProvider provider);
}

class SingleCloudStorageRegistry implements ICloudStorageRegistry {
  const SingleCloudStorageRegistry(this._storage);

  final ICloudStorage _storage;

  @override
  List<CloudProviderOption> providers() {
    return const [
      CloudProviderOption(provider: CloudProvider.googleDrive, available: true),
      CloudProviderOption(
        provider: CloudProvider.oneDrive,
        available: false,
        unavailableReason: 'Em breve',
      ),
      CloudProviderOption(
        provider: CloudProvider.dropbox,
        available: false,
        unavailableReason: 'Em breve',
      ),
    ];
  }

  @override
  ICloudStorage storageFor(CloudProvider provider) {
    if (provider == CloudProvider.googleDrive) {
      return _storage;
    }
    throw UnsupportedError('${provider.label} ainda não está disponível.');
  }
}
