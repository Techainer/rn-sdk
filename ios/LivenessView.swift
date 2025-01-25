import Foundation
import React
import UIKit
import LocalAuthentication
import FlashLiveness
import QTSLiveness
import LocalAuthentication

@available(iOS 13.0, *)
class LivenessView: UIView, FlashLiveness.LivenessUtilityDetectorDelegate, QTSLiveness.QTSLivenessUtilityDetectorDelegate {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let viewMask = viewMask {
            viewMask.frame = self.bounds // Ensure viewMask covers the entire view
        } // Ensure viewMask covers the entire view
    }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
//   setupView()
  }
 
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//   setupView()
  }
    
    deinit {
        print("Dispose Liveness")
        resetLivenessDetector()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            print("LivenessView đã được thêm vào màn hình.")
            // Thực hiện các tác vụ cần thiết
        } else {
            print("LivenessView đã bị xoá khỏi màn hình.")
            resetLivenessDetector()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            print("LivenessView đã xuất hiện trong window.")
            // Thực hiện các tác vụ liên quan đến giao diện.
        } else {
            print("LivenessView đã bị xóa khỏi window.")
            resetLivenessDetector()
        }
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
          resetLivenessDetector()
          setupView()
      }
    
    private func resetLivenessDetector() {
        removeFromSuperview()
        if let detector = livenessDetector as? FlashLiveness.LivenessUtilityDetector {
            // Reset specific configurations or data for FlashLiveness if needed
            detector.stopLiveness() // Stop the session for FlashLiveness
            print("FlashLiveness detector stopped and reset.")
        } else if let detector = livenessDetector as? QTSLiveness.QTSLivenessDetector {
                // Reset specific configurations or data for QTSLiveness if needed
                detector.stopLiveness() // Stop the session for QTSLiveness
                print("QTSLiveness detector stopped and reset.")
            }
        
        livenessDetector = nil // Set to nil to allow reinitialization
    }

 
  private func setupView() {
      do {
          if !isFlashCamera && checkfaceID(), #available(iOS 13.0, *) {
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
          } else {
              self.livenessDetector = FlashLiveness.LivenessUtil.createLivenessDetector(
                  previewView: self,
                  mode: .offline,
                  threshold: .low,
                  debugging: debugging,
                  delegate: self
              )
          }
//                  self.livenessDetector = FlashLiveness.LivenessUtil.createLivenessDetector(
//                      previewView: self,
//                      mode: .offline,
//                      threshold: .low,
//                      debugging: debugging,
//                      delegate: self
//                  )
                  // Starting the session only if livenessDetector was successfully created
                  try startSession()
                  
              } catch {
                  pushEvent(data: ["error": error.localizedDescription])
              }
  }

    private func startSession() throws {
            guard let detector = livenessDetector else {
                throw NSError(domain: "LivenessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Liveness Detector could not be initialized"])
            }
            
//            try (detector as? FlashLiveness.LivenessUtilityDetector)?.getVerificationRequiresAndStartSession(transactionId: self.transactionId)
        
            if let flashDetector = detector as? FlashLiveness.LivenessUtilityDetector {
                try flashDetector.getVerificationRequiresAndStartSession(transactionId: self.transactionId)
            } else if let qtDetector = detector as? QTSLiveness.QTSLivenessDetector {
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
        self.isFlashCamera = val as Bool
        self.setupConfig()
  }
  
    private func liveness(liveness: FlashLiveness.LivenessUtilityDetector, didFail withError: FlashLiveness.LivenessError) {
//    pushEvent(data: withError)
  }
  
    func liveness(_ liveness: FlashLiveness.LivenessUtilityDetector, didFinishWithResult result:  FlashLiveness.LivenessResult) {
        let dataRes: [String: Any] = ["message": result.mess, "result": result, "code": result.code, "livenesScore": result.livenesScore, "status": result.status]
        pushEvent(data: dataRes)
    }
    
    func liveness(_ liveness: FlashLiveness.LivenessUtilityDetector, didFinishWithFaceImages images: FlashLiveness.LivenessFaceImages) {
//        let livenessImage = images.images?.first?.imagePath?.absoluteString
//        let livenessOriginalImage = images.originalImage.imagePath?.absoluteString
        let livenessImage = images.images?.first?.imageBase64
        let livenessOriginalImage = images.originalImage.imageBase64
        let dataRes: [String: Any] = [
            "livenessImage": livenessImage ?? "",
            "livenessOriginalImage": livenessOriginalImage ?? "",
            "color": images.images?.first?.colorString ?? "",
        ]
          pushEvent(data: dataRes)
        (livenessDetector as! LivenessUtilityDetector).stopLiveness()
    }
    
    func liveness(liveness: QTSLiveness.QTSLivenessDetector, didFail withError: QTSLiveness.QTSLivenessError) {
//        liveness.stopLiveness()
//        pushEvent(data: withError)
    }
    
//    func liveness(liveness: QTSLivenessDetector, didFinish verificationImage: UIImage, livenesScore: Float, faceMatchingScore: Float, result: Bool, message: String, videoURL: URL?, response: LivenessResult?) {
//        let imageData = verificationImage.pngData()!
//        let livenessImage = imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
//        let data = response?.data
//        if(response?.status == 200) {
//            let dataRes: [String: Any] = ["message": message, "livenessImage": livenessImage, "result": result, "code": 200, "livenesScore": livenesScore != 0 ? livenesScore : data!["livenesScore"] ?? 0, "request_id": response?.request_id ?? "", "status": response?.status ?? false, "success": response?.succes ?? false, "livenessType": data!["livenessType"] as? String ?? "", "faceMatchingScore": data!["faceMatchingScore"] as? String ?? "", "data": response?.data as Any]
//          pushEvent(data: dataRes)
//          livenessDetector?.stopLiveness()
//        }  else {
//            let dataRes: [String: Any] = ["message": message, "livenessImage": livenessImage, "result": result, "code": 101, "livenesScore": livenesScore, "status": response?.status ?? false, "success": response?.succes ?? false, "livenessType": data!["livenessType"] as? String ?? "", "faceMatchingScore": data!["faceMatchingScore"] as? String ?? "", "data": response?.data as Any]
//            pushEvent(data: dataRes)
//        }
//  //      Request id, message, status, success
//    }
    
    func liveness(liveness: QTSLiveness.QTSLivenessDetector, didFinishLocalLiveness score: Float, maxtrix: [Float], image: UIImage, thermal_image: UIImage, videoURL: URL?){
//        let livenessImage = saveImageToFile(image: image, isOriginal: false) ?? ""
        let livenessImage = convertImageToBase64(thermal_image) ?? ""
        let livenessOriginalImage = convertImageToBase64(image) ?? ""
       let dataRes: [String: Any] = [
            "livenessImage": livenessImage,
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

