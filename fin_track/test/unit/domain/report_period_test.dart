import 'package:fin_track/domain/value_objects/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly period and today calculate boundaries and labels', () {
    final today = periodInterval(
      ReportPeriod.today,
      now: DateTime(2026, 5, 20, 14, 30),
    );
    final week = periodInterval(
      ReportPeriod.week,
      now: DateTime(2026, 5, 20, 14, 30),
    );

    expect(today.startDate, DateTime(2026, 5, 20));
    expect(today.endDate, DateTime(2026, 5, 20, 23, 59, 59, 999, 999));
    expect(today.label, '20/05/2026');
    expect(today.summary, 'hoje');
    expect(week.startDate, DateTime(2026, 5, 18));
    expect(week.endDate, today.endDate);
    expect(week.label, '18/05 - 20/05');
    expect(week.summary, 'nesta semana');
  });

  test('month year and all periods calculate boundaries and descriptions', () {
    final month = periodInterval(
      ReportPeriod.month,
      now: DateTime(2026, 3, 15, 8, 20),
    );
    final year = periodInterval(
      ReportPeriod.year,
      now: DateTime(2026, 3, 15, 8, 20),
    );
    final all = periodInterval(ReportPeriod.all);

    expect(month.startDate, DateTime(2026, 3));
    expect(month.endDate, DateTime(2026, 3, 15, 23, 59, 59, 999, 999));
    expect(month.label, 'Março 2026');
    expect(month.summary, 'em Março 2026');
    expect(year.startDate, DateTime(2026));
    expect(year.endDate, month.endDate);
    expect(year.label, '2026');
    expect(year.summary, 'em 2026');
    expect(all.startDate, isNull);
    expect(all.endDate, isNull);
    expect(all.label, 'Histórico completo');
    expect(all.summary, 'no histórico completo');
  });
}
