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
  var transactionId = ""
  var livenessDetector: LivenessUtilityDetector?
  var requestid = ""
  var appId = ""
  var baseUrl = ""
  var privateKey = ""
  var publicKey = ""
  var secret = "ABCDEFGHIJKLMNOP"
    var debugging = false
    var isDoneSmile = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
//    setupView()
  }
 
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//    setupView()
  }
    
    private func setupConfig() {
        Networking.shared.setup(appId: appId, logLevel: .debug, url: self.baseUrl, publicKey: self.publicKey, privateKey: self.privateKey)
        setupView()
    }
 
  private func setupView() {
    // in here you can configure your view
    Task {
      do {
        let response = try await Networking.shared.initTransaction(additionParam: ["clientTransactionId": self.requestid], clientTransactionId: self.requestid)
        if response.status == 200 {
          self.transactionId = response.data
            self.livenessDetector = LivenessUtil.createLivenessDetector(previewView: self, threshold: .low,delay: 0, smallFaceThreshold: 0.25, debugging: true, delegate: self, livenessMode: faceIDAvailable ? .threeDimension : .twoDimension, isWink: false, isOnlyLiveness: true)
            
          try self.livenessDetector?.getVerificationRequiresAndStartSession(transactionId: self.transactionId)
        } else {
          pushEvent(data: ["status" : response.status, "data": response.data, "signature": response.signature])
        }
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
  
  @objc func setRequestid(_ val: NSString) {
      self.requestid = val as String
  }
    
  @objc func setAppId(_ val: NSString) {
    self.appId = val as String
  }
    
  @objc func setBaseUrl(_ val: NSString) {
    self.baseUrl = val as String
      self.setupConfig()
  }
    
    @objc func setPrivateKey(_ val: NSString) {
      self.privateKey = val as String
    }
    
    @objc func setPublicKey(_ val: NSString) {
      self.publicKey = val as String
    }
    
    @objc func setDebugging(_ val: Bool) {
        self.debugging = val as Bool
      }
  
  func liveness(liveness: LivenessUtilityDetector, didFail withError: LivenessError) {
    pushEvent(data: withError)
  }
  
    func liveness(liveness: LivenessUtilityDetector, didFinish verificationImage: UIImage, livenesScore: Float, faceMatchingScore: Float, result: Bool, message: String, videoURL: URL?, response: LivenessResult?) {
          let imageData = verificationImage.pngData()!
          let livenessImage = imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
          let data = response?.data
        if(response?.status == 200) {
            let dataRes: [String: Any] = ["message": message, "livenessImage": livenessImage, "result": true, "code": 200, "livenesScore": livenesScore, "request_id": response?.request_id ?? "", "status": "200", "success": true, "livenessType": data!["livenessType"] as? String ?? "", "faceMatchingScore": data!["faceMatchingScore"] as? String ?? "", "data": response?.data as Any]
            pushEvent(data: dataRes)
            livenessDetector?.stopLiveness()
        } else {
            let dataRes: [String: Any] = ["message": message, "livenessImage": livenessImage, "result": false, "code": 101, "livenesScore": livenesScore, "status": response?.status as Any, "success": false, "livenessType": data!["livenessType"] as? String ?? "", "faceMatchingScore": data!["faceMatchingScore"] as? String ?? "", "data": response?.data as Any]
            pushEvent(data: dataRes)
        }
        //      Request id, message, status, success
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
            pushEvent(data: ["message": "done smile", "action": action.rawValue])
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
