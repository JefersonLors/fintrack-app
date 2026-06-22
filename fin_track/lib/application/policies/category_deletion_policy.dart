class CategoryDeletionPolicy {
  const CategoryDeletionPolicy();

  void validateDeletion({required bool hasAssociatedReceipts}) {
    if (hasAssociatedReceipts) {
      throw const FormatException(
        'Esta categoria está associada a comprovantes e não pode ser excluída.',
      );
    }
  }
}
