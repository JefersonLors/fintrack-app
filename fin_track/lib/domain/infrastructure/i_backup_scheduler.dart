abstract class IBackupScheduler {
  Future<bool> scheduleAutomaticBackup({required int intervalDays});
  Future<bool> cancelAutomaticBackup();
  Future<bool> runNowForTesting();
}

class NoopBackupScheduler implements IBackupScheduler {
  const NoopBackupScheduler();

  @override
  Future<bool> scheduleAutomaticBackup({required int intervalDays}) async {
    return true;
  }

  @override
  Future<bool> cancelAutomaticBackup() async {
    return true;
  }

  @override
  Future<bool> runNowForTesting() async {
    return false;
  }
}
