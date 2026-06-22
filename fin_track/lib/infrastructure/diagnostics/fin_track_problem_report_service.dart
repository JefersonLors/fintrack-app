import '../../domain/infrastructure/i_problem_report_service.dart';
import '../image/fin_track_platform.dart';
import 'fin_track_error_log.dart';

class FinTrackProblemReportService implements IProblemReportService {
  const FinTrackProblemReportService();

  @override
  Future<Map<String, String>> getDeviceInfo() {
    return FinTrackPlatform.getDeviceInfo();
  }

  @override
  List<String> getRecentLogs() {
    return FinTrackErrorLog.recent();
  }

  @override
  Future<bool> openReportEmail({
    required String recipient,
    required String subject,
    required String body,
  }) {
    return FinTrackPlatform.openReportEmail(
      recipient: recipient,
      subject: subject,
      body: body,
    );
  }
}
