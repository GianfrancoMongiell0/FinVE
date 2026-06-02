package com.finve.app

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.finve.app/launcher_icon"

    // Main activity component (default icon)
    private val mainActivity = ".MainActivity"

    // Alias map: logoId -> component suffix
    private val aliases = mapOf(
        "v4" to ".LauncherV4",
        "v1" to ".LauncherV1",
        "v6" to ".LauncherV6",
        "v7" to ".LauncherV7",
        "v8" to ".LauncherV8",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val logoId = call.argument<String>("logoId")
                    if (logoId == null || !aliases.containsKey(logoId)) {
                        result.error("INVALID_LOGO", "Unknown logo id: $logoId", null)
                        return@setMethodCallHandler
                    }
                    try {
                        setLauncherIcon(logoId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_ICON_FAILED", e.message, null)
                    }
                }
                "getIcon" -> {
                    result.success(getCurrentIcon())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setLauncherIcon(logoId: String) {
        val pm = packageManager

        // Enable the chosen alias, disable all others
        for ((id, suffix) in aliases) {
            val component = ComponentName(packageName, packageName + suffix)
            val state = if (id == logoId)
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            pm.setComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
        }

        // Disable the default MainActivity launcher entry
        // (so only one launcher icon shows up)
        val main = ComponentName(packageName, packageName + mainActivity)
        pm.setComponentEnabledSetting(
            main,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun getCurrentIcon(): String {
        val pm = packageManager
        for ((id, suffix) in aliases) {
            val component = ComponentName(packageName, packageName + suffix)
            val state = pm.getComponentEnabledSetting(component)
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return id
            }
        }
        return "default" // MainActivity is active
    }
}