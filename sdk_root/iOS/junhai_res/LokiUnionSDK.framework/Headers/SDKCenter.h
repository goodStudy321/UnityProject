#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PaymentInfo.h"
#import "Constants.h"
#import "SDKLoginUser.h"

#import "HHCAPI.h"

typedef NS_ENUM(NSUInteger, SDKCenterGameOrientation) {
    SDKCenterGameOrientationLandscape,
    SDKCenterGameOrientationPortrait,
};

/************************* 信息扩展接口事件,调用uploadUserData时的action ***********************/
extern NSString * const JHonEnterServer;
extern NSString * const JHonRoleUpdate;
/************************* 信息扩展接口事件,调用uploadUserData时的action ***********************/


/************************************* 回调通知信息订阅名称 ***********************************/
extern NSString * const JHonInitSuccess;
extern NSString * const JHonInitFailed;
extern NSString * const JHonLoginSuccess;
extern NSString * const JHonLoginFailed;
extern NSString * const JHonLogoutSuccess;
extern NSString * const JHonLogoutFailed;
extern NSString * const JHonPaySuccess;
extern NSString * const JHonPayFailed;
extern NSString * const JHonPayCancel;
/************************************* 回调通知信息订阅名称 ***********************************/

/**
 *
 * 君海用户、支付系统，调用中心类
 *
 **/

@interface SDKCenter : NSObject

/**
 *
 * 获取SDKCenter单例对象
 *
 **/
+ (SDKCenter *)sharedSDKCenter;

/**
 *
 * applicationWillTerminate函数托管，务必接入！！
 *
 * @param    application         UIApplication对象
 *
 **/
- (void)applicationWillTerminate:(UIApplication *)application;

/**
 *
 * applicationDidBecomeActive函数托管，务必接入！！
 *
 * @param    application         UIApplication对象
 *
 **/
- (void)applicationDidBecomeActive:(UIApplication *)application;

/**
 *
 * 初始化SDK
 *
 * @param    appId         君海提供的appId
 *
 * @param    appKey        君海提供的appKey
 *
 * @param    delegate      SDK全局回调协议对象
 *
 **/
- (void)initSDKWithAppId:(NSString *)appId withAppKey:(NSString *)appKey;


/**
 *
 * 启动登录界面
 *
 **/
- (void) startLogin;

/**
 *
 * 登陆两步验证结果回传，收到登陆回调后，请将session_id交由游戏服务器，向我方服务器进行两步验证
 *
 * 验证结果的json请转NSDictionary直接传入该接口，SDK将做登陆验证
 *
 * @param    userInfo    json解析为NSDictionary后直接传入
 *
 * 注意: 不推荐此方法.
 **/
- (void) onLoginResp:(NSDictionary *)userInfo __attribute__((deprecated("3.2.1版本后已过期")));


/**
 *
 * 登录两步验证结果回传，收到登录回调后，请将session_id交由游戏服务器，向我方服务器进行两步验证
 *
 * 验证结果json中取出 user_id，user_name，access_token。SDK将做登录验证，必须接入
 *
 * @param    userInfo    二次验证用户模型
 *
 **/
- (void) onLoginRespWithUserInfo:(SDKLoginUser *)userInfo;


/**
 *
 * 登出接口
 *
 **/
- (void) userLogout;

/**
 *
 *支付接口
 *
 **/
- (void) payWithPaymentInfo:(PaymentInfo *)paymentInfo;

/**
 *
 * 用户扩展信息接口
 *
 * @param    action      扩展事件名称
 *
 * @param    userData    用户信息，请务必传入真实信息，具体内容
 *                       JH_ROLE_ID        JH_SERVER_ID      JH_SERVER_NAME
 *                       JH_ROLE_NAME      JH_VIP_LEVEL      JH_PRODUCT_COUNT
 *                       JH_PRODUCT_NAME   JH_ROLE_LEVEL
 *
 **/

- (void) uploadUserData:(NSString *)action userData:(NSDictionary *)userData;

/**
 *
 * 获取用户信息接口，该接口在完成登录后调用即可获得用户信息，包含：JH_UID、JH_SESSION_ID、JH_UNAME
 *
 * 非法调用将返回nil
 *
 **/

- (NSDictionary *)getUserInfo;

/**
 *  获取SDK版本号
 *
 *  @return SDK版本号
 */

- (NSString *)getSDKVersion;

/**
 *  开启SDK Debug模式
 *
 */

- (void)setupSDKDebug;

@end
