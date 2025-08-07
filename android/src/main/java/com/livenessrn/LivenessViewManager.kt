package com.livenessrn

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.FrameLayout.LayoutParams
import android.app.Activity
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.annotations.ReactPropGroup
import com.facebook.react.uimanager.events.RCTEventEmitter
import java.util.Random

class LivenessViewManager(
  private val reactContext: ReactApplicationContext
) : ViewGroupManager<LivenessView>(), LivenessFragmentListener {

  private var requestId: String = ""
  private var appId: String = "com.qts.test"
  private var deviceId = ""
  private var secret = "ABCDEFGHIJKLMNOP"
  private var baseURL = ""
  private var privateKey = ""
  private var publicKey = ""
  private var debugging: Boolean = false
  private var isFlashCamera: Boolean = false

  private var propWidth: Int? = null
  private var propHeight: Int? = null
  private var id: Int = -1;

  override fun getName() = REACT_CLASS

  override fun createViewInstance(reactContext: ThemedReactContext): LivenessView {
    return LivenessView(reactContext)
  }

  override fun getCommandsMap() = mapOf("create" to COMMAND_CREATE)

  override fun onDropViewInstance(view: LivenessView) {
    super.onDropViewInstance(view)
    try {
      val activity = reactContext.currentActivity as FragmentActivity
      val fragmentManager = activity.supportFragmentManager
      if (fragmentManager.fragments.isNotEmpty()) {
        Log.d("createFragment", "remove fragment liveness")
        fragmentManager.fragments.forEach { fragment ->
          Log.d("remove fragment liveness", "${fragment.id}")
          if (id == fragment.id) {
            fragmentManager.beginTransaction().remove(fragment).commitAllowingStateLoss()
            setBrightness(originalBrightness ?: 0.3f)
          }
        }
      }
    } catch (_: Exception) {}
  }

  private fun setBrightness(value: Float) {
    val window = (reactContext.currentActivity as FragmentActivity).window
    val handler = Handler(Looper.getMainLooper())
    handler.post {
      if (window != null) {
          window.attributes = window.attributes.apply {
              screenBrightness = value
          }
      }
    }
  }

  fun getBrightness() {
    val window = (reactContext.currentActivity as FragmentActivity).window
    if (originalBrightness == null && window != null) {
        originalBrightness = window.attributes.screenBrightness
    }
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
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
    id = reactNativeViewId
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

  @ReactProp(name = "isFlashCamera")
  fun setIsFlashCamera(view: FrameLayout, isFlashCamera: Boolean) {
    this.isFlashCamera = isFlashCamera
  }

  private fun callNativeEvent(map: WritableMap) {
    val reactContext = reactContext as ReactContext
    val event = Arguments.createMap()
    event.putMap("data", map)
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "nativeClick",  //name has to be same as getExportedCustomDirectEventTypeConstants in MyCustomReactViewManager
      event
    )
  }

  private fun createFragment(root: FrameLayout, reactNativeViewId: Int) {
    val parentView = root.findViewById<ViewGroup>(reactNativeViewId)
    setupLayout(parentView)

    val activity = reactContext.currentActivity as FragmentActivity
    val fragmentManager = activity.supportFragmentManager
//    try {
//      Log.d("createFragment", "Success")
//      if (fragmentManager.fragments.isNotEmpty()) {
//        fragmentManager.fragments.forEach { fragment ->
//          fragmentManager.beginTransaction().remove(fragment).commitAllowingStateLoss()
//        }
//      }
//    } catch (e: Exception) {
//      Log.d("createFragment", "Error: $e")
//    }

    Log.d("createFragment", "Start liveness")
    Log.d("createFragment", "Start liveness: $reactNativeViewId")
    getBrightness()
    setBrightness(1f)

    val livenessFragment = LivenessFragment()
    livenessFragment.listener = this

    fragmentManager.beginTransaction()
      .replace(reactNativeViewId, livenessFragment, "LIVENESS_FRAGMENT_TAG")
      .commit()
  }

  private fun setupLayout(view: View) {
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
    var originalBrightness: Float? = null
  }

  override fun onLivenessEvent(event: WritableMap) {
    callNativeEvent(event)
  }
}
