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
    private var maskStyleValue: FaceAuthenticationView.MaskStyle?

    private var cameraStarted = false
    private var _isFlashCamera = false
    var isFlashCamera: Bool { _isFlashCamera }

    var transactionId = ""

    private let brightnessHelper = BrightnessHelper()
    @objc var onEvent: RCTBubblingEventBlock?
    @objc var isDebug: Bool = false
    @objc var maskStyle: NSDictionary? {
        didSet {
            maskStyleValue = Self.parseMaskStyle(maskStyle)
            applyMaskStyleIfNeeded()
        }
    }

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
            if self?.isDebug == true {
                for image in images {
                  if let img = UIImage(contentsOfFile: image) {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                  }
                }
            }
            self?.processImagesAsync(original: images.first, colorOrThermal: images.last, color: color, is3D: false)
        }
        addSubview(faceAuth2D)
        sendSubviewToBack(faceAuth2D)
        faceAuth2D.isHidden = true
        applyMaskStyleIfNeeded()

        // Khởi tạo camera 3D
        if self.checkFaceID() {
          faceAuth3D = FaceAuthentication3DView(frame: bounds)
          faceAuth3D.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          faceAuth3D.onResultsLiveness = { [weak self] result in
              self?.handleLiveness(value: result.rawValue)
          }
          faceAuth3D.onResultsExtracted = { [weak self] images in
              if self?.isDebug == true {
                  for image in images {
                      if let img = UIImage(contentsOfFile: image) {
                          UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                      }
                  }
              }
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
            let base64Original = original.flatMap { self.resizeAndCompressImageToBase64(filePath: $0) }
            let base64ColorOrThermal = colorOrThermal.flatMap { self.resizeAndCompressImageToBase64(filePath: $0) }

            var data: [String: Any] = ["livenessOriginalImage": base64Original as Any]
            if is3D {
                data["livenessThermalImage"] = base64ColorOrThermal as Any
                data["color"] = "t3"
            } else {
                data["livenessColorImage"] = base64ColorOrThermal as Any
              data["color"] = "\(color ?? "")3"
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
    private func applyMaskStyleIfNeeded() {
        guard let maskStyleValue, let faceAuth2D else { return }
        faceAuth2D.setMaskStyle(maskStyleValue)
    }

    private static func parseMaskStyle(_ value: NSDictionary?) -> FaceAuthenticationView.MaskStyle? {
        guard let value else { return nil }

        guard
            let maskBackgroundColorHex = value["maskBackgroundColorHex"] as? String,
            let ovalStrokeColorHex = value["ovalStrokeColorHex"] as? String,
            let textBackgroundColorHex = value["textBackgroundColorHex"] as? String,
            let textColorHex = value["textColorHex"] as? String
        else {
            return nil
        }

        return FaceAuthenticationView.MaskStyle.of(
            maskBackgroundColorHex,
            ovalStrokeColorHex,
            textBackgroundColorHex,
            textColorHex,
            parseInstructionMessageMap(value["instructionMessageMap"])
        )
    }

    private static func parseInstructionMessageMap(_ value: Any?) -> [Int: String]? {
        guard let rawMap = value as? [AnyHashable: Any] else { return nil }

        var result: [Int: String] = [:]
        for (key, message) in rawMap {
            let intKey: Int?
            if let numberKey = key as? NSNumber {
                intKey = numberKey.intValue
            } else if let stringKey = key as? String {
                intKey = Int(stringKey)
            } else {
                intKey = nil
            }

            guard let intKey, let stringMessage = message as? String else { continue }
            result[intKey] = stringMessage
        }

        return result.isEmpty ? nil : result
    }

    private func pushEvent(data: Any) {
        onEvent?(["data": data])
    }

    func resizeAndCompressImageToBase64(filePath: String, maxSize: CGFloat = 1024, compression: Int = 95) -> String? {
        guard let image = UIImage(contentsOfFile: filePath) else { return nil }

        let currentSize = image.size
        let longestSide = max(currentSize.width, currentSize.height)

        let finalImage: UIImage
        // 1. Resize ảnh giữ đúng tỷ lệ (xử lý triệt để vụ lẻ pixel và scale Retina)
        if longestSide > maxSize {
            let scale = maxSize / longestSide
            let newSize = CGSize(width: (currentSize.width * scale).rounded(),
                                height: (currentSize.height * scale).rounded())

            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1.0 

            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            finalImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            finalImage = image
        }

        // 2. Nén đúng 1 lần duy nhất theo chất lượng truyền vào
        let compressQuality = CGFloat(compression) / 100.0
        let imageData = finalImage.jpegData(compressionQuality: compressQuality)

        // 3. Trả về chuỗi Base64 liền mạch, an toàn cho API
        return imageData?.base64EncodedString(options: [])
    }
}
