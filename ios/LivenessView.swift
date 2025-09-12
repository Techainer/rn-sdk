import Foundation
import React
import UIKit
import LocalAuthentication
import ekyc_ios_sdk

@available(iOS 11.1, *)
class LivenessView: UIView {

    // MARK: - Properties
    private var faceAuth2D: FaceAuthenticationView!
    private var faceAuth3D: FaceAuthentication3DView!
    private var viewMask: LivenessMaskView!
    
    private var cameraStarted = false
    private var currentIsFlash: Bool = false
    private var _isFlashCamera = false
    var isFlashCamera: Bool { _isFlashCamera }

    var requestid = ""
    var appId = ""
    var baseUrl = ""
    var privateKey = ""
    var publicKey = ""
    var secret = "ABCDEFGHIJKLMNOP"
    var debugging = false
    var transactionId = ""

    private let brightnessHelper = BrightnessHelper()
    @objc var onEvent: RCTBubblingEventBlock?

    // MARK: - Setters
    @objc func setRequestid(_ val: NSString) { self.requestid = val as String }
    @objc func setAppId(_ val: NSString) { self.appId = val as String }
    @objc func setBaseUrl(_ val: NSString) { self.baseUrl = val as String }
    @objc func setPrivateKey(_ val: NSString) { self.privateKey = val as String }
    @objc func setPublicKey(_ val: NSString) { self.publicKey = val as String }
    @objc func setDebugging(_ val: Bool) { self.debugging = val }
    @objc func setIsFlashCamera(_ val: Bool) {
        if _isFlashCamera == val { return }
        _isFlashCamera = val
        currentIsFlash = val
        setupCameraImmediate()
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        registerForNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
        registerForNotifications()
    }

    deinit {
        stopAllCameras()
        unregisterFromNotifications()
        brightnessHelper.restoreBrightness()
    }

    // MARK: - Configure
    private func configure() {
        backgroundColor = .clear

        // Mask
        viewMask = LivenessMaskView(frame: bounds)
        viewMask.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewMask.backgroundColor = .clear
        viewMask.layer.zPosition = 1
        viewMask.instructionText = "Hãy đưa mặt vào trong khung hình"
        addSubview(viewMask)

        // Brightness set ngay
        brightnessHelper.getBrightness()
        brightnessHelper.setBrightness(1.0)

        // Khởi tạo camera 2D
        faceAuth2D = FaceAuthenticationView(frame: bounds)
        faceAuth2D.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        faceAuth2D.onResultsLiveness = { [weak self] result in
            self?.handleLiveness(value: result.rawValue)
        }
        faceAuth2D.onResultsExtracted = { [weak self] images, color in
            self?.processImagesAsync(original: images.first, colorOrThermal: images.last, color: color, is3D: false)
        }
        addSubview(faceAuth2D)
        sendSubviewToBack(faceAuth2D)
        faceAuth2D.isHidden = true

        // Khởi tạo camera 3D
        faceAuth3D = FaceAuthentication3DView(frame: bounds)
        faceAuth3D.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        faceAuth3D.onResultsLiveness = { [weak self] result in
            self?.handleLiveness(value: result.rawValue)
        }
        faceAuth3D.onResultsExtracted = { [weak self] images in
            self?.processImagesAsync(original: images.first, colorOrThermal: images.last, color: nil, is3D: true)
        }
        addSubview(faceAuth3D)
        sendSubviewToBack(faceAuth3D)
        faceAuth3D.isHidden = true
      
      if self.checkFaceID() {
        _isFlashCamera = false
      } else {
        _isFlashCamera = true
      }
    }

    // MARK: - Layout / Start camera
    override func layoutSubviews() {
        super.layoutSubviews()

        // Start camera sau khi layout xong, chỉ 1 lần
        if !cameraStarted {
            setupCameraImmediate()
            cameraStarted = true
        }
    }

    private func setupCameraImmediate() {
        stopAllCameras()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isFlashCamera {
                self.faceAuth2D.isHidden = true
                self.faceAuth3D.isHidden = false
                self.faceAuth3D.startCamera()
            } else {
                self.faceAuth3D.isHidden = true
                self.faceAuth2D.isHidden = false
                self.faceAuth2D.startCamera()
            }
            
            self.pushEvent(data: ["isFlash": self.isFlashCamera])
        }
    }

    func checkFaceID() -> Bool {
        let authType = LocalAuthManager.shared.biometricType
        return authType == .faceID
    }

    private func stopAllCameras() {
        faceAuth2D?.stopCamera()
        faceAuth3D?.stopCamera()
    }

    // MARK: - Process images async
    private func processImagesAsync(original: String?, colorOrThermal: String?, color: String?, is3D: Bool) {
        DispatchQueue.global(qos: .utility).async {
            let base64Original = original.flatMap { self.convertImageToBase64UnderMB(filePath: $0) }
            let base64ColorOrThermal = colorOrThermal.flatMap { self.convertImageToBase64UnderMB(filePath: $0) }
            
            var data: [String: Any] = ["livenessOriginalImage": base64Original as Any]
            if is3D {
                data["livenessThermalImage"] = base64ColorOrThermal as Any
            } else {
                data["livenessColorImage"] = base64ColorOrThermal as Any
                data["color"] = color as Any
            }
            
            DispatchQueue.main.async {
                self.pushEvent(data: data)
            }
        }
    }

    // MARK: - App Lifecycle
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func unregisterFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onEnterBackground() { stopAllCameras() }
    @objc private func onEnterForeground() { setupCameraImmediate() }

    // MARK: - Liveness Result
    private func handleLiveness(value: Int) {
        let messages: [Int: String] = [
            0: "Hợp lệ",
            1: "Phát hiện bàn tay, vui lòng không che mặt",
            2: "Phát hiện khẩu trang, vui lòng tháo ra",
            3: "Phát hiện kính, vui lòng tháo ra",
            4: "Khuôn mặt bị che khuất",
            5: "Khuôn mặt bị nghiêng, vui lòng nhìn thẳng",
            6: "Khuôn mặt quá nhỏ, vui lòng đưa lại gần hơn",
            7: "Hãy đưa mặt vào trong khung hình",
            8: "Khuôn mặt bị lóa sáng",
            9: "Môi trường thiếu sáng",
            10: "Vui lòng giữ yên khuôn mặt",
            11: "Hoàn thành",
            12: "Khuôn mặt quá lớn, vui lòng đưa ra xa hơn",
            13: "Hide mark view."
        ]
        
        let text = messages[value] ?? "Hợp lệ"
        
        DispatchQueue.main.async {
            if text == "Hide mark view." {
                self.viewMask.overlayColor = UIColor.clear.cgColor
            } else {
                self.viewMask.instructionText = text
                self.viewMask.overlayColor = UIColor.black.withAlphaComponent(0.4).cgColor
            }
        }
    }

    // MARK: - Helpers
    private func pushEvent(data: Any) {
        onEvent?(["data": data])
    }

    func convertImageToBase64UnderMB(filePath: String, maxSizeInKB: Int = 400) -> String? {
        guard var image = UIImage(contentsOfFile: filePath) else { return nil }
        var compression: CGFloat = 1.0
        var data = image.jpegData(compressionQuality: compression)
        
        while let d = data, d.count > maxSizeInKB * 1024 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
            
            if compression < 0.1 {
                let newSize = CGSize(width: image.size.width * 0.9, height: image.size.height * 0.9)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
                compression = 1.0
                data = image.jpegData(compressionQuality: compression)
            }
        }
        return data?.base64EncodedString(options: .lineLength64Characters)
    }
}
