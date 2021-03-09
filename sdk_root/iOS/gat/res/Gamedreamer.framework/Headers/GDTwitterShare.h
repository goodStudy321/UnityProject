//
//  GDTwitterShare.h
//  InternationalSDK_Third
//
//  Created by GD-MB Pro on 2020/5/22.
//  Copyright © 2020 Efunfun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GDTwitterShare : NSObject

/**
 推特图片分享
 @param contentText               文字内容，单独分享图片时传入nil
 @param imageArr                      图片数组，单张图片也以数组的形式传入，分享文字内容时传入nil
 */
typedef void (^GDTwitterCompletion)(id result, NSError *_Nullable error);
+ (void)shareWithContentText:(NSString *)contentText ImageArr:(NSArray <UIImage *>*)imageArr complete:(GDTwitterCompletion)GDCallBack;

/*
 
 */
+ (NSData *)compressImageSize:(UIImage *)image toByte:(NSUInteger)maxLength;

@end

NS_ASSUME_NONNULL_END
