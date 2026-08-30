package com.example.screen_lock

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import java.util.concurrent.Executor

/**
 * Transparent Activity that hosts Android's native BiometricPrompt.
 *
 * androidx.biometric.BiometricPrompt strictly requires a FragmentActivity.
 * Since the app lock overlay runs within a background Service (TYPE_APPLICATION_OVERLAY window),
 * launching this transparent FragmentActivity provides the real native Android Fingerprint
 * unlock dialog and secure PIN reset verification over any app.
 */
class BiometricPromptActivity : FragmentActivity() {

    companion object {
        private const val TAG = "BiometricPromptActivity"
        const val EXTRA_PACKAGE = "extra_package"
        const val EXTRA_APP_NAME = "extra_app_name"
        const val EXTRA_MODE = "extra_mode"

        const val MODE_UNLOCK = "unlock"
        const val MODE_FORGOT_PIN = "forgot_pin"

        @Volatile
        private var activeCallback: ((Boolean) -> Unit)? = null

        fun start(context: Context, packageName: String, appName: String, mode: String = MODE_UNLOCK) {
            startWithCallback(context, packageName, appName, mode, null)
        }

        fun startWithCallback(
            context: Context,
            packageName: String,
            appName: String,
            mode: String = MODE_UNLOCK,
            callback: ((Boolean) -> Unit)? = null
        ) {
            try {
                // If there's an existing unfulfilled callback, notify false first to clear it
                activeCallback?.invoke(false)
                activeCallback = callback

                val intent = Intent(context, BiometricPromptActivity::class.java).apply {
                    putExtra(EXTRA_PACKAGE, packageName)
                    putExtra(EXTRA_APP_NAME, appName)
                    putExtra(EXTRA_MODE, mode)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NO_ANIMATION
                }
                context.startActivity(intent)
            } catch (e: Throwable) {
                Log.e(TAG, "Failed to start BiometricPromptActivity: ${e.message}", e)
                val cb = activeCallback
                activeCallback = null
                cb?.invoke(false)
            }
        }

        fun isBiometricAvailable(context: Context): Boolean {
            return try {
                val biometricManager = BiometricManager.from(context)
                val canAuth = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    biometricManager.canAuthenticate(
                        BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK
                    )
                } else {
                    @Suppress("DEPRECATION")
                    biometricManager.canAuthenticate()
                }
                // Return true if enrolled OR hardware exists (allows user tap to prompt or guide)
                canAuth == BiometricManager.BIOMETRIC_SUCCESS || canAuth == BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED
            } catch (e: Throwable) {
                try {
                    val compat = androidx.core.hardware.fingerprint.FingerprintManagerCompat.from(context)
                    compat.isHardwareDetected
                } catch (t: Throwable) {
                    true // Fallback to true so the button remains accessible
                }
            }
        }
    }

    private var callbackDispatched = false

    private fun dispatchCallback(success: Boolean) {
        if (callbackDispatched) return
        callbackDispatched = true
        val cb = activeCallback
        activeCallback = null
        cb?.invoke(success)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (MainActivity.isRecentAppsPrivacyEnabled(this)) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                try {
                    setRecentsScreenshotEnabled(false)
                } catch (e: Throwable) {
                    // OEM fallback
                }
            }
        }
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)

        val targetPackage = intent.getStringExtra(EXTRA_PACKAGE) ?: ""
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "App"
        val mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_UNLOCK

        authenticate(targetPackage, appName, mode)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val targetPackage = intent.getStringExtra(EXTRA_PACKAGE) ?: ""
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "App"
        val mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_UNLOCK
        authenticate(targetPackage, appName, mode)
    }

    private fun authenticate(targetPackage: String, appName: String, mode: String) {
        callbackDispatched = false
        val executor: Executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                Log.d(TAG, "Biometric authentication error ($errorCode): $errString")
                dispatchCallback(false)
                finish()
                @Suppress("DEPRECATION")
                overridePendingTransition(0, 0)
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                Log.d(TAG, "Biometric authentication succeeded for $targetPackage in mode $mode")

                if (mode == MODE_FORGOT_PIN) {
                    // CRITICAL: DO NOT unlock targetPackage! Securely notify overlay to enter PIN reset mode
                    OverlayController.sendToOverlay("RESET_PIN_AUTHORIZED")
                } else {
                    // Standard unlock
                    if (targetPackage.isNotEmpty()) {
                        NativeLockManager.markAppUnlocked(this@BiometricPromptActivity, targetPackage)
                        if (targetPackage == packageName) {
                            NativeLockManager.markUninstallAuthorized()
                        }
                    }
                    OverlayController.dismissOverlay(this@BiometricPromptActivity)
                }

                dispatchCallback(true)
                finish()
                @Suppress("DEPRECATION")
                overridePendingTransition(0, 0)
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                Log.d(TAG, "Biometric authentication failed (fingerprint not recognized)")
            }
        })

        try {
            val promptInfo = if (mode == MODE_FORGOT_PIN) {
                val builder = BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Reset App Lock PIN")
                    .setSubtitle("Confirm identity to reset your PIN")

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    builder.setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                } else {
                    @Suppress("DEPRECATION")
                    builder.setDeviceCredentialAllowed(true)
                }
                builder.build()
            } else {
                val builder = BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Unlock $appName")
                    .setSubtitle("Touch fingerprint sensor to continue")
                    .setNegativeButtonText("Use PIN")

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    builder.setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK)
                }
                builder.build()
            }

            biometricPrompt.authenticate(promptInfo)
        } catch (e: Throwable) {
            Log.e(TAG, "BiometricPrompt exception: ${e.message}", e)
            try {
                // Universal fallback prompt
                val fallbackPrompt = if (mode == MODE_FORGOT_PIN) {
                    val builder = BiometricPrompt.PromptInfo.Builder()
                        .setTitle("Reset App Lock PIN")
                        .setSubtitle("Confirm identity to reset your PIN")
                    @Suppress("DEPRECATION")
                    builder.setDeviceCredentialAllowed(true)
                    builder.build()
                } else {
                    BiometricPrompt.PromptInfo.Builder()
                        .setTitle("Unlock $appName")
                        .setSubtitle("Touch fingerprint sensor to continue")
                        .setNegativeButtonText("Use PIN")
                        .build()
                }
                biometricPrompt.authenticate(fallbackPrompt)
            } catch (fallbackEx: Throwable) {
                Log.e(TAG, "BiometricPrompt fallback exception: ${fallbackEx.message}", fallbackEx)
                dispatchCallback(false)
                finish()
                @Suppress("DEPRECATION")
                overridePendingTransition(0, 0)
            }
        }
    }

    override fun onDestroy() {
        dispatchCallback(false)
        super.onDestroy()
    }

    override fun finish() {
        super.finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
