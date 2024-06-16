//
//  LivenessView.m
//  AppTest
//
//  Created by NamNg on 5/14/24.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>

 
@interface RCT_EXTERN_MODULE(RCTLivenessViewManager, RCTViewManager)
//  RCT_EXPORT_VIEW_PROPERTY(status, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(onEvent, RCTBubblingEventBlock)
  // RCT_EXPORT_VIEW_PROPERTY(requestid, NSString)
  // RCT_EXPORT_VIEW_PROPERTY(appId, NSString)
  // RCT_EXPORT_VIEW_PROPERTY(baseUrl, NSString)
  // RCT_EXPORT_VIEW_PROPERTY(privateKey, NSString)
  // RCT_EXPORT_VIEW_PROPERTY(publicKey, NSString)
  RCT_EXPORT_VIEW_PROPERTY(debugging, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(isThree, BOOL)
@end
