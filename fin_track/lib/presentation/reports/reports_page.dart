import 'package:flutter/material.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/value_objects/receipt_filter.dart';
import '../../domain/value_objects/report_period.dart';
import '../receipts/pages/receipt_list_page.dart';
import '../theme/fin_track_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/fin_track_page_header.dart';
import '../widgets/state_views.dart';
import 'widgets/report_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  var _period = ReportPeriod.all;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).receiptService;
    final interval = periodInterval(_period);
    return Scaffold(
      appBar: const FinTrackPageHeader(title: Text('Relatórios')),
      body: StreamBuilder<List<Receipt>>(
        stream: service.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LoadingView(message: 'Calculando relatórios');
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: 'Não foi possível gerar os relatórios.',
              onRetry: () => setState(() {}),
            );
          }

          final allReceipts = snapshot.data ?? const <Receipt>[];
          final receipts = allReceipts.where((receipt) {
            final date = receipt.extractedData?.transactionDate;
            if (date == null) {
              return interval.startDate == null && interval.endDate == null;
            }
            final startDate = interval.startDate;
            final endDate = interval.endDate;
            return (startDate == null || !date.isBefore(startDate)) &&
                (endDate == null || !date.isAfter(endDate));
          }).toList();

          final expenses = receipts.where((item) => item.expense).toList();
          final incomes = receipts.where((item) => !item.expense).toList();
          final expenseCategories = _totalsByCategory(context, expenses);
          final incomeCategories = _totalsByCategory(context, incomes);
          final expenseTypes = _totalsByType(expenses);
          final incomeTypes = _totalsByType(incomes);
          final totalExpenseCategories = expenseCategories.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );
          final totalIncomeCategories = incomeCategories.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );
          final totalExpenseTypes = expenseTypes.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );
          final totalIncomeTypes = incomeTypes.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );
          final totalExpenses = expenses.fold<double>(
            0,
            (sum, item) => sum + (item.extractedData?.amount ?? 0),
          );
          final totalIncome = incomes.fold<double>(
            0,
            (sum, item) => sum + (item.extractedData?.amount ?? 0),
          );
          final balance = totalIncome - totalExpenses;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ReportPeriodSelector(
                selected: _period,
                onChanged: (value) => setState(() => _period = value),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione o período para ver seus gastos agregados. Toque em uma barra para abrir os comprovantes correspondentes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ReportSummary(
                incomes: totalIncome,
                expenses: totalExpenses,
                balance: balance,
                count: receipts.length,
                periodSummary: interval.summary,
                onIncomeTap: () => _openDrilldown(expense: false),
                onExpensesTap: () => _openDrilldown(expense: true),
              ),
              if (receipts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: EmptyView(
                    title: 'Sem dados no período',
                    message: 'Escolha outro período ou registre comprovantes.',
                    icon: Icons.bar_chart_outlined,
                  ),
                )
              else ...[
                ..._buildNatureSection(
                  context,
                  title: 'Receitas',
                  categories: incomeCategories,
                  totalCategories: totalIncomeCategories,
                  types: incomeTypes,
                  totalTypes: totalIncomeTypes,
                  expense: false,
                ),
                ..._buildNatureSection(
                  context,
                  title: 'Despesas',
                  categories: expenseCategories,
                  totalCategories: totalExpenseCategories,
                  types: expenseTypes,
                  totalTypes: totalExpenseTypes,
                  expense: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDrilldown({
    ReportTotal? category,
    ReportTotal? type,
    bool? expense,
  }) async {
    final interval = periodInterval(_period);
    final filter = ReceiptFilter(
      categoryId: category?.categoryId,
      withoutCategory: category?.withoutCategory ?? false,
      type: type?.type,
      expense: expense,
      startDate: interval.startDate,
      endDate: interval.endDate,
    );
    final label = [
      if (expense != null) expense ? 'Despesas' : 'Receitas',
      category?.label ?? type?.label,
      interval.label,
    ].whereType<String>().join(' · ');

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptListPage(
          initialFilter: filter,
          activeFilterLabel: label,
          autoFocusSearch: false,
        ),
      ),
    );
  }

  List<Widget> _buildNatureSection(
    BuildContext context, {
    required String title,
    required List<ReportTotal> categories,
    required double totalCategories,
    required List<ReportTotal> types,
    required double totalTypes,
    required bool expense,
  }) {
    if (categories.isEmpty && types.isEmpty) {
      return const [];
    }
    final natureColor = expense
        ? context.finTrackColors.expense
        : context.finTrackColors.income;

    return [
      const SizedBox(height: 20),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: context.finTrackColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (categories.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          'Por categoria',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.finTrackColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map(
          (item) => ReportBarRow(
            label: item.label,
            value: item.total,
            total: totalCategories,
            color: natureColor,
            iconColor: item.color ?? context.finTrackColors.neutralAccent,
            icon: item.icon ?? Icons.category_outlined,
            onTap: () => _openDrilldown(category: item, expense: expense),
          ),
        ),
      ],
      if (types.isNotEmpty) ...[
        SizedBox(height: categories.isEmpty ? 12 : 16),
        Text(
          'Por tipo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.finTrackColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...types.map(
          (item) => ReportBarRow(
            label: item.label,
            value: item.total,
            total: totalTypes,
            color: natureColor,
            icon: Icons.receipt_outlined,
            iconColor: context.finTrackColors.neutralAccent,
            onTap: () => _openDrilldown(type: item, expense: expense),
          ),
        ),
      ],
    ];
  }

  List<ReportTotal> _totalsByCategory(
    BuildContext context,
    List<Receipt> receipts,
  ) {
    final map = <int, MutableReportTotal>{};
    for (final receipt in receipts) {
      final amount = receipt.extractedData?.amount ?? 0;
      final category = receipt.category;
      if (category == null) {
        map[-1] =
            (map[-1] ??
                  MutableReportTotal('Sem categoria', withoutCategory: true))
              ..add(amount);
      } else {
        map[category.id] =
            (map[category.id] ??
                  MutableReportTotal.fromCategory(category, context))
              ..add(amount);
      }
    }
    final totals = map.values.map((item) => item.toTotal()).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return totals;
  }

  List<ReportTotal> _totalsByType(List<Receipt> receipts) {
    final map = <ReceiptType, MutableReportTotal>{};
    for (final receipt in receipts) {
      final amount = receipt.extractedData?.amount ?? 0;
      map[receipt.type] =
          (map[receipt.type] ??
                MutableReportTotal(receipt.type.label, type: receipt.type))
            ..add(amount);
    }
    final totals = map.values.map((item) => item.toTotal()).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return totals;
  }
}
