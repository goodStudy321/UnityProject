//
//  GameSDKDelegate.h
//  GameSDK
//
//  Created by iqiyi on 2018/1/19.
//  Copyright © 2018年 iqiyigame. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * 定义登录结果错误码

 - LoginErrorAutoLoginDisable: 不支持自动登录方式
 - LoginErrorOther: 其他登录错误
 - LoginErrorCancel: 用户取消登录
 */
typedef NS_ENUM(NSInteger, LoginErrorCode){
    LoginErrorAutoLoginDisable = 1,
    LoginErrorOther = 2,
    LoginErrorCancel = 3,
};

#pragma mark -
#pragma mark GameLoginDelegate


/**
 * \brief 处理登录和退出登录结果的回调协议
 */
@protocol GameLoginDelegate <NSObject>

/**
 * 处理登录成功结果，登录成功返回的用户信息如下：
 *               | 字段名称     | 类型    | 描述                                   |
 *               | ---------- | ------- | ----------------                      |
 *               | uid        |  string | 爱奇艺平台用户ID                         |
 *               | uname      |  string | 爱奇艺平台用户名                         |
 *               | timestamp  |  string | 时间戳，用于用户登录验证                  |
 *               | sign       |  string | 签名,用于用户登录验证                    |
 *               | isAdult    |  string | 是否为成年人，true为成年人，false为未成年人 |
 *               | vipType    |  string | 会员类型,0为非会员，1为会员               |
 *               | vipLevel   |  string | 会员等级                               |
 *               | province   |  string | 省份编号                               |
 *               | city       |  string | 城市编号                               |
 *               | gender     |  string | 用户性别，1为男性，0为女性                |
 *               | icon       |  string | 用户头像URL                            |
 *               | guestUid   |  string | 爱奇艺平台游客用户ID                     |
 *               | bindedPhone|  string | 是否绑定了手机，0为未绑定，1为已绑定        |


 @param loginUser 登录成功后获取到的用户信息
 */
@required
-(void) loginSuccess:(NSDictionary *) loginUser;

/**
 * 处理登录失败结果

 @param errorCode 错误码
 @param msg 错误信息
 */
@required
-(void) loginFail:(LoginErrorCode)errorCode msg:(NSString *) msg;

/**
 * 处理退出登录结果，收到退出登录回调后保存当前用户游戏进度并回到登录界面
 @param data 退出登录的用户信息字典，包含uid字段
 */
@required
- (void)logoutSuccess:(NSDictionary *)data;

/**
 * 绑定手机号成功
 *               | 字段名称     | 类型    | 描述                                  |
 *               | ---------- | ------- | ----------------                     |
 *               | uid        |  string | 爱奇艺平台用户ID                        |

 @param data 绑定成功后返回信息
 */
@optional
- (void)bindPhoneSuccess:(NSDictionary *)data;

/**
 * 绑定手机号失败
 @param errorCode 错误码 1:用户取消绑定手机;
 @param msg 错误信息
 */
@optional
- (void)bindPhoneFail:(NSInteger)errorCode msg:(NSString *)msg;

/**
 * 游客转正过程接收到游客账号和正式账号的uid
 @param data 返回游客uid和正式账号uid
 */
@optional
- (void)didReceivedBindingMessage:(NSDictionary *)data;
@end

#pragma mark -
#pragma mark GetUserInfoDelegate

/**
 * \brief 处理异步获取用户信息的回调协议
 */
@protocol GetUserInfoDelegate  <NSObject>

/**
 * 处理获取用户信息成功结果，userInfoDic字典包含的字段如下：
 *               | 字段名称            | 类型    | 描述                                   |
 *               | ----------------- | ------- | ----------------                      |
 *               | isGameVip         |  string | 是否为游戏VIP，1:是，0:不是               |
 *               | vipType           |  string | 会员类型,0为非会员，1为会员               |
 *               | vipLevel          |  string | 会员等级                               |
 */
@required
- (void)getUserInfoDidSuccess:(NSDictionary *)userInfoDic;

/**
 * 处理获取用户信息失败结果

 @param msg 失败信息
 */
@required
- (void)getUserInfoDidFail:(NSString *)msg;
@end
