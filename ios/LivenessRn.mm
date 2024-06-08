#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(LivenessRn, NSObject)

RCT_EXTERN_METHOD(setConfigSDK:(NSString *)appId clientTransactionId:(NSString *)clientTransactionId baseURL:(NSString *)baseURL publicKey:(NSString *)publicKey privateKey:(NSString *)privateKey)

RCT_EXTERN_METHOD(registerFace:(NSString *)image
                 withCallback:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(initTransaction: (RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(getDeviceId: (RCTResponseSenderBlock)callback)

//RCT_EXTERN_METHOD(initTransaction:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject)

@end
