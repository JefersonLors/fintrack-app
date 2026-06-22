enum CloudProvider {
  googleDrive('GOOGLE_DRIVE', 'Google Drive'),
  oneDrive('ONE_DRIVE', 'OneDrive'),
  dropbox('DROPBOX', 'Dropbox');

  const CloudProvider(this.persistedValue, this.label);

  final String persistedValue;
  final String label;

  static CloudProvider fromPersistedValue(String? value) {
    return CloudProvider.values.firstWhere(
      (provider) => provider.persistedValue == value,
      orElse: () => CloudProvider.googleDrive,
    );
  }
}
