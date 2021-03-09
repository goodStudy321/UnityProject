//********************************************************************
// Created by Loong On 2019/7/18 10:12 PM
// Copyright @ 2019 .All rights reserved
// 晶绮港澳台
//********************************************************************

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Gamedreamer/Gamedreamer.h>


NS_ASSUME_NONNULL_BEGIN

#define SDK "Sdk"


#define SDK_CALL_RESULT_SUC = 0

#if defined(__cplusplus)
extern "C"
{
#endif
    //Unity调用方法
    
    //登录
    extern void Login();
    
    //登出
    extern void Logout();
    
    //支付
    extern void Pay(const char* json);
    
    //校验服务器
    extern void CheckSvr(const char* svrID);
    
    //显示悬浮窗
    extern void ShowToolBar(int place);
    
    //隐藏悬浮窗
    extern void HideToolBar();

    //创角色时上传数据
    extern void UploadRoleCreate(const char *roleName, const char*roleID);
    
    //选择角色时上传数据
    extern void UploadRoleSelect(const char *roleName, const char*roleID, const char*lv);
    
    //开始游戏
    extern void UploadBegGame();
    
    //会员中心
    extern void UserCenter();

    extern void Kefu();

    extern void LogEvent(const char* name);

    extern void LogEvent1(const char* name, const char* varName, const char* val);
    
    
    extern void SetBSUrl(const char *url, const char* login);
    
    extern void ShareFbLink(const char *link);

    extern void ShareFbTex(const char *persist, const char* streaming, const char* name);

    extern int GetInitOP();
    
    extern void UnitySendMessage(const char *, const char *, const char *);
    
    extern UIViewController *UnityGetGLViewController();
#if defined(__cplusplus)
}
#endif


@interface Sdk : NSObject<GamedreamerDelegate>
{
    //0:NONE,1:SUC,2:FAIL
    int initOp;
}
+(id) instance;
-(void) Init:(UIApplication *)application options:(NSDictionary *) opts;
-(void) OnLogin;
-(void) OnLogout;
-(void) OnPay:(const char*)json;
-(void) OnCheckSvr:(const char*)svrID;
-(void) OnRoleCreate:(const char *)roleName roleID:(const char*)roleid;
-(void) OnRoleSelect:(const char *)roleName roleID:(const char*)roleid lv:(const char*) rolelv;
-(void) OnBegGame;
-(void) OnUserCenter;
-(void) OnShareFbLink:(const char *)link;
-(void) OnShareFbTex:(const char *)persist streaming:(const char*)streamingPath name:(const char*) fileName;

-(void) OnLogEvent:(const char*)name;
-(void) OnLogEvent1:(const char*)name valName:(const char*) vn val:(const char*) v;
-(void) OnKefu;

-(int) initOP;
-(void) setInitOP:(int) op;
-(void) OnShowToolBar:(int) place;
-(void) OnHideToolBar;
-(NSString*) ToJson:(id)obj;
-(NSDictionary*) ToDicFromJson:(const char *)str;


-(void) Send:(const char*)method msg:(const char*) msg;
-(void) SendInitSuc;
-(void) SendInitFail;
-(void) SendLoginSuc:(const char*) msg;
-(void) SendLoginFail;
-(void) SendLogoutSuc;
-(void) SendLogoutFail;
-(void) SendPaySuc;
-(void) SendPayFail;
-(void) SendNeedRelogin;
-(void) SendCheckSvrFail;
-(void) SendCheckSvrSuc:(const char*)msg;
-(void) SendShareFbLink:(const char*)msg;
-(void) SendShareFbTex:(const char*)msg;
@end

NS_ASSUME_NONNULL_END
