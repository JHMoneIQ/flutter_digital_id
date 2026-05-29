package dev.hancock.flutter_digital_id

import android.app.Activity
import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.DigitalCredential
import androidx.credentials.ExperimentalDigitalCredentialApi
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetDigitalCredentialOption
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Android entry point for flutter_digital_id.
 *
 * Full coroutine-based implementation using ActivityAware + Credential Manager.
 */
class FlutterDigitalIdPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var credentialManager: CredentialManager

    private var activity: Activity? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        credentialManager = CredentialManager.create(context)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_digital_id/android")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    // --- ActivityAware ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getDigitalId" -> handleGetDigitalId(call, result)
            else -> result.notImplemented()
        }
    }

    @OptIn(ExperimentalDigitalCredentialApi::class)
    private fun handleGetDigitalId(call: MethodCall, result: Result) {
        val requestJson = call.argument<String>("requestJson")
        if (requestJson.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "requestJson is required", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Credential Manager requires an Activity context.", null)
            return
        }

        scope.launch {
            try {
                val option = GetDigitalCredentialOption(requestJson)
                val request = GetCredentialRequest(listOf(option))

                val response: GetCredentialResponse =
                        withContext(Dispatchers.IO) {
                            credentialManager.getCredential(currentActivity, request)
                        }

                val cred = response.credential
                val (rawBytes, format) =
                        if (cred is DigitalCredential) {
                            val data = cred.data
                            val json =
                                    data.getString("response")
                                            ?: data.getString("vp_token") ?: data.toString()
                            json.toByteArray(Charsets.UTF_8) to "openid4vp-vp-token"
                        } else {
                            cred.data.toString().toByteArray(Charsets.UTF_8) to
                                    "unknown-digital-credential"
                        }

                val base64 =
                        android.util.Base64.encodeToString(rawBytes, android.util.Base64.NO_WRAP)

                result.success(
                        mapOf(
                                "credentialFormat" to format,
                                "rawCredential" to base64,
                                "source" to "android-credential-manager"
                        )
                )
            } catch (e: NoCredentialException) {
                result.error(
                        "NoCredential",
                        e.message ?: "No matching digital credential found",
                        null
                )
            } catch (e: GetCredentialException) {
                val code =
                        if (e.message?.contains("cancel", ignoreCase = true) == true)
                                "userCancelled"
                        else "CREDENTIAL_ERROR"
                result.error(code, e.message ?: "Credential Manager error", e.toString())
            } catch (t: Throwable) {
                result.error("UNKNOWN", t.message ?: "Unexpected error", t.toString())
            }
        }
    }
}
