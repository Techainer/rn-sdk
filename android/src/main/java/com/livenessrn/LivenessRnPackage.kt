package com.livenessrn
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.ViewManager
import java.util.Collections


class LivenessRnPackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    // return listOf(LivenessRnModule(reactContext))
    return Collections.emptyList()
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return listOf(LivenessViewManager(reactContext))
  }

  companion object {
    fun sendEvent(
      context: ReactApplicationContext,
      eventName: String?,
      params: WritableMap?
    ) {
//      context
//        ?.getJSModule(RCTDeviceEventEmitter::class.java)
//        ?.emit(eventName!!, params)
      context
          .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        ?.emit(eventName!!, params)
    }
  }
}
