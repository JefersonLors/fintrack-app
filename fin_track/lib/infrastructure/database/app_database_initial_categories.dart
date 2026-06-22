part of 'app_database.dart';

extension AppDatabaseInitialCategories on AppDatabase {
  List<domain.Category> _initialCategories() {
    return const <domain.Category>[
      domain.Category(
        id: 1,
        name: 'Alimentação',
        description: 'Mercado e refeições',
        icon: 'restaurant',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 2,
        name: 'Transporte',
        description: 'Mobilidade e combustível',
        icon: 'directions_car',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 3,
        name: 'Saúde',
        description: 'Medicamentos e consultas',
        icon: 'medical_services',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 4,
        name: 'Moradia',
        description: 'Casa, aluguel e contas',
        icon: 'home',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 5,
        name: 'Educação',
        description: 'Cursos, livros e escola',
        icon: 'school',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 6,
        name: 'Lazer',
        description: 'Eventos e entretenimento',
        icon: 'sports_esports',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 7,
        name: 'Pix',
        description: 'Transferências Pix',
        icon: 'pix',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 8,
        name: 'Outros',
        description: 'Despesas sem classificação',
        icon: 'more_horiz',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 9,
        name: 'Vestuário',
        description: 'Roupas, calçados e acessórios',
        icon: 'shopping_bag',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 10,
        name: 'Serviços',
        description: 'Prestadores, manutenção e serviços recorrentes',
        icon: 'work',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 11,
        name: 'Assinaturas',
        description: 'Planos, mensalidades e serviços digitais',
        icon: 'subscriptions',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 12,
        name: 'Viagens',
        description: 'Hospedagem, passagens e despesas de viagem',
        icon: 'flight',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 13,
        name: 'Impostos',
        description: 'Tributos, taxas e obrigações',
        icon: 'request_quote',
        colorArgb: CategoryColorPalette.noColor,
      ),
      domain.Category(
        id: 14,
        name: 'Investimentos',
        description: 'Aplicações, aportes e movimentações financeiras',
        icon: 'savings',
        colorArgb: CategoryColorPalette.noColor,
      ),
    ];
  }
}
