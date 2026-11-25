//
//  CVpixelBuffer2UIImage16bit.h
//  TrueDepthStreamer
//  Copyright © 2018年 Apple. All rights reserved.
//


#ifndef CVpixelBuffer2UIImage16bit_h
#define CVpixelBuffer2UIImage16bit_h

#import <UIKit/UIKit.h>

typedef void(^TakePhotoSuccess)(void);

@interface PhotoView : UIView
/// CHỈ dùng trong app demo khi cần soi ảnh: YES = lưu ảnh màu + depth vào thư viện Photos.
/// Mặc định NO — SDK không tự lưu ảnh camera ra ngoài bộ nhớ.
@property (nonatomic, assign) BOOL saveToPhotoAlbum;

+ (UIImage*)depthBufferToImage:(CVPixelBufferRef) pixelBufffer;
- (instancetype)initWithFrame:(CGRect)frame withPositionDevice:(BOOL)isBack withTakePhotoSuccess:(TakePhotoSuccess)takePhotoSuccess;

- (void)startRunning;
- (UIImage*)depthBufferToImage:(CVPixelBufferRef) pixelBufffer;
- (void)stopRunning;
@end
#endif /* CVpixelBuffer2UIImage16bit_h */
