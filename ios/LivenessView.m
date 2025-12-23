#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>

 
@interface RCT_EXTERN_MODULE(RCTLivenessViewManager, RCTViewManager)
//  RCT_EXPORT_VIEW_PROPERTY(status, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(onEvent, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(isFlashCamera, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(isDebug, BOOL)
@end
