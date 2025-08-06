import Foundation
import React
import UIKit
import LocalAuthentication
import QTSLiveness
import ekyc_ios_sdk

@available(iOS 13.4, *)
class LivenessView: UIView, QTSLiveness.QTSLivenessUtilityDetectorDelegate {
  var mainView: FaceAuthenticationView?
  private var currentIsFlash: Bool = false
  private var enableNewCamera: Bool = false
  var transactionId = ""
  var livenessDetector: Any?
  private var viewMask: LivenessMaskView!
  var requestid = ""
  var appId = ""
  var baseUrl = ""
  var privateKey = ""
  var publicKey = ""
  var secret = "ABCDEFGHIJKLMNOP"
  var debugging = false
  var isFlashCamera = false
  var isDoneSmile = false
    private var originalBrightness: CGFloat?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let viewMask = viewMask {
            viewMask.frame = self.bounds // Ensure viewMask covers the entire view
        } // Ensure viewMask covers the entire view
    }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
//   setupView()
      configution()
      registerForNotifications()
  }
 
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//   setupView()
      configution()
      registerForNotifications()
  }
    
    func configution() {
        self.backgroundColor = .clear
        if UIScreen.main.brightness == 1 {
            self.originalBrightness = 0.35
        } else {
            self.originalBrightness = UIScreen.main.brightness
        }
    }
    
    deinit {
        revertLightScreen()
        print("Dispose Liveness")
        resetLivenessDetector()
        unregisterFromNotifications()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
//            upLightScreen()
            print("LivenessView đã được thêm vào màn hình.")
            // Thực hiện các tác vụ cần thiết
        } else {
            revertLightScreen()
            print("LivenessView đã bị xoá khỏi màn hình.")
            resetLivenessDetector()
        }
    }
    
//    override func didMoveToWindow() {
//        super.didMoveToWindow()
//        if window != nil {
////            upLightScreen()
//            print("LivenessView đã xuất hiện trong window.")
//            // Thực hiện các tác vụ liên quan đến giao diện.
//        } else {
//            revertLightScreen()
//            print("LivenessView đã bị xóa khỏi window.")
//            resetLivenessDetector()
//        }
//    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func unregisterFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func onEnterBackground() {
        // Handle entering background
        print("App entered background")
       revertLightScreen()
    }

    @objc private func onEnterForeground() {
        // Handle entering foreground
        print("App entered foreground")
       upLightScreen()
    }
    
    func upLightScreen() {
        revertLightScreen()
        
        // Lưu độ sáng ban đầu nếu chưa lưu
//        if self.originalBrightness == nil {
//            self.originalBrightness = UIScreen.main.brightness
//        }

        // Tăng độ sáng lên mức tối đa
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIScreen.main.brightness = 1.0
        }
    }
    
    func revertLightScreen() {
        // Khôi phục độ sáng ban đầu nếu đã được lưu
        if let brightness = self.originalBrightness {
            UIScreen.main.brightness = brightness
//            self.originalBrightness = nil
        }
        
//        UIScreen.main.brightness = 0.35
        print("Brightness revert to")
    }
    
    func checkfaceID() -> Bool {
      let authType = LocalAuthManager.shared.biometricType
      switch authType {
      case .faceID:
        return true
      default:
        return false
      }
    }
    
      private func setupConfig() {
          upLightScreen()
          resetLivenessDetector()
          setupView()
      }
    
    private func resetLivenessDetector() {
        if !isFlashCamera && checkfaceID(), #available(iOS 15.0, *) {
          (livenessDetector as? QTSLiveness.QTSLivenessDetector)?.stopLiveness() // Stop the session for QTSLiveness
          print("QTSLiveness detector stopped and reset.")
        } else {
          mainView?.stopCamera()
        }
        
        livenessDetector = nil
        mainView?.removeFromSuperview()
        mainView = nil
        removeFromSuperview()
    }

 
  private func setupView() {
      do {
          let dataRes: [String: Any]
          if !isFlashCamera && checkfaceID(), #available(iOS 15.0, *) {
              self.livenessDetector = QTSLiveness.QTSLivenessDetector.createLivenessDetector(
                  previewView: self,
                  threshold: .low,
                  smallFaceThreshold: 0.25,
                  debugging: debugging,
                  delegate: self,
                  livenessMode: .local,
                  localLivenessThreshold: {
                    if #available(iOS 18.0, *) {
                         return 0.97
                    } else {
                        return 0.97
                    }
                }(),
                  calculationMode: .combine,
                  additionHeader: ["header": "header"]
              )
            //   viewMask = LivenessMaskView(frame: bounds)
            //   viewMask.backgroundColor = UIColor.clear
            //   viewMask.layer.zPosition = 1 // Bring viewMask to the top layer
            //   addSubview(viewMask)
            dataRes = [ "isFlash": false ]
            pushEvent(data: dataRes)
            try startSession()
          } else {
              mainView = FaceAuthenticationView(frame: bounds)
              mainView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
              addSubview(mainView!)
              dataRes = [ "isFlash": true ]
              pushEvent(data: dataRes)
          
               viewMask = LivenessMaskView(frame: bounds)
               viewMask.backgroundColor = UIColor.clear
               viewMask.layer.zPosition = 1
               viewMask.instructionText = "Hãy đưa mặt vào trong khung hình"
               addSubview(viewMask)
            
              handleResultsLiveness()
              handleResultsExtracted()
          }
        } catch {
            pushEvent(data: ["error": error.localizedDescription])
        }
  }
  
  func handleResultsLiveness() {
          guard let mainView = self.mainView else {
              print("Error: mainView is nil")
              return
          }
          print("mainView type: \(type(of: mainView))")
          let handleLivenessResult: (Int) -> [String: Any] = { rawValue in
              var result: [String: Any] = [:]
              switch rawValue {
              case 0:
                  result["result"] = "Hợp lệ"
              case 1:
                  result["result"] = "Phát hiện bàn tay, vui lòng không che mặt"
              case 2:
                  result["result"] = "Phát hiện khẩu trang, vui lòng tháo ra"
              case 3:
                  result["result"] = "Phát hiện kính, vui lòng tháo ra"
              case 4:
                  result["result"] = "Khuôn mặt bị che khuất"
              case 5:
                  result["result"] = "Khuôn mặt bị nghiêng, vui lòng nhìn thẳng"
              case 6:
                  result["result"] = "Khuôn mặt quá nhỏ, vui lòng đưa lại gần hơn"
              case 7:
                  result["result"] = "Hãy đưa mặt vào trong khung hình"
              case 8:
                  result["result"] = "Khuôn mặt bị lóa sáng"
              case 9:
                  result["result"] = "Môi trường thiếu sáng"
              case 10:
                  result["result"] = "Vui lòng giữ yên khuôn mặt"
              case 11:
                  result["result"] = "Hoàn thành"
              case 12:
                  result["result"] = "Khuôn mặt quá lớn, vui lòng đưa ra xa hơn"
              case 13:
                  result["result"] = "Hide mark view."
              default:
                  result["result"] = "Hợp lệ"
              }
              return result
          }

          if let faceAuthView = mainView as? FaceAuthenticationView {
              print("IsFlash: FaceAuthenticationView")
              faceAuthView.onResultsLiveness = { [weak self] livenessResult in
                let result = handleLivenessResult(livenessResult.rawValue)
                let newText = result["result"] as? String

                print("Liveness result received: \(newText ?? "nil")")
                
                if newText != "Hide mark view." {
                  DispatchQueue.main.async {
                      // Hiển thị text hướng dẫn
                      self?.viewMask.instructionText = newText
                      // Khôi phục lại màu đen mờ mặc định cho overlay
                      self?.viewMask.overlayColor = UIColor.black.withAlphaComponent(0.4).cgColor
                  }
                } else {
                  DispatchQueue.main.async {
                      // Ẩn text đi
                      self?.viewMask.instructionText = ""
                      // Làm cho overlay hoàn toàn trong suốt
                      // Dùng UIColor.clear.cgColor sẽ rõ ràng hơn
                      self?.viewMask.overlayColor = UIColor.clear.cgColor
                  }
                }
              }
          }
      }

      func handleResultsExtracted() {
          guard let mainView = self.mainView else {
              print("Error: mainView is nil")
              return
          }
          print("mainView type: \(type(of: mainView))")
          if mainView is FaceAuthenticationView {
              print("IsFlash: FaceAuthenticationView")
              (mainView as! FaceAuthenticationView).onResultsExtracted = {
                  [weak self] images, colorString in
                  var result: [String: Any] = [:]
                  result["livenessOriginalImage"] = self?.convertImageToBase64UnderMB(
                      filePath: images.first ?? "")
                  if self?.enableNewCamera == true {
                      result["livenessImage"] = self?.convertImageToBase64UnderMB(
                          filePath: images.last ?? "")
                      result["color"] = colorString
                  }
                self?.pushEvent(data: result)
              }
          }
      }
  
  func convertImageToBase64UnderMB(filePath: String, maxSizeInKB: Int = 400) -> String? {
      do {
          // 1. Load the image from the file path
          guard let image = UIImage(contentsOfFile: filePath) else {
              throw NSError(
                  domain: "Invalid Image", code: 1,
                  userInfo: [NSLocalizedDescriptionKey: "Image not found at path: \(filePath)"])
          }

          var resizedImage = image
          var compressionQuality: CGFloat = 1.0
          var imageData: Data?

          repeat {
              // 2. Compress the image
              imageData = resizedImage.jpegData(compressionQuality: compressionQuality)

              // 3. Check size and resize if needed
              if let data = imageData, data.count > maxSizeInKB * 1024 {
                  // Reduce compression quality
                  compressionQuality -= 0.1

                  // Resize the image dimensions if quality is too low
                  if compressionQuality < 0.1 {
                      let newWidth = resizedImage.size.width * 0.9
                      let newHeight = resizedImage.size.height * 0.9
                      resizedImage = resizeImage(
                          image: resizedImage, width: newWidth, height: newHeight)
                      compressionQuality = 1.0  // Reset quality after resizing
                  }
              } else {
                  break
              }
          } while imageData == nil || (imageData!.count > maxSizeInKB * 1024)

          // 4. Convert the image data to Base64
          guard let finalData = imageData else {
              throw NSError(
                  domain: "Image Conversion Failed", code: 2,
                  userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
          }

          return finalData.base64EncodedString(options: .lineLength64Characters)

      } catch let error {
          print("Error: \(error.localizedDescription)")
          return nil
      }
  }

  // Helper function to resize an image
  func resizeImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
      let newSize = CGSize(width: width, height: height)
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: CGRect(origin: .zero, size: newSize))
      let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return resizedImage ?? image
  }

  private func startSession() throws {
      guard let detector = livenessDetector else {
          throw NSError(domain: "LivenessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Liveness Detector could not be initialized"])
      }
  
      if #available(iOS 15.0, *), let qtDetector = detector as? QTSLiveness.QTSLivenessDetector {
          try qtDetector.getVerificationRequiresAndStartSession(transactionId: self.transactionId)
      }
  }
  
  private func pushEvent(data: Any) -> Void {
    if (self.onEvent != nil) {
      let event = ["data": data]
      self.onEvent!(event)
    }
  }
  
  @objc var onEvent: RCTBubblingEventBlock?
  
  @objc func setRequestid(_ val: NSString) {
      print("9999")
    self.requestid = val as String
//    self.setupConfig()
  }
    
  @objc func setAppId(_ val: NSString) {
      print("9999")
    self.appId = val as String
//    self.setupConfig()
  }
    
  @objc func setBaseUrl(_ val: NSString) {
      print("9999")
    self.baseUrl = val as String
//    self.setupConfig()
  }
    
  @objc func setPrivateKey(_ val: NSString) {
      print("9999")
    self.privateKey = val as String
//    self.setupConfig()
  }
    
  @objc func setPublicKey(_ val: NSString) {
      print("9999")
    self.publicKey = val as String
//    self.setupConfig()
  }
  
  @objc func setDebugging(_ val: Bool) {
      print("9999")
    self.debugging = val as Bool
  }
    
  @objc func setIsFlashCamera(_ val: Bool) {
        print("9999")
    
        if currentIsFlash == val && mainView != nil {
            return
        }

        // Cập nhật trạng thái mới
        self.isFlashCamera = val as Bool
        currentIsFlash = isFlashCamera
        self.setupConfig()
  }
    
    @available(iOS 15.0, *)
    func liveness(liveness: QTSLivenessDetector, didFail withError: QTSLivenessError) {
      print(withError)
    }
    
    @available(iOS 15.0, *)
    func liveness(liveness: QTSLiveness.QTSLivenessDetector, didFinishLocalLiveness score: Float, maxtrix: [Float], image: UIImage, thermal_image: UIImage, videoURL: URL?){
//        let livenessImage = saveImageToFile(image: image, isOriginal: false) ?? ""
      let livenessImage = resizeUIImageToBase64(image: thermal_image) ?? ""
      let livenessOriginalImage = resizeUIImageToBase64(image: image) ?? ""
       let dataRes: [String: Any] = [
            "livenessThermalImage": livenessImage,
             "livenessOriginalImage": livenessOriginalImage,
             "vector": maxtrix,
       ]
        pushEvent(data: dataRes)
        print(dataRes)
        liveness.stopLiveness()
    }
    
    func saveImageToFile(image: UIImage, isOriginal: Bool) -> String? {
        // Chuyển đổi UIImage thành Data (PNG format)
        guard let imageData = image.pngData() else {
            print("Không thể chuyển đổi ảnh thành dữ liệu PNG")
            return nil
        }

        // Lấy đường dẫn thư mục tạm thời (temporary directory)
        let tempDirectory = FileManager.default.temporaryDirectory
        // Tạo tên file với phần mở rộng .png
        let fileName = "face_authentications\(isOriginal ? "_original" : "")" + ".png"
        // Tạo đường dẫn đầy đủ cho file
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            // Lưu dữ liệu PNG vào file
            try imageData.write(to: fileURL)
            print("Đã lưu file tại: \(fileURL.path)")
            // Trả về đường dẫn của file
            return fileURL.path
        } catch {
            print("Không thể lưu ảnh: \(error.localizedDescription)")
            return nil
        }
    }

    func convertImageToBase64(_ image: UIImage) -> String? {
        // Convert UIImage to Data in JPEG format with optional compression quality
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        // Convert the Data to a Base64 encoded string
        let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
        print("convert done")
        return base64String
    }
  
  func resizeUIImageToBase64(image: UIImage, limitSizeInKB: Int = 500) -> String? {
      var compressionQuality: CGFloat = 1.0
      var compressedData: Data? = image.jpegData(compressionQuality: compressionQuality)
      
      // Reduce quality gradually until below limit
      while let data = compressedData, data.count > limitSizeInKB * 1024, compressionQuality > 0.1 {
          compressionQuality -= 0.05
          compressedData = image.jpegData(compressionQuality: compressionQuality)
      }
      
      // Resize only if still above limit
      var resizedImage = image
      while let data = compressedData, data.count > limitSizeInKB * 1024 {
          let newWidth = Int(resizedImage.size.width * 0.9) // Reduce by 10%
          let newHeight = Int(resizedImage.size.height * 0.9)
          if let newImage = resizeImage(image: resizedImage, width: newWidth, height: newHeight) {
              resizedImage = newImage
              compressionQuality = 1.0 // Reset quality
              compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
          } else {
              break
          }
      }
      
      guard let finalData = compressedData else { return nil }
      return finalData.base64EncodedString()
  }
  
  func resizeBase64Image(base64String: String, limitSizeInKB: Int = 500) -> String? {
      guard let imageData = Data(base64Encoded: base64String), let image = UIImage(data: imageData) else {
          print("Invalid Base64 string")
          return nil
      }
      
      if imageData.count <= limitSizeInKB * 1024 {
          return base64String // Return original if within limit
      }
      
      var compressionQuality: CGFloat = 1.0
      var compressedData: Data? = image.jpegData(compressionQuality: compressionQuality)
      
      // Reduce quality gradually until below limit
      while let data = compressedData, data.count > limitSizeInKB * 1024, compressionQuality > 0.1 {
          compressionQuality -= 0.05
          compressedData = image.jpegData(compressionQuality: compressionQuality)
      }
      
      // Resize only if still above limit
      var resizedImage = image
      while let data = compressedData, data.count > limitSizeInKB * 1024 {
          let newWidth = Int(resizedImage.size.width * 0.9) // Reduce by 10%
          let newHeight = Int(resizedImage.size.height * 0.9)
          if let newImage = resizeImage(image: resizedImage, width: newWidth, height: newHeight) {
              resizedImage = newImage
              compressionQuality = 1.0 // Reset quality
              compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
          } else {
              break
          }
      }
      
      guard let finalData = compressedData else { return nil }
      return finalData.base64EncodedString()
  }

  func resizeImage(image: UIImage, width: Int, height: Int) -> UIImage? {
      let size = CGSize(width: width, height: height)
      UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
      image.draw(in: CGRect(origin: .zero, size: size))
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return newImage
  }


  func stopLiveness() {
      (livenessDetector as AnyObject).stopLiveness()
  }
    
  var faceIDAvailable: Bool {
    if #available(iOS 11.0, *) {
      let context = LAContext()
      return (context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil) && context.biometryType == .faceID)
    }
    return false
  }
}

extension UIColor {
    func toHexDouble(includeAlpha: Bool = false) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int
        if includeAlpha {
            rgb = (Int(red * 255) << 24) | (Int(green * 255) << 16) | (Int(blue * 255) << 8) | Int(alpha * 255)
        } else {
            rgb = (Int(red * 255) << 16) | (Int(green * 255) << 8) | Int(blue * 255)
        }

        return Double(rgb)
    }
}

