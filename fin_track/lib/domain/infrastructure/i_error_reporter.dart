abstract class IErrorReporter {
  void record(Object error, StackTrace? stackTrace);

  void recordDiagnostic(String message);
}
