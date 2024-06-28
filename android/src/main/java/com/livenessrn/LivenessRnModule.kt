package com.livenessrn

import android.util.Log
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.liveness.sdk.core.LiveNessSDK
import com.liveness.sdk.core.model.LivenessModel
import com.liveness.sdk.core.model.LivenessRequest
import com.liveness.sdk.core.utils.CallbackAPIListener
import com.liveness.sdk.core.utils.CallbackLivenessListener
import org.json.JSONObject
import java.util.UUID


class LivenessRnModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return NAME
  }

  companion object {
    const val NAME = "LivenessRn"
  }

  private var deviceId = ""
  private var appId = "com.pvc.test"
  private var secret = "ABCDEFGHIJKLMNOP"
  private var baseURL = "https://ekyc-sandbox.eidas.vn/face-matching"
  private var clientTransactionId = "TEST"

  @ReactMethod
  fun configure(appId: String, secret: String? = null, baseURL: String? = null, clientTransactionId: String? = null) {
    this.appId = appId
    if (secret != null && secret != "") {
      this.secret = secret
    }
    if (baseURL != null && baseURL != "") {
      this.baseURL = baseURL
    }
    if (clientTransactionId != null && clientTransactionId != "") {
      this.clientTransactionId = clientTransactionId
    }
  }

  @ReactMethod
  fun setConfigSDK(appId: String? = null, clientTransactionId: String? = null, baseURL: String? = null, publicKey: String? = null, privateKey: String? = null) {
//    LiveNessSDK.setConfigSDK(
//      reactApplicationContext.currentActivity!!,
//      LivenessRequest(
//        appId = appId, clientTransactionId = clientTransactionId,
//        baseURL = baseURL, publicKey = publicKey, privateKey = privateKey,
//        isDebug = true
//      )
//    )
  }

  @ReactMethod
  fun getDeviceId(callback: Callback? = null) {
    currentActivity!!.runOnUiThread {
      val mDeviceId = LiveNessSDK.getDeviceId(reactApplicationContext.currentActivity as FragmentActivity)
      val resultData: WritableMap = WritableNativeMap()
      if (mDeviceId?.isNotEmpty() == true) {
        deviceId = mDeviceId
        resultData.putString("deviceId", "$mDeviceId")
        callback?.invoke(resultData)
      } else {
        resultData.putString("deviceId", "empty")
        callback?.invoke(resultData)
      }
    }
  }

  @ReactMethod
  fun  initTransaction(callback: Callback? = null) {
    val activity = reactApplicationContext.currentActivity as FragmentActivity
    currentActivity!!.runOnUiThread {
      LiveNessSDK.initTransaction(
        activity,
        LiveNessSDK.getLivenessRequest()!!,
        object : CallbackAPIListener {
          override fun onCallbackResponse(data: String?) {
            var result: JSONObject? = null
            if (!data.isNullOrEmpty()) {
              result = JSONObject(data)
            }
            var status = -1
            if (result?.has("status") == true) {
              status = result.getInt("status")
            }
            var strMessage = "Error"
            if (result?.has("message") == true) {
              strMessage = result.getString("message")
            }
            val resultData: WritableMap = WritableNativeMap()
            if (status == 200) {
              val transactionId = result?.getString("data") ?: ""
              resultData.putString("transactionId", "${transactionId}")
            }
            resultData.putInt("status", status)
            callback?.invoke(resultData)
          }

        }
      )
    }
  }

  @ReactMethod
  fun registerFace(image: String? = null, callback: Callback? = null) {
    val activity = reactApplicationContext.currentActivity as FragmentActivity
    currentActivity!!.runOnUiThread {
      LiveNessSDK.registerFace(
        activity,
        image!!,
        object : CallbackLivenessListener {
          override fun onCallbackLiveness(data: LivenessModel?) {
            val resultData: WritableMap = WritableNativeMap()
            Log.d("LivenessModel", "$data")
            if (data?.status == 200) {
              resultData.putInt("status", data?.status ?: -1)
              resultData.putString("data", "${data?.requestId ?: ""}")
              resultData.putString("signature", "${data?.signature ?: ""}")
            } else {
              resultData.putInt("status", data?.status ?: -1)
              resultData.putString("code", "${data?.code ?: ""}")
              resultData.putString("message", "${data?.message ?: ""}")
            }
            callback?.invoke(resultData)
          }
        })
    }
  }
}
