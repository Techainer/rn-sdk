import Foundation
import React
import UIKit
import LocalAuthentication
internal import ekyc_ios_sdk

@available(iOS 11.1, *)
class LivenessView: UIView {

    // MARK: - Properties
    private var faceAuth2D: FaceAuthenticationView!
    private var faceAuth3D: FaceAuthentication3DView!
    
    private var cameraStarted = false
    private var _isFlashCamera = false
    var isFlashCamera: Bool { _isFlashCamera }

    var transactionId = ""

    private let brightnessHelper = BrightnessHelper()
    @objc var onEvent: RCTBubblingEventBlock?

    // MARK: - Setters
    @objc func setIsFlashCamera(_ val: Bool) {
        if _isFlashCamera == val { return }
        _isFlashCamera = val
        initSetupCamera()
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
      dispose()
    }
    
    private func dispose() {
      stopAllCameras()
      unregisterFromNotifications()
      brightnessHelper.setBrightness(0.3)
    }
  
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            print("FaceAuthenticationView đã được thêm vào màn hình.")
        } else {
            print("FaceAuthenticationView đã bị xoá khỏi màn hình.")
            dispose()
        }
    }

    // MARK: - Configure
    private func configure() {
        backgroundColor = .clear

        // Brightness set ngay
        brightnessHelper.getBrightness()

        // Khởi tạo camera 2D
        faceAuth2D = FaceAuthenticationView(frame: bounds)
        faceAuth2D.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //  faceAuth2D.setLogin(false)
        faceAuth2D.onResultsLiveness = { [weak self] result in
            self?.handleLiveness(value: result.rawValue)
        }
        faceAuth2D.onResultsExtracted = { [weak self] images, color in
        //    for image in images {
        //      if let img = UIImage(contentsOfFile: image) {
        //        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        //      }
        //    }
            self?.processImagesAsync(original: images.first, colorOrThermal: images.last, color: color, is3D: false)
        }
        addSubview(faceAuth2D)
        sendSubviewToBack(faceAuth2D)
        faceAuth2D.isHidden = true

        // Khởi tạo camera 3D
        if self.checkFaceID() {
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
        }
    }

    // MARK: - Layout / Start camera
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            initSetupCamera()
        }
    }

    func initSetupCamera() {
//      guard !cameraStarted else { return }
//      cameraStarted = true
      setupCameraImmediate()
    }

    private func setupCameraImmediate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !_isFlashCamera && self.checkFaceID() {
                self.faceAuth2D.isHidden = true
                self.faceAuth3D.isHidden = false
                self.brightnessHelper.setBrightness(1.0)
                self.faceAuth3D.startCamera()
                self.pushEvent(data: ["isFlash": false])
            } else {
                if self.checkFaceID() {
                  self.faceAuth3D.isHidden = true
                  self.faceAuth3D.stopCamera()
                  self.faceAuth3D.removeFromSuperview()
                }
                self.faceAuth2D.isHidden = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                    self.brightnessHelper.setBrightness(1.0)
//                }
                self.brightnessHelper.setBrightness(1.0)
                self.faceAuth2D.startCamera()
                self.pushEvent(data: ["isFlash": true])
            }
        }
    }

    func checkFaceID() -> Bool {
        let authType = LocalAuthManager.shared.biometricType
        return authType == .faceID
    }

    private func stopAllCameras() {
        faceAuth2D?.stopCamera()
        faceAuth3D?.stopCamera()
        faceAuth2D?.removeFromSuperview()
        faceAuth3D?.removeFromSuperview()
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
    @objc private func onEnterForeground() { initSetupCamera() }

    // MARK: - Liveness Result
    private func handleLiveness(value: Int) {}

    // MARK: - Helpers
    private func pushEvent(data: Any) {
        onEvent?(["data": data])
    }

    func convertImageToBase64UnderMB(filePath: String, maxSizeInKB: Int = 300) -> String? {
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
