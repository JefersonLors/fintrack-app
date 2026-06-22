abstract class IProblemReportService {
  Future<Map<String, String>> getDeviceInfo();

  List<String> getRecentLogs();

  Future<bool> openReportEmail({
    required String recipient,
    required String subject,
    required String body,
  });
}
