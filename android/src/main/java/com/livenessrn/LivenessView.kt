package com.livenessrn

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.example.ekycplugin.eykc.utils.FaceAuthenticationView
import com.example.ekycplugin.eykc.utils.faceauth.FaceLiveness
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.UiThreadUtil.runOnUiThread
import com.facebook.react.bridge.WritableMap
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

interface LivenessFragmentListener {
  fun onLivenessEvent(event: WritableMap)
}

class LivenessView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null
) : FrameLayout(context, attrs)

class LivenessFragment : Fragment(), FaceAuthenticationView.OnFaceListener {

  private lateinit var faceAuthView: FaceAuthenticationView
  private lateinit var maskView: LivenessMaskView
  var listener: LivenessFragmentListener? = null

  override fun onCreateView(
    inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
  ): View {
    faceAuthView = FaceAuthenticationView(requireActivity()).apply {
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
      startCamera()
      setStartStreamImage(true)
      setFaceAuthenticationCallback(this@LivenessFragment)
      maskView = LivenessMaskView(requireActivity())
      maskView.layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
      maskView.instructionText = "Hãy đưa mặt vào trong khung hình"
      addView(maskView)
    }
    return faceAuthView
  }

  override fun onDestroyView() {
    if (::faceAuthView.isInitialized) {
      faceAuthView.stop()
    }
    super.onDestroyView()
  }

  override fun onResultsExtracted(images: MutableList<String>?, colorString: String?) {
    if (images.isNullOrEmpty()) return
    val originalImage = convertPathToBase64WithLimitKB(path = images[0])
    val colorImage = convertPathToBase64WithLimitKB(path = images[1])
    val map = Arguments.createMap()
    map.putString("livenessColorImage", colorImage)
    map.putString("livenessOriginalImage", originalImage)
    map.putString("color", colorString)
    listener?.onLivenessEvent(map)
  }

  override fun onResultsLiveness(livenessResult: FaceLiveness.FaceLivenessResult?) {
    val resultMessage = livenessResult?.let { getResultMessage(it) }
    val map = Arguments.createMap()
    map.putString("result", resultMessage)
    println("onResultsLiveness: $map")
    println("Liveness result received: ${resultMessage ?: "null"}")

    runOnUiThread {
      maskView.let { mask ->
        if (resultMessage != "Hide mark view.") {
          mask.instructionText = resultMessage
          mask.overlayColor = Color.argb(102, 0, 0, 0)
        } else {
          mask.overlayColor = Color.TRANSPARENT
        }
      }
    }
  }

  private fun getResultMessage(livenessResult: FaceLiveness.FaceLivenessResult): String {
    return when (livenessResult.value) {
      0 -> "Hợp lệ"
      1 -> "Phát hiện bàn tay, vui lòng không che mặt"
      2 -> "Phát hiện khẩu trang, vui lòng tháo ra"
      3 -> "Phát hiện kính, vui lòng tháo ra"
      4 -> "Khuôn mặt bị che khuất"
      5 -> "Khuôn mặt bị nghiêng, vui lòng nhìn thẳng"
      6 -> "Khuôn mặt quá nhỏ, vui lòng đưa lại gần hơn"
      7 -> "Hãy đưa mặt vào trong khung hình"
      8 -> "Khuôn mặt bị lóa sáng"
      9 -> "Môi trường thiếu sáng"
      10 -> "Vui lòng giữ yên khuôn mặt"
      11 -> "Hoàn thành"
      12 -> "Khuôn mặt quá lớn, vui lòng đưa ra xa hơn"
      13 -> "Hide mark view." // Giữ nguyên theo ví dụ của bạn
      else -> "Hợp lệ"
    }
  }

  override fun onCheckHack(p0: Boolean, p1: String?) {
    TODO("Not yet implemented")
  }

  fun setBrightness(value: Float, activity: FragmentActivity) {
    val window = activity.window
    val handler = Handler(Looper.getMainLooper())
    handler.post {
      if (window != null) {
        window.attributes = window.attributes.apply {
          screenBrightness = value
        }
      }
    }
  }

  private fun convertPathToBase64WithLimitKB(path: String, maxSizeInKB: Int = 400): String? {
    try {
      val file = File(path)
      if (!file.exists()) {
        throw IllegalArgumentException("File not found at path: $path")
      }

      // 1. Decode the image from the file path
      var bitmap = BitmapFactory.decodeFile(path)
        ?: throw IllegalArgumentException("Failed to decode image at path: $path")

      // 2. Compress and resize the image to reduce size
      var quality = 100 // Start with max quality
      var byteArray: ByteArray
      do {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream) // Compress as JPEG
        byteArray = outputStream.toByteArray()
        outputStream.close()

        // Reduce quality if size is still too large
        quality -= 5

        // Resize bitmap if needed
        if (byteArray.size > maxSizeInKB * 1024 && quality <= 5) {
          val newWidth = (bitmap.width * 0.9).toInt() // Reduce width by 10%
          val newHeight = (bitmap.height * 0.9).toInt() // Reduce height by 10%
          bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
          quality = 100 // Reset quality for resized image
        }
      } while (byteArray.size > maxSizeInKB * 1024 && quality > 0)

      // 3. Convert the byte array to Base64 string
      return Base64.encodeToString(byteArray, Base64.DEFAULT)

    } catch (e: Exception) {
      e.printStackTrace()
      return null // Return null if an error occurs
    }
  }

  fun base64ToPathFile(b64Data: String?, context: Context): String? {
    return try {
      val decodedBytes = Base64.decode(b64Data, Base64.DEFAULT)
      val file = File(context.cacheDir, "image_${System.currentTimeMillis()}.jpg")

      // Write the decoded bytes to the file
      FileOutputStream(file).use { outputStream ->
        outputStream.write(decodedBytes)
      }

      // Return the absolute path of the file
      file.absolutePath
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
  }

  fun base64ToBitmap(b64Data: String?): Bitmap? {
    return try {
      val decodedString = Base64.decode(b64Data, Base64.DEFAULT)
      val inputStream: InputStream = ByteArrayInputStream(decodedString)
      BitmapFactory.decodeStream(inputStream)
    } catch (e: Error) {
      e.printStackTrace()
      null
    }
  }
}
