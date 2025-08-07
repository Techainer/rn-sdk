package com.livenessrn

import android.content.Context
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.core.view.setPadding

class LivenessMaskView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

  // MARK: - UI Elements
  private val instructionLabel: TextView

  // Các đối tượng để vẽ overlay
  private val overlayPaint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val overlayPath = Path()
  private val areaViewFrame = RectF()

  // MARK: - Public Properties
  var instructionText: String? = null
    set(value) {
      field = value
      // Cập nhật text trên luồng UI
      post {
        instructionLabel.text = value
        instructionLabel.visibility = if (value.isNullOrEmpty()) GONE else VISIBLE
        requestLayout() // Yêu cầu layout lại để tính toán kích thước mới
      }
    }

  var overlayColor: Int = Color.argb(102, 0, 0, 0) // Mặc định là đen mờ 40% (0.4 alpha)
    set(value) {
      field = value
      overlayPaint.color = value
      invalidate() // Yêu cầu vẽ lại view với màu mới
    }

  // MARK: - Initialization
  init {
    // Rất quan trọng: Báo cho FrameLayout biết class này sẽ tự vẽ
    setWillNotDraw(false)

    // Cấu hình bút vẽ cho lớp overlay
    overlayPaint.color = this.overlayColor
    overlayPaint.style = Paint.Style.FILL

    // Cấu hình bút vẽ cho đường viền trắng của oval
    strokePaint.color = Color.WHITE
    strokePaint.style = Paint.Style.STROKE
    strokePaint.strokeWidth = 2.0f * resources.displayMetrics.density // 2dp

    // Cấu hình TextView cho chữ hướng dẫn
    instructionLabel = TextView(context).apply {
      // Thiết lập các thuộc tính
      setTextColor(Color.WHITE)
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
      gravity = Gravity.CENTER

      // Thiết lập padding
      val horizontalPadding = (12 * resources.displayMetrics.density).toInt()
      val verticalPadding = (8 * resources.displayMetrics.density).toInt()
      setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding)

      // Tạo background bo tròn
      background = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        setColor(Color.argb(128, 0, 0, 0)) // Đen mờ 50%
        // cornerRadius sẽ được cập nhật trong onLayout
      }
    }

    // Thêm TextView vào FrameLayout
    addView(instructionLabel)
  }

  // MARK: - Layout and Drawing

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)

    // --- 1. Tính toán frame cho vùng oval ---
    val width = w * 0.93f
    val height = width * 1.7f.coerceAtMost(h * 0.85f)
    val xPos = (w - width) / 2f
    val yPos = h / 8f
    areaViewFrame.set(xPos, yPos, xPos + width, yPos + height)

    // --- 2. Cập nhật path cho lớp overlay ---
    overlayPath.reset()
    overlayPath.fillType = Path.FillType.EVEN_ODD // Quy tắc để "đục lỗ"
    overlayPath.addRect(0f, 0f, w.toFloat(), h.toFloat(), Path.Direction.CW)
    overlayPath.addOval(areaViewFrame, Path.Direction.CCW)
  }

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    super.onLayout(changed, left, top, right, bottom)

    // --- 3. Cập nhật vị trí và kích thước cho label ---
    val label = instructionLabel
    if (label.visibility == GONE) return

    // Đo kích thước label để nó tự co giãn theo nội dung
    label.measure(
      MeasureSpec.makeMeasureSpec(width - (40 * resources.displayMetrics.density).toInt(), MeasureSpec.AT_MOST),
      MeasureSpec.makeMeasureSpec(height, MeasureSpec.AT_MOST)
    )

    val labelWidth = label.measuredWidth
    val labelHeight = label.measuredHeight
    val labelX = (width / 2f) - (labelWidth / 2f)
    val labelY = areaViewFrame.bottom + (10 * resources.displayMetrics.density) // Cách oval 10dp

    // Đặt vị trí cho label
    label.layout(labelX.toInt(), labelY.toInt(), (labelX + labelWidth).toInt(), (labelY + labelHeight).toInt())

    // Cập nhật lại bo góc sau khi có chiều cao cuối cùng
    (label.background as? GradientDrawable)?.cornerRadius = labelHeight / 2f
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    // Vẽ lớp overlay đen mờ có lỗ
    canvas.drawPath(overlayPath, overlayPaint)
    // Vẽ đường viền trắng cho oval
    canvas.drawOval(areaViewFrame, strokePaint)
  }
}
