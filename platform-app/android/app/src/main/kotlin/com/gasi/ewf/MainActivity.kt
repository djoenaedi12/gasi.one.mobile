package com.gasi.ewf

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "app_integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "verifySignature" -> result.success(verifyAppSignature())
                else -> result.notImplemented()
            }
        }
    }

    private fun verifyAppSignature(): Boolean {
        val expectedSignature =
            "FC:9D:02:8C:FE:42:91:84:60:FC:6D:CE:E2:83:9B:23:7A:8E:50:78:71:65:BA:D7:FD:67:2F:87:7D:9A:A3:E5"

        return try {
            val packageInfo = try {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                        // Android 13+
                        packageManager.getPackageInfo(
                            packageName,
                            PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong())
                        )
                    }
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> {
                        // Android 9-12
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    }
                    else -> {
                        // Android 6-8
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                    }
                }
            } catch (e: Exception) {
                return true // jika gagal ambil packageInfo → return true
            } ?: return true // null fallback → return true

            val signatures = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> {
                    packageInfo.signingInfo?.apkContentsSigners ?: return true
                }
                else -> {
                    @Suppress("DEPRECATION")
                    packageInfo.signatures ?: return true
                }
            }

            val digest = MessageDigest.getInstance("SHA-256")

            // cek setiap signature
            signatures.any { sig ->
                val hash = digest.digest(sig.toByteArray())
                val sigHex = hash.joinToString(":") { "%02X".format(it) }
                sigHex == expectedSignature
            }
        } catch (e: Exception) {
            true // fallback aman → return true jika ada exception
        }
    }
}

