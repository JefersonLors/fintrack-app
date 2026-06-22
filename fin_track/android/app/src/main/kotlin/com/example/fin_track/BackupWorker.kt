package com.example.fin_track

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ListenableWorker.Result as WorkResult
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val BACKGROUND_BACKUP_WORK = "fin_track_automatic_backup"
private const val BACKGROUND_BACKUP_CHANNEL = "fin_track/background_backup"
private const val BACKGROUND_BACKUP_ENTRYPOINT = "finTrackBackgroundBackupDispatcher"
private const val BACKGROUND_BACKUP_FAILURE_CHANNEL = "fin_track_backup_failures"
private const val BACKGROUND_BACKUP_FAILURE_NOTIFICATION_ID = 7301
private const val REQUEST_OPEN_AFTER_BACKUP_FAILURE = 7302

private data class BackgroundBackupResult(
    val workResult: WorkResult,
    val success: Boolean = false,
    val skipped: Boolean = false,
    val message: String? = null
)

class BackupWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): WorkResult {
        val latch = CountDownLatch(1)
        val backupResult = AtomicReference(BackgroundBackupResult(WorkResult.retry()))
        val mainHandler = Handler(Looper.getMainLooper())
        val engineRef = AtomicReference<FlutterEngine?>()

        mainHandler.post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(applicationContext)
                loader.ensureInitializationComplete(applicationContext, null)

                val engine = FlutterEngine(applicationContext)
                engineRef.set(engine)
                GeneratedPluginRegistrant.registerWith(engine)

                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    BACKGROUND_BACKUP_CHANNEL
                ).setMethodCallHandler { call, methodResult ->
                    if (call.method == "backgroundBackupFinished") {
                        val success = call.argument<Boolean>("success") ?: false
                        val skipped = call.argument<Boolean>("skipped") ?: false
                        val retryable = call.argument<Boolean>("retryable") ?: true
                        val message = call.argument<String>("message")
                        backupResult.set(
                            BackgroundBackupResult(
                                workResult = if (success || !retryable) {
                                    WorkResult.success()
                                } else {
                                    WorkResult.retry()
                                },
                                success = success,
                                skipped = skipped,
                                message = message
                            )
                        )
                        methodResult.success(null)
                        latch.countDown()
                    } else {
                        methodResult.notImplemented()
                    }
                }

                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        BACKGROUND_BACKUP_ENTRYPOINT
                    )
                )
            } catch (_: Exception) {
                backupResult.set(
                    BackgroundBackupResult(
                        workResult = WorkResult.retry(),
                        message = "Não foi possível iniciar o backup em segundo plano."
                    )
                )
                latch.countDown()
            }
        }

        val finished = latch.await(9, TimeUnit.MINUTES)
        mainHandler.post {
            engineRef.getAndSet(null)?.destroy()
        }

        if (!finished) {
            return WorkResult.retry()
        }

        val resolvedResult = backupResult.get()
        if (!resolvedResult.success && !resolvedResult.skipped) {
            showFailureNotification(resolvedResult.message)
        }
        return resolvedResult.workResult
    }

    private fun showFailureNotification(message: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            applicationContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notificationManager =
            applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    BACKGROUND_BACKUP_FAILURE_CHANNEL,
                    "Falhas de backup",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Avisos sobre backups automáticos que não foram concluídos"
                }
            )
        }

        val openIntent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            REQUEST_OPEN_AFTER_BACKUP_FAILURE,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val detail = message?.takeIf { it.isNotBlank() }
            ?: "O backup automático não pôde ser concluído."

        val notification = Notification.Builder(
            applicationContext,
            BACKGROUND_BACKUP_FAILURE_CHANNEL
        )
            .setSmallIcon(applicationContext.applicationInfo.icon)
            .setContentTitle("Backup automático falhou")
            .setContentText(detail)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(BACKGROUND_BACKUP_FAILURE_NOTIFICATION_ID, notification)
    }
}

object BackupWorkScheduler {
    fun schedule(context: Context, intervalDays: Int): Boolean {
        return try {
            val repeatIntervalMinutes = if (intervalDays <= 0) {
                15L
            } else {
                TimeUnit.DAYS.toMinutes(intervalDays.toLong())
            }
            val request = PeriodicWorkRequestBuilder<BackupWorker>(
                repeatIntervalMinutes,
                TimeUnit.MINUTES
            )
                .setConstraints(backupConstraints())
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                BACKGROUND_BACKUP_WORK,
                ExistingPeriodicWorkPolicy.UPDATE,
                request
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun cancel(context: Context): Boolean {
        return try {
            WorkManager.getInstance(context).cancelUniqueWork(BACKGROUND_BACKUP_WORK)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun runNowForTesting(context: Context): Boolean {
        return try {
            val request = OneTimeWorkRequestBuilder<BackupWorker>()
                .setConstraints(backupConstraints())
                .build()
            WorkManager.getInstance(context).enqueue(request)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun backupConstraints(): Constraints {
        return Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()
    }
}
