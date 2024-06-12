package com.livenessrn

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.liveness.sdk.core.LiveNessSDK
import com.liveness.sdk.core.model.LivenessModel
import com.liveness.sdk.core.utils.CallbackLivenessListener


class LivenessView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null
) : FrameLayout(context, attrs) {
  private val callBack = object : CallbackLivenessListener {
    override fun onCallbackLiveness(livenessModel: LivenessModel?) {
      if (livenessModel != null && livenessModel.status != null && livenessModel.status == 200) {
        val map = Arguments.createMap()
        map.putInt("status", livenessModel.status ?: -1)
        map.putString("message", livenessModel.message ?: "")
        map.putString("request_id", livenessModel.requestId ?: "")
        map.putString("code", livenessModel.code ?: "")
        map.putBoolean("success", true)
        map.putString("pathVideo", livenessModel.pathVideo ?: "")
        map.putString("faceImage", livenessModel.faceImage ?: "")
        map.putString("livenessImage", livenessModel.livenessImage ?: "")
        map.putString("transactionID", livenessModel.transactionID ?: "")

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
          map.putString("message", livenessModel?.message ?: "")
        } else {
          map.putInt("status", livenessModel?.status ?: -1)
          map.putString("message", livenessModel?.message ?: "")
          map.putString("code", livenessModel?.code ?: "")
        }
        callNativeEvent(map)
      }
    }
  }

  init {
    LiveNessSDK.setCallbackListener(callBack)
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
