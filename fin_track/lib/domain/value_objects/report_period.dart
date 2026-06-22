enum ReportPeriod {
  all('Tudo'),
  today('Hoje'),
  week('Esta semana'),
  month('Este mês'),
  year('Este ano');

  const ReportPeriod(this.label);

  final String label;
}

class PeriodInterval {
  const PeriodInterval({
    this.startDate,
    this.endDate,
    required this.label,
    required this.summary,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String label;
  final String summary;
}

PeriodInterval periodInterval(ReportPeriod period, {DateTime? now}) {
  final base = now ?? DateTime.now();
  final today = DateTime(base.year, base.month, base.day);
  final todayEnd = today
      .add(const Duration(days: 1))
      .subtract(const Duration(microseconds: 1));

  return switch (period) {
    ReportPeriod.today => PeriodInterval(
      startDate: today,
      endDate: todayEnd,
      label:
          '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}',
      summary: 'hoje',
    ),
    ReportPeriod.week => _week(today, todayEnd),
    ReportPeriod.month => PeriodInterval(
      startDate: DateTime(today.year, today.month),
      endDate: todayEnd,
      label: '${_monthName(today.month)} ${today.year}',
      summary: 'em ${_monthName(today.month)} ${today.year}',
    ),
    ReportPeriod.year => PeriodInterval(
      startDate: DateTime(today.year),
      endDate: todayEnd,
      label: today.year.toString(),
      summary: 'em ${today.year}',
    ),
    ReportPeriod.all => const PeriodInterval(
      label: 'Histórico completo',
      summary: 'no histórico completo',
    ),
  };
}

PeriodInterval _week(DateTime today, DateTime todayEnd) {
  final startDate = today.subtract(Duration(days: today.weekday - 1));
  return PeriodInterval(
    startDate: startDate,
    endDate: todayEnd,
    label:
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')} - '
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}',
    summary: 'nesta semana',
  );
}

String _monthName(int month) {
  const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return monthNames[month - 1];
}
