//
//  Sdk.h
//  Unity-iPhone
//
//  Created by 查理 on 2018/9/7.
//

#import <Foundation/Foundation.h>
#define SDK "Sdk"
#define LOGIN_URL @"index/Junhai/iosAuth"

#define APP_ID @"400000007"
#define APP_KEY @"23cccf0162b3b1d95fa880e61f911963"

#if defined(__cplusplus)
extern "C"
{
#endif
    
    //Unity调用方法
    //初始化
    extern void init();
    
    //登陆
    extern void login();
    
    //登出
    extern void logout();
    
    //支付
    extern void pay(const char *json);
    
    //进入服务器时上传数据
    extern void updataOnEnterSvr(const char *json);
    
    //角色升级时上传数据
    extern void updataOnRoleUpg(const char *json);
    
    //向Unity发送消息
    //extern void UnitySendMessage(const char *,const char *,const char *);
    
#if defined(__cplusplus)
}
#endif


@interface Sdk : NSObject
-(void) onInitSuccess:(NSNotification *)notify;
-(void) onInitFailed:(NSNotification *)notify;
-(void) onPay:(const char *)json;
-(void) onUpdataOnEnterSvr:(const char *)json;
-(void) onUpdataOnRoleUpg:(const char *)json;
-(void) onLoginSuccess:(NSNotification *) notify;
-(void) onLoginFailed:(NSNotification *) notify;
-(void) onLogoutSuccess:(NSNotification *) notify;
-(void) onLogoutFailed:(NSNotification *) notify;
-(void) onPaySuccess:(NSNotification *) notify;
-(void) onPayFailed:(NSNotification *) notify;
-(void) onPayCancel:(NSNotification *) notify;
@end
