import UIKit
//import LivenessUtility


@available(iOS 13.0, *)
@objc(LivenessRn)
class LivenessRn: NSObject {
     var appId = ""
  var secret = "ABCDEFGHIJKLMNOP"
  var baseURL = "https://face-matching.vietplus.eu"
  var clientTransactionId = "TEST"
    
    @objc(setConfigSDK:clientTransactionId:baseURL:publicKey:privateKey:)
    func setConfigSDK(appId: String, clientTransactionId: String, baseURL: String, publicKey: String, privateKey: String) {
//        Networking.shared.setup(appId: app/*Id, logLevel: .debug, url: baseURL, publicKey: publicKey, privateKey: privateKey)*/
    }
  
  @objc(getDeviceId:)
  func getDeviceId(callback: RCTResponseSenderBlock? = nil) -> Void {
//    Task{
//      do {
//        let resposne = try await Networking.shared.generateDeviceInfor()
//        callback?([resposne.data])
//      } catch{
//        callback?([NSNull(), error])
//      }
//    }
  }
  
  @objc(initTransaction:)
  func initTransaction(callback: RCTResponseSenderBlock? = nil) -> Void {
//    Task{
//      do{
//        let response = try await Networking.shared.initTransaction()
//        callback?([response.data])
//      }catch {
//        callback?([NSNull(), error])
//      }
//    }
  }
  
    @objc(registerFace:withCallback:)
    func registerFace(image: String, callback: RCTResponseSenderBlock? = nil) -> Void {
//      Task{
//        let dataAvatar = Data(base64Encoded: image)
//        if ((dataAvatar) != nil) {
//          let uiimage = UIImage(data: dataAvatar!)
//          do{
//            let response = try await Networking.shared.registerFace(faceImage: uiimage!)
//              callback?([["status" : response.status, "data": response.data, "signature": response.signature]])
//          }catch {
//            callback?([NSNull(), error])
//          }
//        }
//      }
    }
}
