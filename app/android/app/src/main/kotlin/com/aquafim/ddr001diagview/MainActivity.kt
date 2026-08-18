package com.aquafim.ddr001diagview

import android.content.Context
import android.hardware.input.InputManager
import android.view.InputDevice
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), InputManager.InputDeviceListener {
    private var remoteControlChannel: MethodChannel? = null
    private var remoteControlActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        remoteControlChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ddr001/remote_test_control",
        )
        remoteControlChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setActive" -> {
                    remoteControlActive = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                "getRemoteConnected" -> result.success(hasExternalRemote())
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        inputManager().registerInputDeviceListener(this, null)
        publishRemoteConnection()
    }

    override fun onStop() {
        inputManager().unregisterInputDeviceListener(this)
        super.onStop()
    }

    private fun inputManager() =
        getSystemService(Context.INPUT_SERVICE) as InputManager

    private fun hasExternalRemote(): Boolean = inputManager().inputDeviceIds.any { id ->
        val device = inputManager().getInputDevice(id) ?: return@any false
        val supportedSources = InputDevice.SOURCE_KEYBOARD or InputDevice.SOURCE_DPAD
        device.isExternal && device.sources and supportedSources != 0
    }

    private fun publishRemoteConnection() {
        remoteControlChannel?.invokeMethod("remoteConnectionChanged", hasExternalRemote())
    }

    override fun onInputDeviceAdded(deviceId: Int) = publishRemoteConnection()

    override fun onInputDeviceRemoved(deviceId: Int) = publishRemoteConnection()

    override fun onInputDeviceChanged(deviceId: Int) = publishRemoteConnection()

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val isShutterVolumeKey = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        if (isShutterVolumeKey && remoteControlActive) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                remoteControlChannel?.invokeMethod("shutterPressed", null)
            }
            // Consume both DOWN and UP so Android does not change the volume.
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
