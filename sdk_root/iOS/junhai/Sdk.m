//
//  Sdk.m
//  Unity-iPhone
//
//  Created by 查理 on 2018/9/7.
//

#import <Foundation/Foundation.h>
#import <LokiUnionSDK/LokiUnionSDK.h>
#import "DemoHttpClient.h"
#import "Sdk.h"
#import "App.h"

@implementation Sdk

+(id) instance
{
    static Sdk * instance = nil;
    if (instance==nil)
    {
        @synchronized(self)
        {
            if(instance==nil)
            {
                instance = [[self alloc] init];
            }
        }
    }
    return (instance);
}

-(id) init
{
    if(self = [super init])
    {
        id center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onLoginSuccess:) name:JHonLoginSuccess object:nil];
        [center addObserver:self selector:@selector(onLoginFailed:) name:JHonLoginFailed object:nil];
        
        [center addObserver:self selector:@selector(onLogoutSuccess:) name:JHonLogoutSuccess object:nil];
        [center addObserver:self selector:@selector(onLogoutFailed:) name:JHonLogoutFailed object:nil];
        
        [center addObserver:self selector:@selector(onPaySuccess:) name:JHonPaySuccess object:nil];
        [center addObserver:self selector:@selector(onPayFailed:) name:JHonPayFailed object:nil];
        [center addObserver:self selector:@selector(onPayCancel:) name:JHonPayCancel object:nil];
    }
    return (self);
}

-(void) onLoginSuccess:(NSNotification *)notify
{
    NSLog(@"SDK登录回调成功,准备二次验证URL:%@",LOGIN_URL);
    NSDictionary *userInfo = (NSDictionary *)notify.object;
    NSString *sessionId = [userInfo objectForKey:JG_SESSION_ID];
    NSDictionary *params = @{@"game_id": APP_ID /*注意填app id*/,
                             @"authorize_code": sessionId};
    NSLog(@"SDK 二次验证参数:%@",params);
    [[DemoHttpClient sharedDemoHttpClient] send:self method:@"GET" url:LOGIN_URL parameters:params timeout:10.0 completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError){
            NSLog(@"SDK 登陆验证错误 %@", [connectionError localizedDescription]);
            NSLog(@"SDK 登陆错误码: = %ld", (long)[connectionError code]);
            UnitySendMessage(SDK, "LoginFail", " ");
        }else if([(NSHTTPURLResponse *)response statusCode] != 200){
            NSLog(@"SDK 登陆验证错误Http返回状态码 %@", @([(NSHTTPURLResponse *)response statusCode]).stringValue);
            NSString *response = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
            
            NSLog(@"SDK response:%@", response);
            UnitySendMessage(SDK, "LoginFail", " ");
        }else{
            
            //二验成功后，把获取到的返回参数回传sdk
            
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            
            NSDictionary *statusDic = jsonDict[@"status"];
            int code = [[statusDic objectForKey:@"code"] intValue];
            int rightCode = 10200;
            if (code == rightCode)
            {
                NSLog(@"SDK 二验成功,信息:%@",jsonDict);
                NSDictionary *dataDic = jsonDict[@"data"];
                SDKLoginUser *loginUser = [SDKLoginUser new];
                NSNumber *num =dataDic[@"union_user_id"];
                NSString *str = [num stringValue];
                loginUser.uid = str;
                loginUser.accessToken = dataDic[@"access_token"];
                // loginUser.userName = jsonDict[@"login_info"][@"user_name"];
                loginUser.userName = @"";
                [[SDKCenter sharedSDKCenter] onLoginRespWithUserInfo:loginUser];
                const char *uid = [str UTF8String];
                UnitySendMessage(SDK, "LoginSuc", uid);
            }
            else
            {
                NSLog(@"SDK 二验失败,信息:%@",jsonDict);
                UnitySendMessage(SDK, "LoginFail", " ");
            }
        }
    }];
    
}

-(void) onLoginFailed:(NSNotification *)notify
{
    [self onFailed:notify tip:@"SDK登录失败" fn:"LoginFail"];
}

-(void) onLogoutSuccess:(NSNotification *)notify
{
    NSLog(@"SDK登出成功");
    UnitySendMessage(SDK, "LogoutSuc", " ");
}

-(void) onLogoutFailed:(NSNotification *)notify
{
    [self onFailed:notify tip:@"SDK登出失败" fn:"LogoutFail"];
}

-(void) onPaySuccess:(NSNotification *)notify
{
    NSLog(@"SDK支付成功");
    UnitySendMessage(SDK, "PaySuc", " ");
}

-(void) onPayFailed:(NSNotification *)notify
{
    [self onFailed:notify tip:@"SDK支付失败" fn:"PayFail"];
}

-(void) onPayCancel:(NSNotification *)notify
{
    NSLog(@"SDK支付取消");
    UnitySendMessage(SDK, "PayCancel", " ");
}

-(void) onFailed:(NSNotification *)notify tip:(NSString *)_tip fn:(const char *)fn
{
    NSString *msg = (NSString *)notify.object;
    NSLog(@"%@:%@",_tip,msg);
    const char * str=[msg UTF8String];
    UnitySendMessage(SDK, fn, str);
}

-(void)onPay:(const char *)json
{
    NSString * jstr = CreateNSString(json);
    NSLog(@"支付数据:%@",jstr);
    NSData * jd = [jstr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jd options:NSJSONReadingMutableLeaves error:nil];
    NSString *ordID = [dic objectForKey:@"ordID"];
    int money = [[dic objectForKey:@"money"] intValue];
    int count = [[dic objectForKey:@"count"] intValue];
    NSString *proID = [dic objectForKey:@"proID"];
    NSString *proName=[dic objectForKey:@"proName"];
    int rate = [[dic objectForKey:@"rate"] intValue];
    NSString *desc = [dic objectForKey:@"desc"];
    NSString *url = [dic objectForKey:@"url"];
    NSString *roleID = [dic objectForKey:@"roleID"];
    NSString *svrName = [dic objectForKey:@"svrName"];
    int svrID = [[dic objectForKey:@"svrID"] intValue];
    NSString *roleName=[dic objectForKey:@"roleName"];
    NSString *appleProID = [dic objectForKey:@"appleProID"];
    
    
    PaymentInfo *info = [[PaymentInfo alloc] init];
    [info setOrderId:ordID];
    [info setPayMoney:money];
    [info setProductCount:count];
    [info setProductId:proID];
    [info setProductName:proName];
    [info setRate:rate];
    [info setPaymentDesc:desc];
    [info setNotifyUrl:url];
    [info setRoleId:roleID];
    [info setServerName:svrName];
    [info setServerId:svrID];
    [info setRoleName:roleName];
    [info setAppleProductId:appleProID];
    [[SDKCenter sharedSDKCenter] payWithPaymentInfo:info];
}

-(NSDictionary *) getData:(const char*)json
{
    NSString * jstr = CreateNSString(json);
    NSLog(@"获取用户数据:%@",jstr);
    NSData * jd = [jstr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jd options:NSJSONReadingMutableLeaves error:nil];
    NSString *roleID = [dic objectForKey:@"roleID"];
    int svrID = [[dic objectForKey:@"svrID"] intValue];
    NSString *svrName = [dic objectForKey:@"svrName"];
    NSString *roleName=[dic objectForKey:@"roleName"];
    int vipLv = [[dic objectForKey:@"vipLv"] intValue];
    int coinCnt = [[dic objectForKey:@"coinCount"] intValue];
    NSString *coinName=[dic objectForKey:@"coinName"];
    int roleLv = [[dic objectForKey:@"roleLv"] intValue];
    if(roleID==nil)
    {
        NSLog(@"SDK 获取用户数据 无roleID");
        return nil;
    }
    if(svrName==nil)
    {
        NSLog(@"SDK 获取用户数据 无svrName");
        return nil;
    }
    if(roleName==nil)
    {
        NSLog(@"SDK 获取用户数据 无roleName");
        return nil;
    }

    if(coinName==nil)
    {
        NSLog(@"SDK 获取用户数据 无coinName");
        return nil;
    }
    NSDictionary *upDic = @{JG_ROLE_ID:roleID,
                            JG_SERVER_ID:@(svrID),
                            JG_SERVER_NAME:svrName,
                            JG_ROLE_NAME:roleName,
                            JG_VIP_LEVEL:@(vipLv),
                            JG_PRODUCT_COUNT:@(coinCnt),
                            JG_PRODUCT_NAME:coinName,
                            JG_ROLE_LEVEL:@(roleLv)
                            };
    return (upDic);
}

-(void) onUpdataOnEnterSvr:(const char *)json
{
    id dic = [self getData:json];
    if(dic == nil) return;
    NSLog(@"上传进入服务器时数据:%@",dic);
    [[SDKCenter sharedSDKCenter] uploadUserData:JHonEnterServer userData:dic];
}

-(void) onUpdataOnRoleUpg:(const char *)json
{
    id dic = [self getData:json];
    if(dic == nil)return;
    NSLog(@"上传角色升级时数据:%@",dic);
    [[SDKCenter sharedSDKCenter] uploadUserData:JHonRoleUpdate userData:dic];
}

-(void) onInit
{
    NSLog(@"调用Sdk初始化");
    id center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onInitSuccess:) name:JHonInitSuccess object:nil];
    [center addObserver:self selector:@selector(onInitFailed:) name:JHonInitFailed object:nil];
    [[SDKCenter sharedSDKCenter] initSDKWithAppId:APP_ID withAppKey:APP_KEY];
}

-(void) onLogin
{
    NSLog(@"调用Sdk登陆");
    [[SDKCenter sharedSDKCenter] startLogin];
}

-(void) onInitSuccess:(NSNotification *) notify
{
    NSLog(@"JH_SDK初始化成功");
    UnitySendMessage("Sdk", "InitSuc", " ");
}

-(void) onInitFailed:(NSNotification *) notify
{
    id msg = (NSString *) notify.object;
    NSLog(@"JH_SDK初始化失败,%@",msg);
    [self showDialog:msg title:@"初始化失败,请检查网络后重新启动"];
}

-(void) showDialog:(NSString *) msg title:(NSString *)t
{
    id alert =[UIAlertController alertControllerWithTitle:t message:msg preferredStyle:UIAlertControllerStyleAlert];
    id okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    id win = [[UIApplication sharedApplication] keyWindow];
    if(win==nil) return;
    [[win rootViewController] presentViewController:alert animated:YES completion:nil];
}


void init()
{
    [[Sdk instance] onInit];
}

//登陆
void login()
{
    [[Sdk instance] onLogin];
}

//登出
void logout()
{
    NSLog(@"调用sdk登出");
    [[SDKCenter sharedSDKCenter] userLogout];
}

//支付
void pay(const char* json)
{
    [[Sdk instance] onPay:json];
}

//进入服务器时上传数据
void updataOnEnterSvr(const char *json)
{
    [[Sdk instance] onUpdataOnEnterSvr:json];
}

//角色升级时上传数据
void updataOnRoleUpg(const char *json)
{
    [[Sdk instance] onUpdataOnRoleUpg:json];
}

void setBSUrl(const char *url)
{
    NSString *bsurl = CreateNSString(url);
    [[App instance] setBSUrl:bsurl];
}

//创建NSString
NSString* CreateNSString(const char *str)
{
    if(str)
    {
        return [NSString stringWithUTF8String:str];
    }
    return [NSString stringWithUTF8String:" "];
}

@end
