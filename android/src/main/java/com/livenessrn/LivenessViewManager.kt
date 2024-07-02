package com.livenessrn

import android.os.Bundle
import android.util.Log
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
import io.liveness.flash.core.LiveNessSDKBio
import io.liveness.flash.core.model.LivenessRequestBio


class LivenessViewManager(
  private val reactContext: ReactApplicationContext
) : ViewGroupManager<LivenessView>() {
//  private var deviceId = ""
  private var secret = "ABCDEFGHIJKLMNOP"
  private var debugging = false
  private var minFaceSize: Float = 0.15F
  private var isThreeDimension = false

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

  @ReactProp(name = "minFaceSize")
  fun setMinFaceSize(view: FrameLayout, minFaceSize: Float) {
    this.minFaceSize = minFaceSize
  }

  @ReactProp(name = "debugging")
  fun setDebugging(view: FrameLayout, debugging: Boolean) {
    this.debugging = debugging
  }

  @ReactProp(name = "isThreeDimension")
  fun setIsThreeDimension(view: FrameLayout, isThreeDimension: Boolean) {
    this.isThreeDimension = isThreeDimension
  }

  /**
   * Replace your React Native view with a custom fragment
   */
  fun createFragment(root: FrameLayout, reactNativeViewId: Int) {
    val parentView = root.findViewById<ViewGroup>(reactNativeViewId)
    setupLayout(parentView)


    val activity = reactContext?.currentActivity as FragmentActivity

    LiveNessSDKBio.startLiveNess(
      activity,
      getLivenessRequest(),
      activity.supportFragmentManager,
      reactNativeViewId, null)
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

  private fun getLivenessRequest(): LivenessRequestBio {
    val activity = reactContext?.currentActivity as FragmentActivity

//    if (LiveNessSDKBio.getDeviceId(activity)?.isNotEmpty() == true) {
//      deviceId = LiveNessSDKBio.getDeviceId(activity)!!
//    }

    return LivenessRequestBio(
      duration = 600, isDebug = debugging, secret = secret, mMinFaceSize = this.minFaceSize
    )
  }
}
