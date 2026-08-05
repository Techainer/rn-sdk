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

  private var isFlashCamera: Boolean = false
  private var isDebug: Boolean = false
  private var sessionKey: ByteArray? = null
  private var sessionId: String? = null
  private var timestamp: Long = System.currentTimeMillis()

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
    Log.d("LivenessViewManager", "receiveCommand - View ID assigned: $id")
    when (commandId.toInt()) {
      COMMAND_CREATE -> {
        Log.d("LivenessViewManager", "Creating fragment for view ID: $id")
        createFragment(root, reactNativeViewId)
      }
    }
  }

  @ReactPropGroup(names = ["width", "height"], customType = "Style")
  fun setStyle(view: FrameLayout, index: Int, value: Int) {
    if (index == 0) propWidth = value
    if (index == 1) propHeight = value
  }

  @ReactProp(name = "isFlashCamera")
  fun setIsFlashCamera(view: FrameLayout, isFlashCamera: Boolean) {
    this.isFlashCamera = isFlashCamera
  }

  @ReactProp(name = "isDebug")
  fun setIsDebug(view: FrameLayout, isDebug: Boolean) {
    this.isDebug = isDebug
  }

  @ReactProp(name = "sessionKey")
  fun setSessionKey(view: FrameLayout, sessionKeyB64: String?) {
    this.sessionKey = sessionKeyB64?.let {
      runCatching { android.util.Base64.decode(it, android.util.Base64.NO_WRAP) }.getOrNull()
    }
  }

  /**
   * UUID phiên do server cấp. Truyền NGUYÊN chuỗi: lowercase, giữ dấu gạch nối.
   * Strip gạch hoặc uppercase là HMAC fail phía server.
   */
  @ReactProp(name = "sessionId")
  fun setSessionId(view: FrameLayout, sessionId: String?) {
    this.sessionId = sessionId
  }

  @ReactProp(name = "timestamp")
  fun setTimestamp(view: FrameLayout, timestamp: Double) {
    this.timestamp = timestamp.toLong()
  }

  private fun callNativeEvent(viewId: Int, map: WritableMap) {
    try {
      // Validate ID trước khi gửi event
      if (viewId == -1) {
        Log.e("LivenessViewManager", "Cannot send event: Invalid view ID (-1)")
        return
      }
      Log.d("LivenessViewManager", "Sending event to view ID: $viewId")
      val reactContext = reactContext as ReactContext
      val event = Arguments.createMap()
      event.putMap("data", map)
      Handler(Looper.getMainLooper()).post {
        try {
          reactContext
            .getJSModule(RCTEventEmitter::class.java)
            ?.receiveEvent(
              viewId,
              "nativeClick",
              event
            )
          Log.d("LivenessViewManager", "Event sent successfully to view ID: $viewId")
        } catch (e: Exception) {
          Log.e("LivenessViewManager", "Error in receiveEvent: ${e.message}", e)
        }
      }
    } catch (e: Exception) {
      Log.e("LivenessViewManager", "Error preparing event: ${e.message}", e)
    }
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
    livenessFragment.isDebug = this.isDebug
    livenessFragment.sessionKey = this.sessionKey
    livenessFragment.sessionId = this.sessionId
    livenessFragment.timestamp = this.timestamp
    livenessFragment.viewId = reactNativeViewId

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

  override fun onLivenessEvent(viewId: Int, event: WritableMap) {
    Log.d("LivenessViewManager", "onLivenessEvent received for view ID: $viewId")
    callNativeEvent(viewId, event)
  }
}
