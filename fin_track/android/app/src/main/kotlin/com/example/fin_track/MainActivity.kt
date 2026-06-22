package com.example.fin_track

import android.app.Activity
import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.hardware.fingerprint.FingerprintManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Base64
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCameraFile: File? = null
    private var pendingSaveFiles: List<File> = emptyList()
    private var pendingSaveMimeType: String = "application/octet-stream"
    private val pendingSharedFilePaths = mutableListOf<String>()
    private var nativeChannel: MethodChannel? = null
    private var pendingBiometricResult: MethodChannel.Result? = null
    private var pendingBiometricCancellation: CancellationSignal? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        nativeChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "captureImage" -> captureImage(result)
                "selectFiles" -> selectFiles(result)
                "processOcr" -> {
                    val path = call.argument<String>("path")
                    processOcr(path, result)
                }
                "shareFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType") ?: "image/*"
                    shareFile(path, mimeType, result)
                }
                "shareFiles" -> {
                    val paths = call.argument<List<String>>("paths") ?: emptyList()
                    shareFiles(paths, result)
                }
                "saveFileToDevice" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    saveFileToDevice(path, mimeType, result)
                }
                "saveFilesToDevice" -> {
                    val paths = call.argument<List<String>>("paths") ?: emptyList()
                    saveFilesToDevice(paths, result)
                }
                "getDeviceInfo" -> getDeviceInfo(result)
                "openReportEmail" -> {
                    val recipient = call.argument<String>("recipient")
                    val subject = call.argument<String>("subject") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    openReportEmail(recipient, subject, body, result)
                }
                "saveLocalPin" -> {
                    val pin = call.argument<String>("pin")
                    saveLocalPin(pin, result)
                }
                "authenticateLocalPin" -> {
                    val pin = call.argument<String>("pin")
                    authenticateLocalPin(pin, result)
                }
                "removeLocalPin" -> removeLocalPin(result)
                "checkBiometrics" -> checkBiometrics(result)
                "authenticateBiometrics" -> {
                    val title = call.argument<String>("title") ?: "Desbloquear FinTrack"
                    val subtitle = call.argument<String>("subtitle") ?: ""
                    authenticateBiometrics(title, subtitle, result)
                }
                "pendingSharedFiles" -> {
                    val paths = pendingSharedFilePaths.toList()
                    pendingSharedFilePaths.clear()
                    result.success(paths)
                }
                "getInitialAction" -> {
                    result.success(null)
                }
                "scheduleAutomaticBackup" -> {
                    val intervalDays = (call.argument<Number>("intervalDays"))?.toInt()
                    result.success(
                        intervalDays != null &&
                            BackupWorkScheduler.schedule(applicationContext, intervalDays)
                    )
                }
                "cancelAutomaticBackup" -> {
                    result.success(BackupWorkScheduler.cancel(applicationContext))
                }
                "runAutomaticBackupNowForTesting" -> {
                    result.success(BackupWorkScheduler.runNowForTesting(applicationContext))
                }
                "schedulePendingBatchImports" -> {
                    result.success(ReceiptBatchWorkScheduler.schedule(applicationContext))
                }
                "cancelPendingBatchImports" -> {
                    result.success(ReceiptBatchWorkScheduler.cancel(applicationContext))
                }
                "schedulePendingSemanticIndex" -> {
                    result.success(SemanticIndexWorkScheduler.schedule(applicationContext))
                }
                "cancelPendingSemanticIndex" -> {
                    result.success(SemanticIndexWorkScheduler.cancel(applicationContext))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun captureImage(result: MethodChannel.Result) {
        if (!preparePending(result)) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
            return
        }

        openCameraIntent(result)
    }

    private fun openCameraIntent(result: MethodChannel.Result) {

        val dir = File(filesDir, "receipts")
        dir.mkdirs()
        val file = File(dir, "capture_${System.currentTimeMillis()}.jpg")
        pendingCameraFile = file
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }

        if (intent.resolveActivity(packageManager) == null) {
            clearPending()
            result.success(null)
            return
        }

        startActivityForResult(intent, REQUEST_CAMERA)
    }

    private fun selectFiles(result: MethodChannel.Result) {
        if (!preparePending(result)) return

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "image/jpeg",
                    "image/png",
                    "image/webp",
                    "image/heic",
                    "image/heif",
                    "application/pdf"
                )
            )
        }
        startActivityForResult(intent, REQUEST_FILES)
    }

    private fun shareFile(
        path: String?,
        mimeType: String,
        result: MethodChannel.Result
    ) {
        if (path.isNullOrBlank()) {
            result.success(false)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.success(false)
            return
        }

        try {
            val shareable = prepareFileForSharing(file)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", shareable)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = android.content.ClipData.newUri(
                    contentResolver,
                    "Comprovante",
                    uri
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            openShareWithPermission(
                intent,
                "Compartilhar comprovante",
                listOf(uri)
            )
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun shareFiles(
        paths: List<String>,
        result: MethodChannel.Result
    ) {
        val files = paths.map { File(it) }.filter { it.exists() }
        if (files.isEmpty()) {
            result.success(false)
            return
        }

        try {
            val uris = ArrayList<Uri>()
            files.forEach { file ->
                val shareable = prepareFileForSharing(file)
                uris.add(
                    FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        shareable
                    )
                )
            }
            val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "*/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                clipData = android.content.ClipData.newUri(
                    contentResolver,
                    "Comprovantes",
                    uris.first()
                )
                for (index in 1 until uris.size) {
                    clipData?.addItem(android.content.ClipData.Item(uris[index]))
                }
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            openShareWithPermission(
                intent,
                "Compartilhar comprovantes",
                uris
            )
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun saveFileToDevice(
        path: String?,
        mimeType: String,
        result: MethodChannel.Result
    ) {
        if (!preparePending(result)) return

        val file = path?.let { File(it) }
        if (file == null || !file.exists()) {
            clearPending()
            result.success(false)
            return
        }

        pendingSaveFiles = listOf(file)
        pendingSaveMimeType = mimeType

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, file.name)
        }

        try {
            startActivityForResult(intent, REQUEST_SAVE_FILE)
        } catch (_: ActivityNotFoundException) {
            clearPending()
            result.success(false)
        }
    }

    private fun saveFilesToDevice(
        paths: List<String>,
        result: MethodChannel.Result
    ) {
        if (!preparePending(result)) return

        val files = paths.map { File(it) }.filter { it.exists() }
        if (files.isEmpty()) {
            clearPending()
            result.success(false)
            return
        }

        pendingSaveFiles = files
        pendingSaveMimeType = "*/*"

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        try {
            startActivityForResult(intent, REQUEST_SAVE_FILES_DIR)
        } catch (_: ActivityNotFoundException) {
            clearPending()
            result.success(false)
        }
    }

    private fun prepareFileForSharing(file: File): File {
        val dir = File(cacheDir, "shared_exports")
        dir.mkdirs()
        deleteOldSharedFiles(dir)
        val safeName = file.name.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        val destination = File(dir, "receipt_${System.currentTimeMillis()}_$safeName")
        file.inputStream().use { input ->
            destination.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        return destination
    }

    private fun deleteOldSharedFiles(dir: File) {
        val limit = System.currentTimeMillis() - 24L * 60L * 60L * 1000L
        dir.listFiles()?.forEach { file ->
            if (file.isFile && file.lastModified() < limit) {
                file.delete()
            }
        }
    }

    private fun openShareWithPermission(
        intent: Intent,
        title: String,
        uris: List<Uri>
    ) {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        packageManager
            .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            .forEach { resolveInfo ->
                val targetPackage = resolveInfo.activityInfo?.packageName ?: return@forEach
                uris.forEach { uri ->
                    grantUriPermission(targetPackage, uri, flags)
                }
            }

        val chooser = Intent.createChooser(intent, title).apply {
            addFlags(flags)
            clipData = intent.clipData
        }
        startActivity(chooser)
    }

    private fun getDeviceInfo(result: MethodChannel.Result) {
        val manufacturer = Build.MANUFACTURER.orEmpty()
        val model = Build.MODEL.orEmpty()
        val deviceModel = when {
            manufacturer.isBlank() && model.isBlank() -> "Modelo indisponível"
            manufacturer.isBlank() -> model
            model.isBlank() -> manufacturer
            model.startsWith(manufacturer, ignoreCase = true) -> model
            else -> "$manufacturer $model"
        }

        result.success(
            mapOf(
                "androidVersion" to "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
                "deviceModel" to deviceModel.trim()
            )
        )
    }

    private fun openReportEmail(
        recipient: String?,
        subject: String,
        body: String,
        result: MethodChannel.Result
    ) {
        if (recipient.isNullOrBlank()) {
            result.success(false)
            return
        }

        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }

        try {
            startActivity(intent)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.success(false)
        }
    }

    private fun saveLocalPin(pin: String?, result: MethodChannel.Result) {
        if (!isValidPin(pin)) {
            result.success(false)
            return
        }

        try {
            val salt = ByteArray(PIN_SALT_BYTES)
            SecureRandom().nextBytes(salt)
            val hash = hashPin(pin!!, salt)
            authPrefs()
                .edit()
                .putString(PREF_PIN_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
                .putString(PREF_PIN_HASH, Base64.encodeToString(hash, Base64.NO_WRAP))
                .apply()
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun authenticateLocalPin(pin: String?, result: MethodChannel.Result) {
        if (!isValidPin(pin)) {
            result.success(false)
            return
        }

        try {
            val prefs = authPrefs()
            val saltValue = prefs.getString(PREF_PIN_SALT, null)
            val hashValue = prefs.getString(PREF_PIN_HASH, null)
            if (saltValue.isNullOrBlank() || hashValue.isNullOrBlank()) {
                result.success(false)
                return
            }

            val salt = Base64.decode(saltValue, Base64.NO_WRAP)
            val expected = Base64.decode(hashValue, Base64.NO_WRAP)
            val actual = hashPin(pin!!, salt)
            result.success(constantTimeEquals(expected, actual))
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun removeLocalPin(result: MethodChannel.Result) {
        authPrefs()
            .edit()
            .remove(PREF_PIN_SALT)
            .remove(PREF_PIN_HASH)
            .apply()
        result.success(true)
    }

    private fun checkBiometrics(result: MethodChannel.Result) {
        result.success(biometricStatus())
    }

    private fun authenticateBiometrics(
        title: String,
        subtitle: String,
        result: MethodChannel.Result
    ) {
        if (pendingBiometricResult != null) {
            result.error(
                "biometric_in_progress",
                "Já existe uma autenticação biométrica em andamento.",
                null
            )
            return
        }

        val status = biometricStatus()
        if (status["available"] != true) {
            result.success(false)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(false)
            return
        }

        pendingBiometricResult = result
        val cancellation = CancellationSignal()
        pendingBiometricCancellation = cancellation

        val builder = BiometricPrompt.Builder(this)
            .setTitle(title.ifBlank { "Desbloquear FinTrack" })
            .setNegativeButton("Cancelar", mainExecutor) { _, _ ->
                completeBiometrics(false)
            }

        if (subtitle.isNotBlank()) {
            builder.setSubtitle(subtitle)
        }

        val prompt = builder.build()
        prompt.authenticate(
            cancellation,
            mainExecutor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult?) {
                    completeBiometrics(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
                    completeBiometrics(false)
                }
            }
        )
    }

    private fun completeBiometrics(success: Boolean) {
        val result = pendingBiometricResult
        pendingBiometricResult = null
        pendingBiometricCancellation = null
        result?.success(success)
    }

    private fun biometricStatus(): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return mapOf(
                "available" to false,
                "message" to "A biometria no FinTrack requer Android 9 ou superior."
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val biometricManager = getSystemService(BiometricManager::class.java)
            return when (biometricManager.canAuthenticate()) {
                BiometricManager.BIOMETRIC_SUCCESS -> mapOf(
                    "available" to true,
                    "message" to "Biometria disponível."
                )
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> mapOf(
                    "available" to false,
                    "message" to "Configure a biometria nas configurações do sistema operacional."
                )
                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> mapOf(
                    "available" to false,
                    "message" to "Este dispositivo não possui autenticação biométrica disponível."
                )
                else -> mapOf(
                    "available" to false,
                    "message" to "A biometria está temporariamente indisponível neste dispositivo."
                )
            }
        }

        @Suppress("DEPRECATION")
        val fingerprintManager = getSystemService(FingerprintManager::class.java)
        @Suppress("DEPRECATION")
        return when {
            fingerprintManager == null || !fingerprintManager.isHardwareDetected -> mapOf(
                "available" to false,
                "message" to "Este dispositivo não possui autenticação biométrica disponível."
            )
            !fingerprintManager.hasEnrolledFingerprints() -> mapOf(
                "available" to false,
                "message" to "Configure a biometria nas configurações do sistema operacional."
            )
            else -> mapOf(
                "available" to true,
                "message" to "Biometria disponível."
            )
        }
    }

    private fun isValidPin(pin: String?): Boolean {
        return pin != null && pin.length in 4..12 && pin.all { it.isDigit() }
    }

    private fun hashPin(pin: String, salt: ByteArray): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(getPinKey())
        mac.update(salt)
        mac.update(pin.toByteArray(Charsets.UTF_8))
        return mac.doFinal()
    }

    private fun getPinKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val existing = keyStore.getKey(PIN_KEY_ALIAS, null) as? SecretKey
        if (existing != null) {
            return existing
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_HMAC_SHA256,
            "AndroidKeyStore"
        )
        val spec = KeyGenParameterSpec.Builder(
            PIN_KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .build()
        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private fun constantTimeEquals(expected: ByteArray, actual: ByteArray): Boolean {
        if (expected.size != actual.size) {
            return false
        }

        var diff = 0
        for (index in expected.indices) {
            diff = diff or (expected[index].toInt() xor actual[index].toInt())
        }
        return diff == 0
    }

    private fun authPrefs() = getSharedPreferences(AUTH_PREFS, Context.MODE_PRIVATE)

    private fun processOcr(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.success("")
            return
        }

        val file = File(path)
        if (!file.exists() || file.extension.equals("pdf", ignoreCase = true)) {
            result.success("")
            return
        }

        try {
            val image = InputImage.fromFilePath(this, Uri.fromFile(file))
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    recognizer.close()
                    result.success(visionText.text)
                }
                .addOnFailureListener {
                    recognizer.close()
                    result.success("")
                }
        } catch (_: Exception) {
            result.success("")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_CAMERA -> {
                val file = pendingCameraFile
                val result = pendingResult
                clearPending()
                if (resultCode == Activity.RESULT_OK && file != null && file.exists()) {
                    compressCapturedImage(file, preferPortrait = true)
                    result?.success(file.absolutePath)
                } else {
                    result?.success(null)
                }
            }
            REQUEST_FILES -> {
                val result = pendingResult
                clearPending()
                if (resultCode == Activity.RESULT_OK && data != null) {
                    result?.success(copySelectedFiles(data))
                } else {
                    result?.success(emptyList<String>())
                }
            }
            REQUEST_SAVE_FILE -> {
                val result = pendingResult
                val file = pendingSaveFiles.firstOrNull()
                val uri = data?.data
                val saved = resultCode == Activity.RESULT_OK &&
                    file != null &&
                    uri != null &&
                    copyFileToUri(file, uri)
                clearPending()
                result?.success(saved)
            }
            REQUEST_SAVE_FILES_DIR -> {
                val result = pendingResult
                val files = pendingSaveFiles
                val treeUri = data?.data
                val saved = resultCode == Activity.RESULT_OK &&
                    treeUri != null &&
                    copyFilesToTree(files, treeUri)
                clearPending()
                result?.success(saved)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            val result = pendingResult
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (result != null) {
                    openCameraIntent(result)
                }
            } else {
                clearPending()
                result?.success(null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingShare(intent)
    }

    override fun onDestroy() {
        pendingBiometricCancellation?.cancel()
        pendingBiometricResult?.success(false)
        pendingBiometricCancellation = null
        pendingBiometricResult = null
        super.onDestroy()
    }

    private fun handleIncomingShare(intent: Intent?) {
        val paths = when (intent?.action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                listOfNotNull(uri?.let { copySharedFile(it, temporary = true) })
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                uris
                    ?.mapNotNull { copySharedFile(it, temporary = true) }
                    .orEmpty()
            }
            else -> emptyList()
        }
        if (paths.isEmpty()) return
        pendingSharedFilePaths.addAll(paths)
        nativeChannel?.invokeMethod(
            "sharedFiles",
            mapOf("paths" to paths),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    pendingSharedFilePaths.removeAll(paths.toSet())
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    // Keep pending paths for Flutter to consume during startup.
                }

                override fun notImplemented() {
                    // Keep pending paths for Flutter to consume during startup.
                }
            }
        )
    }

    private fun copySharedFile(uri: Uri, temporary: Boolean = false): String? {
        return try {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {
                // Some providers do not offer persistable permission; the immediate copy is enough.
            }
            val mime = contentResolver.getType(uri) ?: "application/octet-stream"
            val isPdf = mime.contains("pdf")
            val isImage = mime.startsWith("image/") || !isPdf
            val extension = when {
                isPdf -> "pdf"
                isImage -> "jpg"
                else -> "jpg"
            }
            val dir = if (temporary) {
                File(cacheDir, "shared_imports")
            } else {
                File(filesDir, "receipts")
            }
            dir.mkdirs()
            val target = File(dir, "imported_${System.currentTimeMillis()}_${System.nanoTime()}.$extension")
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { stream ->
                target.outputStream().use { output -> stream.copyTo(output) }
            }
            if (!target.exists() || target.length() == 0L) return null
            if (isImage) {
                compressCapturedImage(target)
            }
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun copySelectedFiles(data: Intent): List<String> {
        val paths = mutableListOf<String>()
        val clipData = data.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                val uri = clipData.getItemAt(index).uri
                copySharedFile(uri, temporary = true)?.let { paths.add(it) }
            }
        } else {
            data.data?.let { uri ->
                copySharedFile(uri, temporary = true)?.let { paths.add(it) }
            }
        }
        return paths
    }

    private fun copyFileToUri(file: File, uri: Uri): Boolean {
        return try {
            contentResolver.openOutputStream(uri)?.use { output ->
                file.inputStream().use { input -> input.copyTo(output) }
            } ?: return false
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun copyFilesToTree(files: List<File>, treeUri: Uri): Boolean {
        if (files.isEmpty()) return false
        return try {
            val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                treeDocumentId
            )
            var copied = 0
            files.forEach { file ->
                val targetUri = DocumentsContract.createDocument(
                    contentResolver,
                    parentUri,
                    mimeTypeForFile(file),
                    file.name
                )
                if (targetUri != null && copyFileToUri(file, targetUri)) {
                    copied += 1
                }
            }
            copied == files.size
        } catch (_: Exception) {
            false
        }
    }

    private fun mimeTypeForFile(file: File): String {
        val name = file.name.lowercase()
        return when {
            name.endsWith(".pdf") -> "application/pdf"
            name.endsWith(".png") -> "image/png"
            name.endsWith(".webp") -> "image/webp"
            name.endsWith(".heic") -> "image/heic"
            name.endsWith(".heif") -> "image/heif"
            name.endsWith(".jpg") || name.endsWith(".jpeg") -> "image/jpeg"
            pendingSaveMimeType.isNotBlank() && pendingSaveMimeType != "*/*" -> pendingSaveMimeType
            else -> "application/octet-stream"
        }
    }

    private fun compressCapturedImage(file: File, preferPortrait: Boolean = false) {
        try {
            val orientation = ExifInterface(file.absolutePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
            val bitmap = BitmapFactory.decodeFile(file.absolutePath) ?: return
            val orientedBitmap = applyExifOrientation(bitmap, orientation)
            val portraitBitmap = if (preferPortrait && orientedBitmap.width > orientedBitmap.height) {
                rotateBitmap(orientedBitmap, 90f)
            } else {
                orientedBitmap
            }
            val maxSide = 1600
            val width = portraitBitmap.width
            val height = portraitBitmap.height
            val longest = maxOf(width, height)
            val outputBitmap = if (longest > maxSide) {
                val scale = maxSide.toFloat() / longest.toFloat()
                Bitmap.createScaledBitmap(
                    portraitBitmap,
                    (width * scale).toInt().coerceAtLeast(1),
                    (height * scale).toInt().coerceAtLeast(1),
                    true
                )
            } else {
                portraitBitmap
            }

            file.outputStream().use { output ->
                outputBitmap.compress(Bitmap.CompressFormat.JPEG, 88, output)
            }

            if (outputBitmap !== portraitBitmap) {
                outputBitmap.recycle()
            }
            if (portraitBitmap !== orientedBitmap) {
                portraitBitmap.recycle()
            }
            if (orientedBitmap !== bitmap) {
                orientedBitmap.recycle()
            }
            bitmap.recycle()
        } catch (_: Exception) {
            // Keep the original captured image if compression fails.
        }
    }

    private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
        return when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(bitmap, 90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(bitmap, 180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(bitmap, 270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> transformBitmap(bitmap) {
                preScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> transformBitmap(bitmap) {
                preScale(1f, -1f)
            }
            ExifInterface.ORIENTATION_TRANSPOSE -> transformBitmap(bitmap) {
                postRotate(90f)
                preScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSVERSE -> transformBitmap(bitmap) {
                postRotate(270f)
                preScale(-1f, 1f)
            }
            else -> bitmap
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        return transformBitmap(bitmap) { postRotate(degrees) }
    }

    private fun transformBitmap(bitmap: Bitmap, configure: Matrix.() -> Unit): Bitmap {
        val matrix = Matrix().apply(configure)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun preparePending(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error(
                "operation_in_progress",
                "Já existe uma operação nativa em andamento.",
                null
            )
            return false
        }
        pendingResult = result
        return true
    }

    private fun clearPending() {
        pendingResult = null
        pendingCameraFile = null
        pendingSaveFiles = emptyList()
        pendingSaveMimeType = "application/octet-stream"
    }

    companion object {
        private const val CHANNEL = "fin_track/native"
        private const val REQUEST_CAMERA = 7101
        private const val REQUEST_CAMERA_PERMISSION = 7103
        private const val REQUEST_FILES = 7104
        private const val REQUEST_SAVE_FILE = 7106
        private const val REQUEST_SAVE_FILES_DIR = 7107
        private const val AUTH_PREFS = "fin_track_auth"
        private const val PREF_PIN_SALT = "pin_salt"
        private const val PREF_PIN_HASH = "pin_hash"
        private const val PIN_KEY_ALIAS = "fin_track_pin_hmac"
        private const val PIN_SALT_BYTES = 16
    }
}
