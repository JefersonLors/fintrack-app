import 'package:fin_track/infrastructure/diagnostics/fin_track_error_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(FinTrackErrorLog.clear);

  test('keeps only recent diagnostics and limits long messages', () {
    final longMessage = 'x' * 5000;

    for (var i = 0; i < 22; i++) {
      FinTrackErrorLog.recordDiagnostic('diag-$i $longMessage');
    }

    final recent = FinTrackErrorLog.recent();
    expect(recent, hasLength(20));
    expect(recent.first, contains('diag-21'));
    expect(recent.last, contains('diag-2'));
    expect(recent.first.length, lessThan(4100));
  });

  test('reporter delegates errors and diagnostics to shared log', () {
    const reporter = FinTrackErrorReporter();

    reporter.record(StateError('failure controlada'), StackTrace.current);
    reporter.recordDiagnostic('pipeline=teste');

    final recent = FinTrackErrorLog.recent();
    expect(recent.first, contains('Diagnóstico'));
    expect(recent.first, contains('pipeline=teste'));
    expect(recent[1], contains('StateError'));
    expect(recent[1], contains('failure controlada'));
  });
}
