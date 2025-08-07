import UIKit

class LivenessMaskView: UIView {

    // MARK: - UI Elements
    // Sử dụng PaddedLabel tùy chỉnh để giải quyết vấn đề padding
    private let instructionLabel = PaddedLabel()

    // Các layer để vẽ giao diện
    private let overlayLayer = CAShapeLayer()
    private let ovalStrokeLayer = CAShapeLayer() // Giữ lại để có thể bật/tắt viền trắng

    // MARK: - Public Properties
    var instructionText: String? {
        didSet {
            // Khi text thay đổi, cập nhật nội dung của label
            // và yêu cầu hệ thống tính toán lại layout
            self.instructionLabel.text = self.instructionText
            self.setNeedsLayout()
        }
    }

    var overlayColor: CGColor? = UIColor.black.withAlphaComponent(0.4).cgColor {
        didSet {
            // Cập nhật trực tiếp màu của layer.
            // Việc này hiệu quả hơn nhiều so với việc gọi setNeedsLayout().
            self.overlayLayer.fillColor = overlayColor
        }
    }

    private(set) var areaViewFrame: CGRect = .zero

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let viewBounds = self.bounds

        // 1. Tính toán frame cho vùng oval
        let width: CGFloat = viewBounds.width * 0.93
        let height = min(width * 1.7, viewBounds.height * 0.85)
        let xPos = (viewBounds.width - width) / 2
        let yPos = viewBounds.height / 8
        self.areaViewFrame = CGRect(x: xPos, y: yPos, width: width, height: height)

        // 2. Cập nhật path (đường vẽ) cho các shape layer
        let overlayPath = UIBezierPath(rect: viewBounds)
        let ovalPath = UIBezierPath(ovalIn: self.areaViewFrame)
        overlayPath.append(ovalPath)
        overlayLayer.path = overlayPath.cgPath

        // Cập nhật path cho viền trắng (nếu được sử dụng)
        ovalStrokeLayer.path = ovalPath.cgPath

        // 3. Cập nhật frame cho label hướng dẫn
        updateLabelFrame()
    }

    // MARK: - Private Methods
    private func setupViews() {
        self.backgroundColor = .clear
        // Cấu hình lớp nền đen mờ
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = self.overlayColor
        self.layer.addSublayer(overlayLayer)

        // Cấu hình lớp vẽ viền trắng cho oval
//        ovalStrokeLayer.lineWidth = 2.0
//        ovalStrokeLayer.strokeColor = UIColor.white.cgColor
//        ovalStrokeLayer.fillColor = UIColor.clear.cgColor
        // Bỏ comment dòng dưới nếu bạn muốn hiện lại viền trắng
        // self.layer.addSublayer(ovalStrokeLayer)

        // Cấu hình PaddedLabel
        let fontSize: CGFloat = 14.0
        instructionLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Thiết lập padding cho label
        instructionLabel.textInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        // Thêm label vào view
        self.addSubview(instructionLabel)
    }

    private func updateLabelFrame() {
        guard let text = self.instructionLabel.text, !text.isEmpty else {
            self.instructionLabel.isHidden = true
            return
        }
        self.instructionLabel.isHidden = false

        // Lấy kích thước chính xác từ PaddedLabel (đã bao gồm padding)
        let labelSize = instructionLabel.intrinsicContentSize

        let labelX = self.bounds.width / 2 - labelSize.width / 2
        let labelY = self.areaViewFrame.maxY + 10

        self.instructionLabel.frame = CGRect(origin: CGPoint(x: labelX, y: labelY), size: labelSize)

        // Bo tròn góc cho label
        self.instructionLabel.layer.cornerRadius = labelSize.height / 2
        self.instructionLabel.layer.masksToBounds = true
    }
}


// MARK: - PaddedLabel Helper Class

/// Một UILabel tùy chỉnh có khả năng xử lý padding (khoảng đệm).
class PaddedLabel: UILabel {

    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fittingSize = super.sizeThatFits(size)
        return CGSize(width: fittingSize.width + textInsets.left + textInsets.right,
                      height: fittingSize.height + textInsets.top + textInsets.bottom)
    }
}
