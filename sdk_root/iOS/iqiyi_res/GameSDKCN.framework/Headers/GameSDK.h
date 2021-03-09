//
//  GameSDK.h
//  GameSDK
//
//  Created by iqiyi on 2018/1/19.
//  Copyright © 2018年 iqiyigame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GameSDKDelegate.h"
#import "GameSDKDef.h"
#import "GamePaymentDelegate.h"

#pragma mark -
#pragma mark APICallResult
/**
 * \brief 定义需要返回数据的同步接口的数据返回类型
 * 首先需要通过retCode字段判断接口调用是否成功，若成功则获取data字段
 */
@interface APICallResult : NSObject<NSCoding>


/**
 * 接口调用返回码
 */
@property (nonatomic, assign) GameOpenSDKAPICallResult retCode;


/**
 * 接口调用返回的数据字典
 */
@property (nonatomic, strong) NSDictionary *data;

@end

#pragma mark -
#pragma mark GameSDK
/**
 * \brief 爱奇艺自平台SDK提供的登录，应用内支付等开放接口
 * 爱奇艺自平台SDK提供了游客登录，爱奇艺账号密码登录，微信和QQ授权登录等登录方式，苹果应用内支付支持消耗品和非消耗品的购买，并且支持接入爱奇艺的客服平台
 */
@interface GameSDK : NSObject


/**
 * GameSDK为单例模式，在调用接口的地方需要使用此方法获取GameSDK对象

 @return GameSDK对象
 */
+ (id)sharedInstance;


/**
 * 初始化GameSDK，需要在AppDelegate的didFinishLaunchingWithOptions方法中调用

 @param gameId 对接游戏在爱奇艺游戏平台的ID
 @return YES:初始化成功 NO:已经初始化
 */
- (BOOL)initGameSDK:(NSString *) gameId;

/**
 * 初始化热云SDK，需要在AppDelegate的didFinishLaunchingWithOptions方法中调用
 
 @param appkey 创建产品时获得的32位字符长度的APPKEY
 @param channelId 填入默认值 "_default_"
 */
- (void)initReYunSDKWithAppKey:(NSString *)appkey channelId:(NSString *)channelId;
/**
 * 初始化QuickAD，需要在AppDelegate的didFinishLaunchingWithOptions方法中调用
 
 @param productCode QuickAD产品code
 */
- (void)initQKAdWithProductCode:(NSString *)productCode;

/**
 初始化QQ登录，需要在AppDelegate的didFinishLaunchingWithOptions方法中调用

 @param qqAppId 对接游戏在腾讯开放平台上的appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param qqUnionAPPID 对接游戏在爱奇艺平台上用于QQ授权登录的union appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 */
- (void)initQQLogin:(NSString *)qqAppId unionAppId:(NSString *)qqUnionAPPID;


/**
 初始化QQ登录，需要在AppDelegate的didFinishLaunchingWithOptions方法中调用

 @param wxAppId 对接游戏在微信开放平台上的appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param unionAppId 对接游戏在爱奇艺平台上用于微信授权登录的union appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 */
- (void)initWXLogin:(NSString *)wxAppId unionAppId:(NSString *)unionAppId;


/**
 初始化爱奇艺授权登录并设置应用图标URL地址用于爱奇艺登录跳转到爱奇艺APP时显示游戏图标，注意：不能传空， 图片尺寸:640*180 ；未调用该接口显示爱奇艺默认图标

 @param appIconUrl 应用Icon地址
 */
- (void)initIQYLogin:(NSString *)appIconUrl;

/**
 * 处理微信和QQ授权等第三方登录后调起游戏，通知授权登录结果

 @param url 第三方登录传递的url
 @return YES:能够处理传递的url NO:不能处理传递的url
 */
- (BOOL)handleOpenURL4OAuth:(NSURL *)url;


/**
 * 判断用户手机上是否安装了爱奇艺客户端。

 @return YES:安装了爱奇艺客户端 NO:没有安装爱奇艺客户端
 */
- (BOOL)isQYAppInstalled;

/**
 * 判断用户手机上是否安装了微信客户端，并向微信注册本游戏。
 * 注意：建议只有调用了此方法返回YES才能向用户展示微信登录图标
 *
 @param wxAppId 对接游戏在微信开放平台上的appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @return YES:安装了微信 NO:传入的wxAppId为空或没有安装微信
 */
- (BOOL)isWXAppInstalledWithAppId:(NSString *)wxAppId;

/**
 * 判断用户手机上是否安装了QQ客户端
 *
 @return YES:安装了QQ NO:没有安装QQ
 */
- (BOOL)isQQInstalled;

/**
 * 自动登录方式，登录逻辑为：
 * 1.若存在上次登录的缓存信息，则直接使用缓存信息登录；
 * 2.若没有登录缓存信息且支持极速登录（爱奇艺游戏后台配置）则自动使用游客方式进行登录；
 * 3.若没有登录缓存信息且不支持极速登录则返回登录失败，errorCode为LoginErrorAutoLoginDisable，收到此错误后需要
 *
 @param viewController 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录 
 */
- (GameOpenSDKAPICallResult)autoLogin:(UIViewController *)viewController delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * 游客登录方式

 @param viewController 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录
 */
- (GameOpenSDKAPICallResult)guestLogin:(UIViewController *)viewController delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * QQ授权登录方式

 @param qqAppId 对接游戏在腾讯开放平台上的appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param qqUnionAPPID 对接游戏在爱奇艺平台上用于QQ授权登录的union appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param vc 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录 GameOpenSDKAPICallErrorQQOAuthNotSurpport:没有安装qq或者版本不支持
 */
- (GameOpenSDKAPICallResult)qqAuthLogin:(NSString *) qqAppId unionAppId:(NSString *)qqUnionAPPID viewController:(UIViewController *)vc delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * 微信登录方式

 @param wxAppId 对接游戏在微信开放平台上的appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param unionAppId 对接游戏在爱奇艺平台上用于微信授权登录的union appId，此Id需要通过爱奇艺游戏的运营人员进行申请
 @param vc 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录 GameOpenSDKAPICallErrorWXAuthNotSurpport:没有安装微信或者版本不支持 
 */
- (GameOpenSDKAPICallResult)wxAuthLogin:(NSString *) wxAppId unionAppId:(NSString *)unionAppId viewController:(UIViewController *)vc delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * 爱奇艺登录方式

 @param vc 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录 GameOpenSDKAPICallErrorQYAuthNotSurpport:没有安装爱奇艺APP或者版本不支持
 */
- (GameOpenSDKAPICallResult)qyAuthLogin:(UIViewController *)vc delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * 爱奇艺账号登录方式：支持手机号验证码和账号密码登录

 @param viewController 游戏调用登录接口时所在的viewController，用于显示加载圈等控件
 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorReLogin:重复登录
 */
- (GameOpenSDKAPICallResult)accountLogin:(UIViewController *)viewController delegate:(id<GameLoginDelegate>) loginDelegate;


/**
 * 退出账号

 @param loginDelegate 接收登录结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorUnLogin:没有登录
 */
- (GameOpenSDKAPICallResult)userLogout:(id<GameLoginDelegate>)loginDelegate;


/**
 * 苹果应用内支付接口，只支持消耗品的购买
 * 在调用此接口前需要提供商品列表给爱奇艺游戏运营人员分别在苹果开发者账号和爱奇艺支付中心中进行配置

 @param viewController 游戏调用支付接口时所在的viewController,用于显示加载圈等控件
 @param serverId 游戏内的区服ID，必须是大于0的整数
 @param roleId 用户角色ID，不能为中文、json格式和特殊字符，只能为字母、数字和下划线
 @param money 商品金额（以元为单位）
 @param productId 商品ID
 @param orderId 游戏中生成的订单id
 @param developerinfo 游戏的透传信息，会在爱奇艺后台异步通知游戏后台时原样返回，例如游戏订单信息
 @param purchaseDelegate 接收支付结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorNetwork:网络未连接GameOpenSDKAPICallErrorPurchaseUnFinish:上次支付未结束 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)userPayment:(UIViewController *) viewController serverId:(NSString *) serverId roleId:(NSString *) roleId productPrice:(int) money productId:(NSString *) productId orderId:(NSString *) orderId developerInfo:(NSString *) developerinfo delegate:(id<GamePurchaseDelegate>) purchaseDelegate;


/**
 * 苹果应用内支付恢复已购买的非消耗品

 @param viewController 游戏调用恢复接口时所在的viewController，用于显示加载圈等控件
 @param restoreDelegate 接收恢复结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorNetwork:网络未连接GameOpenSDKAPICallErrorPurchaseUnFinish:上次支付未结束 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)restoreAllProducts:(UIViewController *) viewController delegate:(id<GameRestoreDelegate>) restoreDelegate;

/**
 * 游戏内创建游戏角色时通知SDK

 @param viewController 游戏调用此接口时所在的viewController
 @param serverId 游戏内的区服ID，必须是大于0的整数
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)createRole:(UIViewController *)viewController serverId:(NSString *) serverId;


/**
 * 游戏内进入游戏主场景时通知SDK

 @param viewController 游戏调用此接口时所在的viewController
 @param serverId 游戏内的区服ID，必须是大于0的整数
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)enterGame:(UIViewController *)viewController serverId:(NSString *) serverId;


/**
 * 登录成功显示悬浮窗

 @param point x： 0浮标显示在屏幕左边，1浮标显示在屏幕右边； y: (0 ~ 100)
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功
 */
- (GameOpenSDKAPICallResult)showFloatWithPoint:(CGPoint)point;


/**
 * 隐藏悬浮窗

 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功
 */
- (GameOpenSDKAPICallResult)hideFloat;


/**
 * 关闭百度和新浪登录

 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功
 */
- (GameOpenSDKAPICallResult)enableBaiduAndSinaLogin:(BOOL)yesOrNo;

/**
 * 游戏内调起用户协议与隐私保护页面
 * 该接口只在首次初始化SDK后，第一次调用时展示页面，以后调用不会展示页面。建议在展示登录窗之后调用
 
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功
 */
- (GameOpenSDKAPICallResult)showPrivacyAgreement;

/**
 * 游戏内调起爱奇艺平台客服页面

 @param viewController 游戏调用此接口时所在的viewController
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)customService:(UIViewController *) viewController;

/**
 * 游戏内调起绑定手机页面
 
 @param viewController 游戏调用此接口时所在的viewController
 @param delegate 接收绑定结果的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)bindPhone:(UIViewController *) viewController delegate:(id<GameLoginDelegate>)delegate;

/**
 * 游戏内调起侧边栏支付订单页面
 
 @param viewController 游戏调用此接口时所在的viewController
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)showOrderList:(UIViewController *) viewController;

/**
 * 游戏内调起侧边栏消息页面
 
 @param viewController 游戏调用此接口时所在的viewController
 @return 接口调用结果，GameOpenSDKAPICallSuccess:接口调用成功 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)showMessageList:(UIViewController *) viewController;

/**
 * 获取侧边栏未读消息数
 
 @return 接口调用结果，若APICallResult中retCode字段为GameOpenSDKAPICallSuccess则其中data字段不为空，为未读消息数；若retCode字段为GameOpenSDKAPICallErrorUnLogin则表示用户未登录，data字段为空
 */
- (APICallResult *)getUnReadMessageCount;


/**
 * 获取登录成功后缓存的用户信息

 @return 接口调用结果，若APICallResult中retCode字段为GameOpenSDKAPICallSuccess则其中data字段不为空，包含的信息与接收登录结果委托对象中获取的数据相同；若retCode字段为GameOpenSDKAPICallErrorUnLogin则表示用户未登录，data字段为空
 */
- (APICallResult *)getLocalUserInfo;


/**
 * 异步获取其他用户信息，此版本只包括游戏VIP信息

 @param delegate 接收用户信息的委托对象
 @return 接口调用结果，GameOpenSDKAPICallSuccess:成功 GameOpenSDKAPICallErrorParams:传入的委托对象为空 GameOpenSDKAPICallErrorUnLogin:用户未登录
 */
- (GameOpenSDKAPICallResult)getUserInfoAsync:(id<GetUserInfoDelegate>)delegate;

@end
