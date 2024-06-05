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
import com.liveness.sdk.core.utils.CallbackLivenessListener
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
    LiveNessSDK.setConfigSDK(
      reactApplicationContext.currentActivity!!,
      LivenessRequest(
        appId = appId, clientTransactionId = clientTransactionId,
        baseURL = baseURL, publicKey = publicKey, privateKey = privateKey,
        isDebug = true
      )
    )
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
  fun registerFace(image: String? = null, callback: Callback? = null) {
    val activity = reactApplicationContext.currentActivity as FragmentActivity
    currentActivity!!.runOnUiThread {
      LiveNessSDK.registerFace(
        activity,
        image!!,
        object : CallbackLivenessListener {
          override fun onCallbackLiveness(data: LivenessModel?) {
            val resultData: WritableMap = WritableNativeMap()
            resultData.putInt("status", data?.status ?: -1)
            resultData.putString("data", "${data?.data ?: ""}")
            resultData.putString("message", "${data?.message ?: ""}")
            resultData.putString("code", "${data?.code ?: ""}")
            resultData.putString("pathVideo", "${data?.pathVideo ?: ""}")
            resultData.putString("faceImage", "${data?.faceImage ?: ""}")
            resultData.putString("livenessImage", "${data?.livenessImage ?: ""}")
            callback?.invoke(resultData)
          }
        })
    }
  }

//  private fun getLivenessRequest(image: String? = null): LivenessRequest {
//    val privateKey = "-----BEGIN PRIVATE KEY-----\n" +
//      "MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCtZW3L3TiJ7+Hb\n" +
//      "KlEXd3pkjKiwjk9fZgmFAWzKirkjdBHS9YnM7tp8tUNIHGb87o6ZjkcnNOhbdlRw\n" +
//      "L8Zl/eAu1J7UQ85smzw+5L36wsQB9YHQw4dikWin7M355qNn0IIxhWA3iqUFEhWN\n" +
//      "czYco+W6+w59IAtYVRmRnDUUC/UjPdPYnwd3rz7i0Hea4r7Q/4AicDVN6p3duIwg\n" +
//      "+SDVxJomlpsdc+fj/3oOrfdvUS00VVngUUOlswSnSMvKcRmM8NKcaSGKq2bt9AxN\n" +
//      "iZsI+4mjWfnsYq0Ms5RQBBF0xju/rWez664x/KVX7j9XhCvq8BGflJ91donYFuMA\n" +
//      "Xgy5q5NjAgMBAAECggEAIswYHLFoh0X8rV7wpyTzCvqvX78vbpWrk2WVz4/HV7YT\n" +
//      "XaKo5NeKQTyfI/mPMXMuauKCpPuZJcG5cEomJpGsS7mfpjl1U5ZToMuG1KwBaeM7\n" +
//      "CgozQTStLAX50AzY/hx6BDYf+QV52GqoqJpWYakCkWOQpMupezCY0P/oJv2/VDLf\n" +
//      "lbGNN1ZvscK+sf80UyvdWArNI54TtD4DbSj3n0O67qd3S4JACAV1V4yOhPQMOrpk\n" +
//      "IlnKpOS2jUMq1JJEzt3msLmXx1LaIB2wte4DqDlwd7XW2XdX3hSY27o4y24Axa6N\n" +
//      "WnCc/HymM+LwkXWYqgWQhh+ey7JtTF2et29UsX/ZAQKBgQDZdiqKCWCF8e2Ndgbk\n" +
//      "jtvEov9kWLvsqJo6x391/cBoa4SEiO7xS8D+Lm+Ym8SuffnCWOKqMZxnmVnDUHwf\n" +
//      "h8LF+k69LydMP8vKCKzD0LGN0EZ6xup8D6m8jU3omT2yZGssyoxXYQznUcn5CViY\n" +
//      "L9eQVXw4YLSe63D9VIqMxm9/ZQKBgQDMIBjfDHIW1b53wT2FMLIMZR8eiTUXAHPQ\n" +
//      "Mp2zZ14AKoSUp1THDnuTmnHzWgn6/7pKWz+hk45LG8JXHnOMX3GFzvG9aQMkRuuD\n" +
//      "Sd7VipCCp1o4dsoSrHIJ5TiQJOZaQgureesHdOAeP0STxGVOmX7DFhUxSzwjAZz2\n" +
//      "FDHwrHNPJwKBgQDN/1Q4wr0+5XiE4uOQq4uf8FBCPJR4kRbYy5cArMoRoJg9/IFs\n" +
//      "7rf5kP+B7z0Xlpp78jt1wd1Jfkk77ghGzhJB/OWN7Rcq8dwYnLMcI5uunTfGopwJ\n" +
//      "vcSqqqi8yD1buiiUm6LqOzNABYhwctwL/nYTcgdkWKeBS8MTF3zP8kI4yQKBgQCl\n" +
//      "+IcgfPca+ApZRuclr7VlfKcz5e4j2LtSEoXFRIva6LdKQ1AcVftGxbJXYuNwkZPA\n" +
//      "N7diQh7VlSmMOndLMKOWX/CQyJzEV2HRKzQjPvpHMZmbBYNCcbJ7t0Qpd8dQphjl\n" +
//      "AUmHk5FTJrA00eBpa0b1irQKk5i/AeXE9CCzBxTuywKBgA3wbWbuhSe/kL3QOuuG\n" +
//      "GBtH5E7FsHQ++PphMcdpeSVaA6yiVc/3Iu2d+p+Nda3VGiqD6/uVVRWDxcE3u3eQ\n" +
//      "88Xwl6yudl9moadaaYydjWB3wIP9lZKW7MzV86HJnXvr4JNsre0JqO+OBDSI3YUb\n" +
//      "8Ywxgfrp5wx1/7VYTLOdROUh\n" +
//      "-----END PRIVATE KEY-----"
//    val public_key = "-----BEGIN CERTIFICATE-----\n" +
//      "MIIE8jCCA9qgAwIBAgIQVAESDxKv/JtHV15tvtt1UjANBgkqhkiG9w0BAQsFADAr\n" +
//      "MQ0wCwYDVQQDDARJLUNBMQ0wCwYDVQQKDARJLUNBMQswCQYDVQQGEwJWTjAeFw0y\n" +
//      "MzA2MDcwNjU1MDNaFw0yNjA2MDkwNjU1MDNaMIHlMQswCQYDVQQGEwJWTjESMBAG\n" +
//      "A1UECAwJSMOgIE7hu5lpMRowGAYDVQQHDBFRdeG6rW4gSG/DoG5nIE1haTFCMEAG\n" +
//      "A1UECgw5Q8OUTkcgVFkgQ1AgROG7ikNIIFbhu6QgVsOAIEPDlE5HIE5HSOG7hiBT\n" +
//      "4buQIFFVQU5HIFRSVU5HMUIwQAYDVQQDDDlDw5RORyBUWSBDUCBE4buKQ0ggVuG7\n" +
//      "pCBWw4AgQ8OUTkcgTkdI4buGIFPhu5AgUVVBTkcgVFJVTkcxHjAcBgoJkiaJk/Is\n" +
//      "ZAEBDA5NU1Q6MDExMDE4ODA2NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC\n" +
//      "ggEBAJO6JDU+kNEUIiO6m75LOfgHkwGExYFv0tILHInS9CkK2k0FjmvU8VYJ0cQA\n" +
//      "sGGabpHIwfh07llLfK3TUZlhnlFZYRrYvuexlLWQydjHYPqT+1c3iYaiXXcOqEjm\n" +
//      "OupCj71m93ThFrYzzI2Zx07jccRptAAZrWMjI+30vJN7SDxhYsD1uQxYhUkx7psq\n" +
//      "MqD4/nOyaWzZHLU94kTAw5lhAlVOMu3/6pXhIltX/097Wji1eyYqHFu8w7q3B5yW\n" +
//      "gJYugEZfplaeLLtcTxok4VbQCb3cXTOSFiQYJ3nShlBd89AHxaVE+eqJaMuGj9z9\n" +
//      "rdIoGr9LHU/P6KF+/SLwxpsYgnkCAwEAAaOCAVUwggFRMAwGA1UdEwEB/wQCMAAw\n" +
//      "HwYDVR0jBBgwFoAUyCcJbMLE30fqGfJ3KXtnXEOxKSswgZUGCCsGAQUFBwEBBIGI\n" +
//      "MIGFMDIGCCsGAQUFBzAChiZodHRwczovL3Jvb3RjYS5nb3Yudm4vY3J0L3ZucmNh\n" +
//      "MjU2LnA3YjAuBggrBgEFBQcwAoYiaHR0cHM6Ly9yb290Y2EuZ292LnZuL2NydC9J\n" +
//      "LUNBLnA3YjAfBggrBgEFBQcwAYYTaHR0cDovL29jc3AuaS1jYS52bjA0BgNVHSUE\n" +
//      "LTArBggrBgEFBQcDAgYIKwYBBQUHAwQGCisGAQQBgjcKAwwGCSqGSIb3LwEBBTAj\n" +
//      "BgNVHR8EHDAaMBigFqAUhhJodHRwOi8vY3JsLmktY2Eudm4wHQYDVR0OBBYEFE6G\n" +
//      "FFM4HXne9mnFBZInWzSBkYNLMA4GA1UdDwEB/wQEAwIE8DANBgkqhkiG9w0BAQsF\n" +
//      "AAOCAQEAH5ifoJzc8eZegzMPlXswoECq6PF3kLp70E7SlxaO6RJSP5Y324ftXnSW\n" +
//      "0RlfeSr/A20Y79WDbA7Y3AslehM4kbMr77wd3zIij5VQ1sdCbOvcZXyeO0TJsqmQ\n" +
//      "b46tVnayvpJYW1wbui6smCrTlNZu+c1lLQnVsSrAER76krZXaOZhiHD45csmN4dk\n" +
//      "Y0T848QTx6QN0rubEW36Mk6/npaGU6qw6yF7UMvQO7mPeqdufVX9duUJav+WBJ/I\n" +
//      "Y/EdqKp20cAT9vgNap7Bfgv5XN9PrE+Yt0C1BkxXnfJHA7L9hcoYrknsae/Fa2IP\n" +
//      "99RyIXaHLJyzSTKLRUhEVqrycM0UXg==\n" +
//      "-----END CERTIFICATE-----"
//    if (deviceId.isNullOrEmpty()) {
//      if (LiveNessSDK.getDeviceId(reactApplicationContext.currentActivity!!)?.isNotEmpty() == true) {
//        deviceId = LiveNessSDK.getDeviceId(reactApplicationContext.currentActivity!!).toString()
//      }
//    }
//    return LivenessRequest(
//      duration = 600, privateKey = privateKey,
//      appId = appId,
//      imageFace = image,
//      deviceId = deviceId, clientTransactionId = clientTransactionId, secret = secret,
//      baseURL = baseURL, publicKey = public_key
//    )
//  }
}
