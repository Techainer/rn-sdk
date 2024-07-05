package com.livenessrn

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import io.liveness.flash.core.LiveNessSDKBio
import io.liveness.flash.core.model.LivenessModelBio
import io.liveness.flash.core.utils.CallbackLivenessListenerBio


class LivenessView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null
) : FrameLayout(context, attrs) {
  private val callBack = object : CallbackLivenessListenerBio {
    override fun onCallbackLiveness(livenessModel: LivenessModelBio?) {
      if (livenessModel != null && livenessModel.status != null && livenessModel.status == 200) {
        val map = Arguments.createMap()
        map.putBoolean("status", true)
        map.putInt("code", 200)
        map.putString("message", livenessModel.message ?: "")
        map.putString("request_id", livenessModel.requestId ?: "")
        map.putBoolean("success", true)
        map.putString("pathVideo", livenessModel.pathVideo ?: "")
        map.putString("faceImage", livenessModel.faceImage ?: "")
        map.putString("livenessImage", livenessModel.livenessImage ?: "")
        map.putString("transactionID", livenessModel.transactionID ?: "")
        map.putString("videoURL", livenessModel.pathVideo ?: "")

        if (livenessModel.data != null) {
          val mapData = Arguments.createMap()
          map.putString("faceMatchingScore", livenessModel.data?.faceMatchingScore ?: "")
          map.putString("livenessType", livenessModel.data?.livenessType ?: "")
          map.putDouble("livenesScore", (livenessModel.data?.livenesScore ?: 0).toDouble())
          map.putMap("data", mapData)
        }
        callNativeEvent(map)
      } else {
        val map = Arguments.createMap()
        if (livenessModel?.action != null) {
          map.putInt("action", livenessModel?.action ?: -1)
          map.putString("message", "${livenessModel?.message}")
          map.putString("livenessImage", "${livenessModel?.livenessImage}")
          map.putString("videoURL", "${livenessModel.pathVideo}")
          map.putString("color", "${livenessModel.bgColor}")
        } else {
          map.putBoolean("status", false)
          map.putInt("code", 101)
          map.putString("message", livenessModel?.message ?: "")
        }
        callNativeEvent(map)
      }
    }
  }

  init {
    LiveNessSDKBio.setCallbackListener(callBack)
  }

  fun callNativeEvent(map: WritableMap) {
    val reactContext = context as ReactContext
    val event = Arguments.createMap()
    event.putMap("data", map)
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "nativeClick",  //name has to be same as getExportedCustomDirectEventTypeConstants in MyCustomReactViewManager
      event
    )
  }
}
