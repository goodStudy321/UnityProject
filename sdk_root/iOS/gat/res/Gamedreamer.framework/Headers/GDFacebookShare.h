//
//  EFEFFacebookShare.h
//  InternationalSDK_Third
//
//  Created by gd on 13/10/16.
//  Copyright © 2016年 Efunfun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GDShareType) {
    GDShareTypeSuccess,       //分享成功
    GDShareTypeFail,          //分享失败
    GDShareTypeCancel,        //分享取消
    GDShareTypeNoapp          //没有客户端
};

typedef void(^EFShareCallback)(
                               BOOL shareResult
                               );

typedef void(^GDShareCallback)(
                               GDShareType shareResult
                               );


@interface GDFacebookShare : NSObject


+ (instancetype)shareInstance;


/**
 *  旧版facebook分享
 *  用於遊戲內分享內容到facebook
 *
 *  @param viewController   分享彈出界面從父節點 如無可以傳入nil
 *  @param EFCallback       分享成功與否block。
 */
- (void)gamedreamerFacebookShareFrom:(UIViewController *)viewController
                                Link:(NSString *)link
                            complete:(EFShareCallback)EFCallback; NS_DEPRECATED_IOS(4_2, 8_0, "请使用新接口 返回参数更加详细") __TVOS_PROHIBITED;


/**
 *  新版 facebook分享
 *  用於遊戲內分享內容到facebook
 *
 *  @param viewController   分享彈出界面從父節點 如無可以傳入nil
 *  @param GDCallback       分享结果block。
 */
- (void)gamedreamerNewFacebookShareFrom:(UIViewController *)viewController
                                   Link:(NSString *)link
                               complete:(GDShareCallback)GDCallback;


/**
 *  旧版 facebook 圖片分享
 *  用於遊戲內分享內容到facebook
 *  需要在LSApplicationQueriesSchemes 中添加 fbapi 與 fbshareextension
 *
 *  @param viewController  分享彈出界面從父節點 如無可以傳入nil
 *  @param EFCallback 分享成功與否block。
 */
- (void)gamedreamerFacebookShare:(UIViewController *)viewController
                      LocalImage:(UIImage *)picture
                      completion:(EFShareCallback)EFCallback; NS_DEPRECATED_IOS(4_2, 8_0, "请使用新接口 返回参数更加详细") __TVOS_PROHIBITED;


/**
 *  新版 facebook 圖片分享
 *  用於遊戲內分享內容到facebook
 *  需要在LSApplicationQueriesSchemes 中添加 fbapi 與 fbshareextension
 *
 *  @param viewController  分享彈出界面從父節點 如無可以傳入nil
 *  @param GDCallback 分享结果block。
 */
- (void)gamedreamerNewFacebookShare:(UIViewController *)viewController
                         LocalImage:(UIImage *)picture
                         completion:(GDShareCallback)GDCallback;


@end
