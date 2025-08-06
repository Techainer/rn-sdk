class LivenessMaskView: UIView {
    var textLayer: CATextLayer?
    var instructionText: String? {
        didSet {
            if oldValue != self.instructionText {
                self.textLayer?.string = self.instructionText
//                    self.textLayer?.frame = self.bounds
                self.updateTextLayerLayout(text: self.instructionText ?? "")
                    self.setNeedsLayout()
            }
        }
    }
    var areaViewFrame: CGRect = .zero
    
    override func draw(_ rect: CGRect) {
        self.layer.sublayers?.forEach({ (l) in
            l.removeFromSuperlayer()
        })
        
        let width: CGFloat = rect.width * 0.93
        let height = min(width * 1.7, rect.height * 0.85)
        let xPos = rect.width / 20
        let yPos = rect.height / 8
        
        let areaViewFrame = CGRect(x: xPos, y: yPos, width: width, height: height)
        let areaViewPath = self.drawAreaViewPath(areaViewFrame)
        
        let path = UIBezierPath(rect: rect)
        path.append(areaViewPath.reversing())
        let color = UIColor.black.withAlphaComponent(0.3)
        color.setFill()
        path.fill()
        path.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        
        self.layer.mask = shapeLayer
        self.areaViewFrame = areaViewFrame
        
        self.textLayer = self.drawTextLayer(withText: self.instructionText ?? "Hãy đưa khuôn mặt vào khung hình", rect: CGRect(x: 13.0, y: yPos - 40, width: rect.width, height: 30))
        self.layer.addSublayer(self.textLayer!)
        self.textLayer?.isHidden = true
    }
    
    func updateTextLayerLayout(text: String) {
        guard !text.isEmpty else {
            self.textLayer?.isHidden = true
            return
        }
        self.textLayer?.isHidden = false
        guard let textLayer = self.textLayer else {
            self.textLayer = self.drawTextLayer(withText: text, rect: CGRect(x: 13.0, y: self.areaViewFrame.origin.y - 40, width: self.areaViewFrame.width, height: 30))
            self.layer.addSublayer(self.textLayer!)
            return
        }
        // Calculate the size of the text
        let textSize = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: textLayer.fontSize)])
        
        // Update the background layer's frame
        let padding: CGFloat = 10
        
        // Update the text layer's frame
        let rect = self.bounds
        let textLayerWidth = textSize.width + (padding * 2)
        textLayer.frame = CGRect(
            x: rect.width / 2 - textLayerWidth / 2,
            y: textLayer.frame.origin.y,
            width: textLayerWidth,
            height: textSize.height + (padding / 2)
        )
        
        // Center the text
        textLayer.alignmentMode = .center
    }
    
    func drawAreaViewPath(_ rect: CGRect) -> UIBezierPath {
        let areaViewPath = UIBezierPath(ovalIn: rect)
        areaViewPath.lineWidth = 0.5
        UIColor.white.setStroke()
        areaViewPath.stroke()
        areaViewPath.close()
        return areaViewPath
    }
    
    func drawTextLayer(withText text: String, rect: CGRect) -> CATextLayer {
        let textlayer = CATextLayer()
        let sizeOfText = (text as NSString).boundingRect(with: rect.size, context: nil)
        textlayer.frame = CGRect(origin: CGPoint(x: rect.width / 2 - sizeOfText.width / 2 - 15, y: rect.origin.y), size: CGSize(width: sizeOfText.width + 30, height: sizeOfText.height + 8))
        textlayer.fontSize = 14
        textlayer.alignmentMode = .center
        textlayer.string = text
        textlayer.isWrapped = true
        textlayer.truncationMode = .end
        textlayer.foregroundColor = UIColor.white.cgColor
        textlayer.contentsScale = UIScreen.main.scale
        textlayer.backgroundColor = UIColor.black.cgColor
        return textlayer
    }
}
