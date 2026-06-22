import '../../domain/infrastructure/i_backup_scheduler.dart';
import '../image/fin_track_platform.dart';

class AndroidBackupScheduler implements IBackupScheduler {
  const AndroidBackupScheduler();

  @override
  Future<bool> scheduleAutomaticBackup({required int intervalDays}) {
    return FinTrackPlatform.scheduleAutomaticBackup(intervalDays: intervalDays);
  }

  @override
  Future<bool> cancelAutomaticBackup() {
    return FinTrackPlatform.cancelAutomaticBackup();
  }

  @override
  Future<bool> runNowForTesting() {
    return FinTrackPlatform.runAutomaticBackupNowForTesting();
  }
}
