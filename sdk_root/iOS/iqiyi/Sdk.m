//********************************************************************
// Created by Loong On 2019/7/18 10:12 PM
// Copyright @ 2019 .All rights reserved
//********************************************************************

#import "Sdk.h"
#import "App.h"
#import "DemoHttpClient.h"

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
    if (self = [super init])
    {
        [self setFirstLogin:YES];
        [self setInitOP:0];
    
    }
    return self;
}

-(BOOL) firstLogin
{
    return firstLogin;
}

-(void) setFirstLogin:(BOOL)val
{
    firstLogin = val;
}
-(void) Init
{
    if ([[GameSDK sharedInstance] initGameSDK:@"9359"] == YES)
    {
        NSString* qid=@"34332149671935388566576975199762";
        [[GameSDK sharedInstance] initQKAdWithProductCode:qid];
        [[GameSDK sharedInstance] enableBaiduAndSinaLogin:NO];
        [self setInitOP:1];
        UnitySendMessage(SDK, "InitSuc", " ");
    }
    else
    {
        [self setInitOP:2];
        UnitySendMessage(SDK, "InitFail", " ");
        NSString *msg = @"网络出现异常,请检查你的Wifi,3G/4G连接是否正常?";
        NSString *title = @"网络出现异常";
        [self ShowInitFail:msg title:title];
    }
}

-(int) OnLogin
{
    id view = UnityGetGLViewController();
    GameOpenSDKAPICallResult result = GameOpenSDKAPICallSuccess;
    if ([self firstLogin] == YES)
    {
        result = [[GameSDK sharedInstance] autoLogin:view delegate:self];
    }
    else
    {
        result = [[GameSDK sharedInstance] accountLogin:view delegate:self];
    }
    NSLog(@"SDK OnLoing call result:%d, firstLogin:%d", result, [self firstLogin]);
    return result;
}


-(int) OnLogout
{
    GameOpenSDKAPICallResult result = [[GameSDK sharedInstance] userLogout:self];
    return result;
}

-(int) OnShowFloat:(int)x ht:(int)y
{
    CGPoint point = CGPointMake(x, y);
    GameOpenSDKAPICallResult result = [[GameSDK sharedInstance] showFloatWithPoint:point];
    NSLog(@"SDK show float at point:{%d, %d}, result:%d",x,y, result);
    return result;
}

-(int) OnHideFloat
{
    GameOpenSDKAPICallResult result = [[GameSDK sharedInstance] hideFloat];
    NSLog(@"SDK hideFloat result:%d", result);
    return result;
}

-(void) loginSuccess:(NSDictionary *)loginUser
{
    NSString *msg = [self ToJson:loginUser];
    NSLog(@"SDK Login Suc:%@", msg);
    //sign = md5(uid + "&" + time + "&" + key);
    //NSString* uid = [[loginUser objectForKey:@"uid"] stringValue];
    //NSString* time = [[loginUser objectForKey:@"time"] stringValue];
    
    [[DemoHttpClient sharedDemoHttpClient] send:self method:@"GET" url:LOGIN_URL parameters:loginUser timeout:10.0 completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        if (err) {
            NSLog(@"SDK Login suc,but two verify err:%@",[err localizedDescription]);
            UnitySendMessage(SDK, "LoginFail", " ");
        }
        else
        {
            NSInteger code = [(NSHTTPURLResponse *)response statusCode];
            if (code == 200)
            {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                NSDictionary *statusDic = dic[@"status"];
                int rightCode = [[statusDic objectForKey:@"code"] intValue];
                if (rightCode == 10200)
                {
                    NSLog(@"SDK Login Suc and two verify suc");
                    const char *str = [msg UTF8String];
                    UnitySendMessage(SDK, "LoginSuc", str);
                }
                else
                {
                    NSLog(@"SDK Login suc,but two verify Fail:%@",dic);
                     UnitySendMessage(SDK, "LoginFail", " ");
                }
            }
            else
            {
                NSString *str = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"SDK Login suc,but two verify code:%d, response:%@",(int)code,str);
                UnitySendMessage(SDK, "LoginFail", " ");
            }
        }
    }];
    
}

-(void) loginFail:(LoginErrorCode)errorCode msg:(NSString *)msg
{
    if ([self firstLogin] == YES)
    {
        [self setFirstLogin:NO];
        
        if (errorCode == LoginErrorAutoLoginDisable)
        {
            id view = UnityGetGLViewController();
            NSLog(@"SDK FirstLogin Fail, Call accountLogin");
            [[GameSDK sharedInstance] accountLogin:view delegate:self];
        }
        else
        {
            int code = errorCode;
            NSLog(@"SDK FirstLogin Fail, errCode:%d", code);
            UnitySendMessage(SDK, "LoginFail", " ");
        }
    }
    else
    {
        int code =  errorCode;
        NSLog(@"SDK Login Fail, errorCode:%d, msg:%@", code, msg);
        NSString *codeStr = [NSString stringWithFormat:@"%d", code];
        const char * str = [codeStr UTF8String];
        UnitySendMessage(SDK, "LoginFail", str);
    }
}

-(void) logoutSuccess:(NSDictionary *)data
{
    NSString *msg = [self ToJson:data];
    NSLog(@"SDK Logout Suc:%@",msg);
    const char *str = [msg UTF8String];
    UnitySendMessage(SDK, "LogoutSuc", str);
}

-(void) bindPhoneSuccess:(NSDictionary *)data
{
    NSString *msg = [self ToJson:data];
    NSLog(@"SDK bindPhoneSuc:%@",msg);
    const char *str = [msg UTF8String];
    UnitySendMessage(SDK, "BindPhoneSuc", str);
}

-(void) bindPhoneFail:(NSInteger)errorCode msg:(NSString *)msg
{
    NSLog(@"SDK Login Fail, errorCode:%ld, msg:%@", (long)errorCode, msg);
    NSString *codeStr = [NSString stringWithFormat:@"%ld", (long)errorCode];
    const char * str = [codeStr UTF8String];
    UnitySendMessage(SDK, "BindPhoneFail", str);
}

-(void) didReceivedBindingMessage:(NSDictionary *)data
{
    NSLog(@"SDK didReceivedBindingMessage:%@", data);
    NSString *nsStr = [self ToJson:data];
    const char *str = [nsStr UTF8String];
    UnitySendMessage(SDK, "DidBindMessage", str);
    
}

-(int) OnPay:(const char *)json
{
    NSDictionary* dic = [self ToDicFromJson:json];
    NSLog(@"SDK payData:%@", dic);
    
    id view = UnityGetGLViewController();
    NSString *svrID = [dic objectForKey:@"svrID"];
    NSString *roleID = [dic objectForKey:@"roleID"];
    int price = [[dic objectForKey:@"money"] intValue];
    NSString * proID = [dic objectForKey:@"proID"];
    NSString * ordID = [dic objectForKey:@"ordID"];
    NSString * devInfo = [dic objectForKey:@"devInfo"];
    GameOpenSDKAPICallResult result = [[GameSDK sharedInstance] userPayment:view serverId:svrID roleId:roleID productPrice:price productId:proID orderId:ordID developerInfo:devInfo delegate:self];
    return result;
}

-(void) purchaseSuccess:(NSDictionary *)purchase
{
    NSLog(@"SDK pay suc:%@",purchase);
    UnitySendMessage(SDK, "PaySuc", " ");
}

-(void) purchaseFail:(NSString *)msg
{
    NSLog(@"SDK pay fail:%@", msg);
    UnitySendMessage(SDK, "PayFail", "");
}

-(int) OnUpdataOnRoleCreate:(const char *)svrID
{
    id view = UnityGetGLViewController();
    NSString *svr = CreateNSString(svrID);
    NSLog(@"SDK updata on roleCreate:%@", svr);
    return [[GameSDK sharedInstance] createRole:view serverId:svr];
}

-(int) OnUpdataOnSceneEnter:(const char *)svrID
{
    id view = UnityGetGLViewController();
    NSString *svr = CreateNSString(svrID);
    NSLog(@"SDK updata on enterGame:%@", svr);
    return [[GameSDK sharedInstance] enterGame:view serverId:svr];
}

-(void) OnNotifyBind:(const char *)json
{
    NSDictionary *dic = [self ToDicFromJson:json];
    NSLog(@"SDK onNotifyBind:%@", dic);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NOTIFICATION_BING_PHONE_RESULT" object:nil userInfo:dic];
}
-(int) OnBindPhone
{
    id view = UnityGetGLViewController();
    return [[GameSDK sharedInstance] bindPhone:view delegate:self];
}

-(int) initOP
{
    return initOp;
}

-(void) setInitOP:(int)op
{
    initOp = op;
    NSLog(@"SDK setInitOp:%d",initOp);
}

-(const char *) GetStr:(int) val
{
    NSString*  str= [NSString stringWithFormat:@"%d", val];
    return [str UTF8String];
}

int Login()
{
    return [[Sdk instance] OnLogin];
}

int Logout()
{
    return [[Sdk instance] OnLogout];
}

int Pay(const char *json)
{
    return [[Sdk instance] OnPay:json];
}

int UpdataOnRoleCreate(const char *svrID)
{
    return [[Sdk instance] OnUpdataOnRoleCreate:svrID];
}

int UpdataOnSceneEnter(const char *svrID)
{
    return [[Sdk instance] OnUpdataOnSceneEnter:svrID];
}

void NotifyBind(const char *json)
{
    [[Sdk instance] OnNotifyBind:json];
}

void SetBSUrl(const char *url)
{
    NSString *bsurl = CreateNSString(url);
    [[App instance] setBSUrl:bsurl];
}

int GetInitOP()
{
    return [[Sdk instance] initOP];
}


int ShowFloat(int x, int y)
{
   return [[Sdk instance] OnShowFloat:x ht:y];
}

int HideFloat()
{
    return [[Sdk instance] OnHideFloat];
}

int BindPhone()
{
    return [[Sdk instance] OnBindPhone];
}



-(NSString*) ToJson:(id)obj
{
    NSData *data  = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return str;
}

-(NSDictionary*) ToDicFromJson:(const char *)str
{
    NSString *jStr = CreateNSString(str);
    NSLog(@"SDK Json data:%@",jStr);
    NSData *data = [jStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    return dic;
}

NSString* CreateNSString(const char* str)
{
    if(str)
    {
        return [NSString stringWithUTF8String:str];
    }
    return [NSString stringWithUTF8String:" "];
}

-(void) ShowInitFail:(NSString*) msg title:(NSString*) t
{
    id win = UnityGetGLViewController();
    id alter = [UIAlertController alertControllerWithTitle:t message:msg preferredStyle:UIAlertControllerStyleAlert];
    id okAction = [UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        abort();
    }];
    [alter addAction:okAction];
    [[win rootViewController] presentViewController:alter animated:YES completion:nil];
}
@end
