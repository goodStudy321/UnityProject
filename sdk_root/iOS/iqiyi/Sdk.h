//********************************************************************
// Created by Loong On 2019/7/18 10:12 PM
// Copyright @ 2019 .All rights reserved
//********************************************************************

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GameSDKCN/GamePaymentDelegate.h>
#import <GameSDKCN/GameSDK.h>
#import <GameSDKCN/GameSDKCN.h>
#import <GameSDKCN/GameSDKDef.h>
#import <GameSDKCN/GameSDKDelegate.h>

NS_ASSUME_NONNULL_BEGIN

#define SDK "Sdk"

#define LOGIN_URL @"index/Iqiyi/auth"

#define SDK_CALL_RESULT_SUC = 0

#if defined(__cplusplus)
extern "C"
{
#endif
    //Unity调用方法
    
    //登录
    extern int Login();
    
    //登出
    extern int Logout();
    
    //支付
    extern int Pay(const char* json);
    
    //显示悬浮窗
    extern int ShowFloat(int x, int y);
    
    //隐藏悬浮窗
    extern int HideFloat();
    
    extern int BindPhone();
    
    //创角色时上传数据
    extern int UpdataOnRoleCreate(const char *svrID);
    
    //进入地图时上传数据
    extern int UpdataOnSceneEnter(const char *svrID);
    
    //通知绑定结果
    extern void NotifyBind(const char *json);
    
    extern void SetBSUrl(const char *url);
    
    extern int GetInitOP();
    
    //extern void UnitySendMessage(const char *, const char *, const char *);
    
    //extern UIViewController *UnityGetGLViewController();
#if defined(__cplusplus)
}
#endif


@interface Sdk : NSObject<GameLoginDelegate,GamePurchaseDelegate>
{
    BOOL firstLogin;
    //0:NONE,1:SUC,2:FAIL
    int initOp;
}
+(id) instance;
-(void) Init;
-(int) OnLogin;
-(int) OnLogout;
-(int) OnPay:(const char*)json;
-(int) OnUpdataOnRoleCreate:(const char *)svrID;
-(int) OnUpdataOnSceneEnter:(const char *)svrID;
-(BOOL) firstLogin;
-(void) setFirstLogin:(BOOL) val;
-(int) initOP;
-(void) setInitOP:(int) op;
-(int) OnShowFloat:(int) x  ht:(int) y;
-(int) OnHideFloat;
-(int) OnBindPhone;
-(void) OnNotifyBind:(const char*)json;
-(NSString*) ToJson:(id)obj;
-(NSDictionary*) ToDicFromJson:(const char *)str;
@end

NS_ASSUME_NONNULL_END
