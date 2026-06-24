package com.example.virent_mobile

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "virent/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimInfo" -> {
                        if (!hasSmsPermission()) {
                            result.error("PERMISSION_DENIED", "SEND_SMS not granted", null)
                            return@setMethodCallHandler
                        }
                        result.success(getSimCards())
                    }
                    "sendSms" -> {
                        if (!hasSmsPermission()) {
                            result.error("PERMISSION_DENIED", "SEND_SMS not granted", null)
                            return@setMethodCallHandler
                        }
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val simSlot = call.argument<Int>("simSlot") ?: 0
                        sendSms(phone, message, simSlot)
                        result.success(true)
                    }
                    "hasSmsPermission" -> result.success(hasSmsPermission())
                    "requestSmsPermission" -> { requestSmsPermission(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestSmsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(
                arrayOf(Manifest.permission.SEND_SMS, Manifest.permission.READ_PHONE_STATE), 1001
            )
        }
    }

    private fun getSimCards(): List<Map<String, Any>> {
        val sims = mutableListOf<Map<String, Any>>()
        try {
            val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                for (sub in sm.activeSubscriptionInfoList ?: emptyList()) {
                    sims.add(mapOf(
                        "slotIndex" to sub.simSlotIndex,
                        "carrierName" to (sub.carrierName?.toString() ?: "Unknown"),
                        "phoneNumber" to (sub.number ?: "Unknown"),
                        "iccId" to (sub.iccId ?: "Unknown"),
                    ))
                }
            }
        } catch (_: Exception) {}
        if (sims.isEmpty()) {
            sims.add(mapOf("slotIndex" to 0, "carrierName" to "SIM 1", "phoneNumber" to "Unknown", "iccId" to "unknown"))
        }
        return sims
    }

    private fun sendSms(phone: String, message: String, simSlot: Int) {
        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val subId = sm.activeSubscriptionInfoList?.find { it.simSlotIndex == simSlot }?.subscriptionId ?: -1
            if (subId != -1) SmsManager.getSmsManagerForSubscriptionId(subId) else SmsManager.getDefault()
        } else SmsManager.getDefault()

        val sentPI = PendingIntent.getBroadcast(this, 0, Intent("SMS_SENT"), PendingIntent.FLAG_IMMUTABLE)
        smsManager.sendTextMessage(phone, null, message, sentPI, null)
    }
}
