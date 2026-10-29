package com.appbedev.statusmaker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Adds targeted image sharing on top of the plain system chooser that
 * `share_plus` gives us: the editor's share sheet hands the exported PNG
 * straight to WhatsApp / Instagram / Facebook, which needs an ACTION_SEND
 * intent with the destination package set.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "status_maker/native_share"

        /** Must match the provider authority declared in AndroidManifest.xml. */
        const val PROVIDER_SUFFIX = ".shareprovider"

        /**
         * Candidate packages per logical target, in preference order — WhatsApp
         * Business and the Lite clients stand in when the main app is absent.
         */
        val TARGET_PACKAGES = mapOf(
            "whatsapp" to listOf("com.whatsapp", "com.whatsapp.w4b"),
            "instagram" to listOf("com.instagram.android", "com.instagram.lite"),
            "facebook" to listOf("com.facebook.katana", "com.facebook.lite"),
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * Creates the channel FCM pushes land in (id from
     * `default_notification_channel_id` in strings.xml, which the manifest
     * also points FCM at). Without this, Android 8+ files pushes under an
     * auto-created "Miscellaneous" channel. Idempotent: re-creating an
     * existing channel is a no-op.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.default_notification_channel_id),
            getString(R.string.notification_channel_likes_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.notification_channel_likes_desc)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedTargets" -> result.success(installedTargets())
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        val target = call.argument<String>("target")
                        val text = call.argument<String>("text")
                        if (path == null || target == null) {
                            result.error("bad_args", "path and target are required", null)
                        } else {
                            result.success(shareImage(path, target, text))
                        }
                    }
                    "encodePreview" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val maxWidth = call.argument<Int>("maxWidth") ?: 540
                        val quality = call.argument<Int>("quality") ?: 80
                        if (bytes == null) {
                            result.error("bad_args", "bytes is required", null)
                        } else {
                            // Off the main thread: decoding + encoding a
                            // 1080x1920 image takes ~100 ms on a mid-range phone.
                            Thread {
                                val out = try {
                                    encodePreview(bytes, maxWidth, quality)
                                } catch (e: Exception) {
                                    null
                                }
                                runOnUiThread { result.success(out) }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Downscales an exported PNG to [maxWidth] and re-encodes it as lossy WebP
     * for the feed: ~40 KB instead of a 1–2 MB PNG. Flutter can only encode
     * PNG, and Android's own encoder avoids pulling in an image package.
     */
    private fun encodePreview(bytes: ByteArray, maxWidth: Int, quality: Int): ByteArray? {
        val source = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        val scaled = if (source.width > maxWidth) {
            val height = (source.height.toLong() * maxWidth / source.width).toInt()
            Bitmap.createScaledBitmap(source, maxWidth, height, true)
        } else {
            source
        }
        val format = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bitmap.CompressFormat.WEBP_LOSSY
        } else {
            @Suppress("DEPRECATION")
            Bitmap.CompressFormat.WEBP
        }
        val stream = ByteArrayOutputStream()
        scaled.compress(format, quality, stream)
        if (scaled !== source) scaled.recycle()
        source.recycle()
        return stream.toByteArray()
    }

    /**
     * The logical target names ("whatsapp", …) that actually have an app
     * installed, so the sheet can hide tiles that would only fail.
     */
    private fun installedTargets(): List<String> =
        TARGET_PACKAGES.filterValues { pkgs -> pkgs.any(::isInstalled) }.keys.toList()

    private fun isInstalled(pkg: String): Boolean = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    /**
     * Returns false (rather than throwing) when nothing could handle the share —
     * the Dart side then falls back to the system chooser.
     */
    private fun shareImage(path: String, target: String, text: String?): Boolean {
        val file = File(path)
        if (!file.exists()) return false

        val pkg = TARGET_PACKAGES[target]?.firstOrNull(::isInstalled) ?: return false

        val uri = try {
            FileProvider.getUriForFile(this, packageName + PROVIDER_SUFFIX, file)
        } catch (e: IllegalArgumentException) {
            return false
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        // Belt-and-braces alongside the flag: some targets read the stream from a
        // different process than the one that resolved the intent.
        grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
