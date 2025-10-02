import UIKit

class LivenessMaskView: UIView {
    
    // MARK: - UI Elements
    private let instructionLabel = PaddedLabel()
    
    // Overlay
    private let overlayLayer = CAShapeLayer()
    private let ovalStrokeLayer = CAShapeLayer()
    
    // Oval frame
    private(set) var areaViewFrame: CGRect = .zero
    
    // MARK: - Public Properties
    var instructionText: String? {
        didSet {
            instructionLabel.text = instructionText
            instructionLabel.isHidden = instructionText?.isEmpty ?? true
            setNeedsLayout()
        }
    }
    
//    var overlayColor: UIColor = .black.withAlphaComponent(0.4) {
    var overlayColor: UIColor = .white {
        didSet {
            overlayLayer.fillColor = overlayColor.cgColor
            instructionLabel.backgroundColor = overlayColor == .clear ? .clear : UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            ovalStrokeLayer.strokeColor = overlayColor == .clear ? UIColor.clear.cgColor : UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor
        }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        
        // overlay
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = overlayColor.cgColor
        layer.addSublayer(overlayLayer)
        
        // oval stroke
        ovalStrokeLayer.lineWidth = 10
        ovalStrokeLayer.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor // #FFD700
        ovalStrokeLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(ovalStrokeLayer)
        
        // instruction label
        let screenWidth = UIScreen.main.bounds.width
        let fontSize = screenWidth * 0.036
        instructionLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        instructionLabel.textColor = .black
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        
        instructionLabel.textInsets = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        instructionLabel.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // #FFD700
        instructionLabel.layer.cornerRadius = 10
        instructionLabel.layer.masksToBounds = true
        
        addSubview(instructionLabel)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds = self.bounds
        
        // tính oval giống Android
        let ovalWidth = bounds.width * 0.89
        let ovalHeight = ovalWidth * 1.55
        let xPos = (bounds.width - ovalWidth) / 2
        var yPos = (bounds.height - ovalHeight) / 2
        
        // đẩy oval lên một chút
        yPos = max(0, yPos - ovalHeight * 0.03)
        
        areaViewFrame = CGRect(x: xPos, y: yPos, width: ovalWidth, height: ovalHeight)
        
        // path overlay
        let overlayPath = UIBezierPath(rect: bounds)
        overlayPath.append(UIBezierPath(ovalIn: areaViewFrame))
        overlayLayer.path = overlayPath.cgPath
        
        // path stroke
        ovalStrokeLayer.path = UIBezierPath(ovalIn: areaViewFrame).cgPath
        
        // layout label
        updateLabelFrame()
    }
    
    private func updateLabelFrame() {
        guard let text = instructionLabel.text, !text.isEmpty else {
            instructionLabel.isHidden = true
            return
        }
        
        instructionLabel.isHidden = false
        
        let maxWidth = bounds.width * 0.9
        let size = instructionLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        let labelX = (bounds.width - size.width) / 2
        let labelY = areaViewFrame.minY - size.height + 30 // đặt label phía trên oval
        
        instructionLabel.frame = CGRect(x: labelX, y: labelY, width: size.width, height: size.height)
    }
}


// MARK: - PaddedLabel
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
