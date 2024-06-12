package com.livenessrn

import android.os.Bundle
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.FrameLayout.LayoutParams
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.annotations.ReactPropGroup
import com.liveness.sdk.core.LiveNessSDK
import com.liveness.sdk.core.model.LivenessRequest


class LivenessViewManager(
  private val reactContext: ReactApplicationContext
) : ViewGroupManager<LivenessView>() {

  private var requestId: String = ""
  private var appId: String = "com.qts.test"
  private var deviceId = ""
  private var secret = "ABCDEFGHIJKLMNOP"
  private var baseURL = ""
  private var privateKey = ""
  private var publicKey = ""
  private var debugging = false

  private var propWidth: Int? = null
  private var propHeight: Int? = null

  override fun getName() = REACT_CLASS

  override fun createViewInstance(reactContext: ThemedReactContext) =
    LivenessView(reactContext)

  override fun getCommandsMap() = mapOf("create" to COMMAND_CREATE)

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
    return MapBuilder.builder<String, Any>()
      .put(
        "nativeClick",  //Same as name registered with receiveEvent
        MapBuilder.of("registrationName", "onEvent")
      )
      .build()
  }

  /**
   * Handle "create" command (called from JS) and call createFragment method
   */
  override fun receiveCommand(
    root: LivenessView,
    commandId: String,
    args: ReadableArray?
  ) {
    super.receiveCommand(root, commandId, args)
    val reactNativeViewId = requireNotNull(args).getInt(0)

    when (commandId.toInt()) {
      COMMAND_CREATE -> createFragment(root, reactNativeViewId)
    }
  }

  @ReactPropGroup(names = ["width", "height"], customType = "Style")
  fun setStyle(view: FrameLayout, index: Int, value: Int) {
    if (index == 0) propWidth = value
    if (index == 1) propHeight = value
  }

  @ReactProp(name = "requestid")
  fun setRequestid(view: FrameLayout, requestid: String) {
    this.requestId = requestid
  }

  @ReactProp(name = "appId")
  fun setAppId(view: FrameLayout, appId: String) {
    this.appId = appId
  }

  @ReactProp(name = "baseUrl")
  fun setBaseUrl(view: FrameLayout, baseUrl: String) {
    this.baseURL = baseUrl
  }

  @ReactProp(name = "privateKey")
  fun setPrivateKey(view: FrameLayout, privateKey: String) {
    this.privateKey = privateKey
  }

  @ReactProp(name = "publicKey")
  fun setPublicKey(view: FrameLayout, publicKey: String) {
    this.publicKey = publicKey
  }

  @ReactProp(name = "debugging")
  fun setDebugging(view: FrameLayout, debugging: Boolean) {
    this.debugging = debugging
  }

  /**
   * Replace your React Native view with a custom fragment
   */
  fun createFragment(root: FrameLayout, reactNativeViewId: Int) {
    val parentView = root.findViewById<ViewGroup>(reactNativeViewId)
    setupLayout(parentView)

//    val bundle = Bundle()
//    bundle.putString("KEY_BUNDLE_SCREEN", "")
//    val myFragment = MainLiveNessActivity()
//    myFragment.arguments = bundle


    val activity = reactContext?.currentActivity as FragmentActivity

    LiveNessSDK.startLiveNess(
      activity,
      getLivenessRequest(),
      activity.supportFragmentManager,
      reactNativeViewId, null)

//    activity.supportFragmentManager
//      .beginTransaction()
//      .replace(reactNativeViewId, myFragment, reactNativeViewId.toString())
//      .commit()
  }

  fun setupLayout(view: View) {
    Choreographer.getInstance().postFrameCallback(object: Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        manuallyLayoutChildren(view)
        view.viewTreeObserver.dispatchOnGlobalLayout()
        Choreographer.getInstance().postFrameCallback(this)
      }
    })
  }

  /**
   * Layout all children properly
   */
  private fun manuallyLayoutChildren(view: View) {
    // propWidth and propHeight coming from react-native props
    if (propWidth != null && propHeight != null) {
      val width = requireNotNull(propWidth)
      val height = requireNotNull(propHeight)

      view.measure(
        View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))

      view.layout(0, 0, width, height)
    } else {
      view.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    }
  }

  companion object {
    private const val REACT_CLASS = "LivenessViewManager"
    private const val COMMAND_CREATE = 1

  }

  private fun getLivenessRequest(): LivenessRequest {
    val activity = reactContext?.currentActivity as FragmentActivity

    if (LiveNessSDK.getDeviceId(activity)?.isNotEmpty() == true) {
      deviceId = LiveNessSDK.getDeviceId(activity)!!
    }

    val optionRequest: HashMap<String, String> = HashMap()
    optionRequest["requestId"] = this.requestId
    optionRequest["clientTransactionId"] = this.requestId
    return LivenessRequest(
      duration = 600, privateKey = privateKey,
      appId = this.appId, isDebug = debugging,
      deviceId = deviceId, clientTransactionId = this.requestId, secret = secret,
      baseURL = baseURL, publicKey = publicKey
    )
  }
}
