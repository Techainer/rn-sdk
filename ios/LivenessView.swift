//
//  LivenessView.swift
//  AppTest
//
//  Created by NamNg on 5/14/24.
//

import Foundation
import React
import UIKit
@_implementationOnly import LivenessUtility

@available(iOS 13.0, *)
class LivenessView: UIView, LivenessUtilityDetectorDelegate {
  var transactionId = ""
  var livenessDetector: LivenessUtilityDetector?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
 
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
 
  private func setupView() {
    // in here you can configure your view
    Task {
      do {
        let response = try await Networking.shared.initTransaction()
        if response.status == 200 {
          self.transactionId = response.data
          self.livenessDetector = LivenessUtil.createLivenessDetector(previewView: self, threshold: .low,delay: 0, smallFaceThreshold: 0.25, debugging: true, delegate: self, livenessMode: .twoDimension)
          try self.livenessDetector?.getVerificationRequiresAndStartSession(transactionId: self.transactionId)
        } else {
          pushEvent(data: [["status" : response.status, "data": response.data, "signature": response.signature]])
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
  
  func liveness(liveness: LivenessUtilityDetector, didFail withError: LivenessError) {
    pushEvent(data: withError)
  }
  
  func liveness(liveness: LivenessUtilityDetector, didFinish verificationImage: UIImage, livenesScore: Float, faceMatchingScore: Float, result: Bool, message: String, videoURL: URL?) {
    pushEvent(data: message)
  }
}