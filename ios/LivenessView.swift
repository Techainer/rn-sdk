//
//  LivenessView.swift
//  AppTest
//
//  Created by NamNg on 5/14/24.
//

import Foundation
import React
import UIKit
import LocalAuthentication
@_implementationOnly import LivenessUtility

@available(iOS 13.0, *)
class LivenessView: UIView, LivenessUtilityDetectorDelegate {
  var livenessDetector: LivenessUtilityDetector?
  var debugging = false
//  var isThreeDimension = false
  var isDoneSmile = false
    var minFaceSize = 0.25
  
  override init(frame: CGRect) {
    super.init(frame: frame)
//    setupView()
  }
 
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//    setupView()
  }
 
  private func setupView() {
    // in here you can configure your view
    Task {
      do {
        if isThreeDimension == true {
          self.livenessDetector = LivenessUtil.createLivenessDetector(previewView: self, threshold: .low,delay: 0, smallFaceThreshold: minFaceSize, debugging: self.debugging, delegate: self, livenessMode: faceIDAvailable ? .threeDimension : .twoDimension)
        } else {
          self.livenessDetector = LivenessUtil.createLivenessDetector(previewView: self, threshold: .low,delay: 0, smallFaceThreshold: minFaceSize, debugging: self.debugging, delegate: self, livenessMode: .twoDimension)
        }
        try self.livenessDetector?.getVerificationRequiresAndStartSession()
      } catch {
        pushEvent(data: error)
      }
    }
  }
  
  private func pushEvent(data: Any) -> Void {
    if (self.onEvent != nil) {
      let event = ["data": data]
      self.onEvent!(event)
    }
  }
  
  @objc var onEvent: RCTBubblingEventBlock?
    
  @objc func setDebugging(_ val: Bool) {
    self.debugging = val as Bool
  }
    
  @objc func setMinFaceSize(_ val: Double) {
    self.minFaceSize = val
      self.setupView()
  }

  @objc var isThreeDimension = false {
    didSet {
//      self.setupView()
    }
  }
  
  func liveness(liveness: LivenessUtilityDetector, didFail withError: LivenessError) {
    pushEvent(data: withError)
  }
  
  func liveness(liveness: LivenessUtilityDetector, didFinish verificationImage: UIImage, thermalImage: UIImage?, videoURL: URL?) {
    Task {
        let compressData = verificationImage.jpegData(compressionQuality: 0.25)
        let compressedImage = UIImage(data: compressData!)
        let image1 = compressedImage?.pngData()!
        let livenessImage = image1?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
      if faceIDAvailable == true {
        if thermalImage != nil {
            let compressDataThermal = thermalImage?.jpegData(compressionQuality: 0.25)
            let compressedImageThermal = UIImage(data: compressDataThermal!)
          let image2 = compressedImageThermal?.pngData()!
          let thermalImageBase64 = image2?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
            pushEvent(data: ["message": "done smile", "action": 8, "livenessImage": livenessImage ?? "", "thermalImage": thermalImageBase64 ?? "", "videoURL": videoURL?.absoluteString ?? ""])
        } else {
            pushEvent(data: ["message": "done smile", "action": 8, "livenessImage": livenessImage ?? "", "videoURL": videoURL?.absoluteString ?? ""])
        }
      } else {
        pushEvent(data: ["message": "done smile", "action": 8, "livenessImage": livenessImage ?? "", "videoURL": videoURL?.absoluteString ?? ""])
      }
//      pushEvent(data: ["message": "done smile", "action": 8, "livenessImage": livenessImage])
      livenessDetector?.stopLiveness()
    }
  }
    
  func liveness(liveness: LivenessUtilityDetector, startLivenessAction action: LivenessAction) {
    if action == .smile{
      isDoneSmile = false
      pushEvent(data: ["message": "check smile", "action": action.rawValue])
    } else if action == .fetchConfig{
      isDoneSmile = false
      pushEvent(data: ["message": "start check smile", "action": action.rawValue])
    } else if action == .detectingFace{
      isDoneSmile = false
      pushEvent(data: ["message": "detect face", "action": action.rawValue])
    } else if isDoneSmile == false{
      isDoneSmile = true
//      pushEvent(data: ["message": "done smile", "action": action.rawValue])
      print("done smile")
    }
  }
    
    
  func stopLiveness() {
    livenessDetector?.stopLiveness()
  }

  var faceIDAvailable: Bool {
    if #available(iOS 11.0, *) {
      let context = LAContext()
      return (context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil) && context.biometryType == .faceID)
    }
    return false
  }
}
