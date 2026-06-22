package com.example.fin_track

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.ListenableWorker.Result as WorkResult
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val RECEIPT_BATCH_WORK = "fin_track_receipt_batch_import"
private const val RECEIPT_BATCH_CHANNEL = "fin_track/background_receipt_batch"
private const val RECEIPT_BATCH_ENTRYPOINT = "finTrackBackgroundReceiptBatchDispatcher"

class ReceiptBatchWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): WorkResult {
        val latch = CountDownLatch(1)
        val result = AtomicReference(WorkResult.retry())
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
                    RECEIPT_BATCH_CHANNEL
                ).setMethodCallHandler { call, methodResult ->
                    if (call.method == "backgroundReceiptBatchFinished") {
                        val success = call.argument<Boolean>("success") ?: false
                        result.set(if (success) WorkResult.success() else WorkResult.retry())
                        methodResult.success(null)
                        latch.countDown()
                    } else {
                        methodResult.notImplemented()
                    }
                }

                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        RECEIPT_BATCH_ENTRYPOINT
                    )
                )
            } catch (_: Exception) {
                result.set(WorkResult.retry())
                latch.countDown()
            }
        }

        val finished = latch.await(9, TimeUnit.MINUTES)
        mainHandler.post {
            engineRef.getAndSet(null)?.destroy()
        }

        return if (finished) result.get() else WorkResult.retry()
    }
}

object ReceiptBatchWorkScheduler {
    fun schedule(context: Context): Boolean {
        return try {
            val request = OneTimeWorkRequestBuilder<ReceiptBatchWorker>()
                .setConstraints(receiptBatchConstraints())
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                RECEIPT_BATCH_WORK,
                ExistingWorkPolicy.KEEP,
                request
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun cancel(context: Context): Boolean {
        return try {
            WorkManager.getInstance(context).cancelUniqueWork(RECEIPT_BATCH_WORK)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun receiptBatchConstraints(): Constraints {
        return Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .setRequiresBatteryNotLow(true)
            .build()
    }
}
