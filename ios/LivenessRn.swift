import React
import UIKit
@_implementationOnly import LivenessUtility
//import LivenessUtility


@available(iOS 13.0, *)
@objc(LivenessRn)
class LivenessRn: NSObject {
     var appId = ""
  var secret = "ABCDEFGHIJKLMNOP"
  var baseURL = "https://face-matching.vietplus.eu"
  var clientTransactionId = "TEST"
  
    @objc(configure:publicKey:privateKey:secret:baseURL:clientTransactionId:)
    func configure(appId: String, publicKey: String, privateKey: String, secret: String? = nil, baseURL: String? = nil, clientTransactionId: String? = "") {
    self.appId = appId
    if (secret != nil && secret != "") {
      self.secret = secret!
    }
    if (baseURL != nil && baseURL != "") {
      self.baseURL = baseURL!
    }
    if (clientTransactionId != nil && clientTransactionId != "") {
      self.clientTransactionId = clientTransactionId!
    }
    print("setup SS")
  }
  
  @objc(getDeviceId:)
  func getDeviceId(callback: RCTResponseSenderBlock? = nil) -> Void {
    Task{
      do {
        let resposne = try await Networking.shared.generateDeviceInfor()
        callback?([resposne.data])
      } catch{
        callback?([NSNull(), error])
      }
    }
  }
  
  @objc(initTransaction:)
  func initTransaction(callback: RCTResponseSenderBlock? = nil) -> Void {
    Task{
      do{
        let response = try await Networking.shared.initTransaction()
        callback?([response.data])
      }catch {
        callback?([NSNull(), error])
      }
    }
  }
  
    @objc(registerFace:withCallback:)
    func registerFace(image: String, callback: RCTResponseSenderBlock? = nil) -> Void {
      Task{
        let dataAvatar = Data(base64Encoded: image)
        if ((dataAvatar) != nil) {
          let uiimage = UIImage(data: dataAvatar!)
          do{
            let response = try await Networking.shared.registerFace(faceImage: uiimage!)
              callback?([["status" : response.status, "data": response.data, "signature": response.signature]])
          }catch {
            callback?([NSNull(), error])
          }
        }
      }
    }
  
  @objc(startLiveNess:withCallback:)
  func startLiveNess(previewView: UIView, callback: RCTResponseSenderBlock? = nil) {
    
  }
}
