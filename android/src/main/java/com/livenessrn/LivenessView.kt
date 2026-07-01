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
import java.util.Locale;
import java.text.SimpleDateFormat;
import java.util.Date;
import com.example.ekycplugin.eykc.utils.ImageUtils;

interface LivenessFragmentListener {
  fun onLivenessEvent(viewId: Int, event: WritableMap)
}

class LivenessView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null
) : FrameLayout(context, attrs)

class LivenessFragment : Fragment(), FaceAuthenticationView.OnFaceListener {

  private lateinit var faceAuthView: FaceAuthenticationView
  var listener: LivenessFragmentListener? = null
  var isDebug: Boolean = false
  var viewId: Int = -1

  override fun onCreateView(
    inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
  ): View {
    faceAuthView = FaceAuthenticationView(requireActivity()).apply {
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
      // setIsLogin(false);
      startCamera()
      setStartStreamImage(true)
      setFaceAuthenticationCallback(this@LivenessFragment)
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
    val originalImage = resizeAndCompressImageToBase64(path = images[0])
    val colorImage = resizeAndCompressImageToBase64(path = images[1])
    val map = Arguments.createMap()
    map.putString("livenessColorImage", colorImage)
    map.putString("livenessOriginalImage", originalImage)
    map.putString("color", "${colorString}3")
    listener?.onLivenessEvent(viewId, map)
    if (isDebug) {
        saveImagesToGallery(images)
    }
  }

  fun saveImagesToGallery(images: MutableList<String>?) {
    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())

    val originalFileName = "face_original_$timeStamp.png"
    val colorFileName = "face_color_$timeStamp.png"

    if (!images.isNullOrEmpty()) {
        ImageUtils.saveImageToGallery(context, loadBitmapFromFile(images[0]), originalFileName)
        println("Saved original image as: $originalFileName")
    } else {
        System.err.println("Images list is null or empty, cannot save original image.")
    }

    when {
        images != null && images.size > 1 -> {
            ImageUtils.saveImageToGallery(context, loadBitmapFromFile(images[1]), colorFileName)
            println("Saved color image as: $colorFileName")
        }
        images != null && images.size == 1 -> {
            println("Only one image available, cannot save color image.")
        }
        else -> {
            System.err.println("Images list is null or empty, cannot save color image.")
        }
    }
  }

  fun loadBitmapFromFile(filePath: String?): Bitmap? {
    if (filePath.isNullOrEmpty()) {
        println("ImageUtils File path is null or empty, cannot load bitmap.")
        return null
    }

    val file = File(filePath)
    if (!file.exists()) {
        println("ImageUtils File does not exist at path: $filePath")
        return null
    }

    return try {
        BitmapFactory.decodeFile(filePath)
    } catch (e: Exception) {
        println("ImageUtils Error loading bitmap from file: $filePath $e")
        null
    }
  }

  override fun onResultsLiveness(livenessResult: FaceLiveness.FaceLivenessResult?) {
    val map = Arguments.createMap()
    println("onResultsLiveness: $map")
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

  private fun resizeAndCompressImageToBase64(path: String, maxSize: Int = 1024, compression: Int = 95): String? {
    try {
      val file = File(path)
      if (!file.exists()) {
        throw IllegalArgumentException("File not found at path: $path")
      }

      // 1. Decode ảnh từ file
      val bitmap = BitmapFactory.decodeFile(path)
        ?: throw IllegalArgumentException("Failed to decode image at path: $path")

      // 2. Resize 1 lần nếu cạnh dài nhất > maxSize, giữ đúng tỷ lệ. Ngược lại giữ nguyên.
      val longestSide = maxOf(bitmap.width, bitmap.height)
      val finalBitmap = if (longestSide > maxSize) {
        val scale = maxSize.toFloat() / longestSide.toFloat()
        val newWidth = Math.round(bitmap.width * scale)
        val newHeight = Math.round(bitmap.height * scale)
        Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
      } else {
        bitmap
      }

      // 3. Nén JPEG đúng 1 lần theo chất lượng truyền vào
      val outputStream = ByteArrayOutputStream()
      finalBitmap.compress(Bitmap.CompressFormat.JPEG, compression, outputStream)
      val byteArray = outputStream.toByteArray()
      outputStream.close()

      // 4. Base64 liền mạch (NO_WRAP), an toàn cho API
      return Base64.encodeToString(byteArray, Base64.NO_WRAP)

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
