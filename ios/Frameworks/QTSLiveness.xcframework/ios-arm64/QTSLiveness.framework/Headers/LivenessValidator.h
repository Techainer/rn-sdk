////
////  WrapperObject.h
////  TestImportProject
////
////  Created by admin on 29/09/2023.
////
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ARKit/ARKit.h>
//
//
@interface LivenessValidator : NSObject

- (instancetype)init;
-(float)calculatorLivenessWithValue1:(float)value1 matrix2:(float)value2;
//
//- (NSMutableArray<NSNumber *> *)getVectorDataFromImagePath:(NSString* )imagePath;
//- (NSMutableArray<NSNumber *> *)getVectorDataFromImage:(UIImage* )image;
//
//- (float)calculateSimilarityFromImagePath:(NSString* )imagePath andOther:(NSString *)otherImagePath;
//- (float)calculateSimilarityFromImage:(UIImage* )image andOther:(UIImage *)otherImage;
//
//
//- (float)calculateLivenessFromImage:(UIImage *)rgbImage andOther:(UIImage *)thermalImage;
//- (float)calculateLivenessFromImagePath:(NSString *)rgbImagePath andOther:(NSString *)thermalImagePath;
//- (float)calculateLivenessWithFlashWithImage:(UIImage*)image;
//-(float)calculateAntiSpoofingFace:(UIImage*)image;
////- (void)calculateLivenessFrom: (ARFrame *)frame onStartingHandler:(void(^)(bool))startHandler onFinishingHandler:(void(^)(bool))finishHandler;
//

@end
