abstract class ICategoryPreferenceService {
  Future<int?> findPreferredCategory({String? cnpj, String? establishment});

  Future<void> registerPreferredCategory({
    String? cnpj,
    String? establishment,
    required int categoryId,
  });

  Future<void> registerCnpjConfirmation({
    required String cnpj,
    required String establishment,
    required int categoryId,
  });

  Future<Map<int, double>> itemBoosts(List<String> items);

  Future<void> registerCategoryItems({
    required List<String> items,
    required int categoryId,
  });
}
