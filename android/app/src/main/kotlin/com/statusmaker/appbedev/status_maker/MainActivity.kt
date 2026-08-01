package com.statusmaker.appbedev.status_maker

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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
                    else -> result.notImplemented()
                }
            }
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
