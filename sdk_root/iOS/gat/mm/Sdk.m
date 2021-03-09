//********************************************************************
// Created by Loong On 2019/7/18 10:12 PM
// Copyright @ 2019 .All rights reserved
// 晶绮港澳台
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
       
        [self setInitOP:0];
    
    }
    return self;
}


-(void) Init:(UIApplication *) application options:(nonnull NSDictionary *)opts
{
    [[GamedreamerManager shareInstance] gamedreamerStartWithSuperView:nil andCompletion:^(NSDictionary *result, NSError *error){
        NSLog(@"SDK init result:%@ , error:%@", result, error);
        if(error)
        {
            [self SendInitFail];
        }
        else
        {
            [self SendInitSuc];
        }
    }];
    
    //应用委托实现--必需加入
    [[GamedreamerManager shareInstance] application:application didFinishLaunchingWithOptions:opts];
    //SDK委托实现--必需加入处理
    [GamedreamerManager shareInstance].delegate = self;
}

//SDK委托实现--必需加入
- (void)gamedreamerNeedRelogin{
    NSLog(@"SDK session过期,登出");
    [self SendNeedRelogin];
}

-(UIView*) GetUIView
{
    //TODO
    return nil;
    //return GetAppController().unityView;
}

-(void) OnLogin
{
    UIView* view = [self GetUIView];
    [[GamedreamerManager shareInstance] gamedreamerLoginWithSuperView:view andCompletion:^(NSDictionary *userInfo, NSError *error) {
        if (error) {
            NSLog(@"SDK login err:%@", error);
            [self SendLoginFail];
        }
        else
        {
            NSString* LOGIN_URL = [[App instance] Login];
            //NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:userInfo];
            //[dic setValue:@"zh-hk" forKeyPath:@"lang"];
            NSString* kID = @"sessionid";
            NSString* kToken = @"token";
            NSString* kUid = @"userid";
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:[userInfo objectForKey:kID], kID,[userInfo objectForKey:kToken],kToken,[userInfo objectForKey:kUid],kUid,@"zh-hk",@"lang", nil];
            NSLog(@"SDK login suc result:%@, ready verify!, dic:%@", userInfo, dic);
            [[DemoHttpClient sharedDemoHttpClient] send:self method:@"GET" url:LOGIN_URL parameters:dic timeout:10.0 completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
                if (err) {
                    NSLog(@"SDK Login suc,but two verify err:%@",[err localizedDescription]);
                    [self SendLoginFail];
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
                            NSString *msg = [self ToJson:userInfo];
                            NSLog(@"SDK Login Suc and two verify suc:%@", msg);
                            const char *str = [msg UTF8String];
                            [self SendLoginSuc:str];
                        }
                        else
                        {
                            NSLog(@"SDK Login suc,but two verify Fail:%@",dic);
                            [self SendLoginFail];
                        }
                    }
                    else
                    {
                        NSString *str = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                        NSLog(@"SDK Login suc,but two verify code:%d, response:%@",(int)code,str);
                        [self SendLoginFail];
                    }
                }
            }];
        }
    }];
}




-(void) OnLogout
{
    [[GamedreamerManager shareInstance] gamedreamerLogout];
    [self SendLogoutSuc];
}



-(void) OnShowToolBar:(int)place
{
    
}

-(void) OnHideToolBar
{
    
}


-(void) logoutSuccess:(NSDictionary *)data
{
    NSString *msg = [self ToJson:data];
    NSLog(@"SDK Logout Suc:%@",msg);
    const char *str = [msg UTF8String];
    UnitySendMessage(SDK, "LogoutSuc", str);
}


-(void) OnPay:(const char *)json
{
    NSString* proID = CreateNSString(json);
    NSLog(@"SDK pay proID:%@",proID);
    [[GamedreamerManager shareInstance] gamedreamerStoreWithProItemid:proID andCompletion:^(NSDictionary *result, NSError *error) {
        if(error){
            NSLog(@"SDK pay fail, err:%@", error);
            [self SendPayFail];
        }else{
            NSLog(@"SDK pay suc,%@",result);
            int code =[[result objectForKey:@"code"] intValue];
            if(code == 1000){
                //儲值成功
                [self SendPaySuc];
            } else {
                //儲值失敗
                NSLog(@"SDK pay fail ,code:%d", code);
                [self SendPayFail];
            }
        }
    }];
}



-(void) OnCheckSvr:(const char *)svrID
{
    NSString* str = CreateNSString(svrID);
    [[GamedreamerManager shareInstance] gamedreamerCheckServerWithServerId:str andCompletion:^(NSDictionary *userInfo, NSError *error){
        if(error)
        {
            NSLog(@"SDK checkSvr err:%@", error);
            [self SendCheckSvrFail];
        }else{
            //返回参数有可能和登录接口不一样，请以这个接口返回参数为准
            NSString *msg = [self ToJson:userInfo];
            NSLog(@"SDK checkSvr suc, userInfo:%@, msg:%@", userInfo, msg);
            const char *str = [msg UTF8String];
            [self SendCheckSvrSuc:str];
        }
    }];
}

-(void) OnRoleCreate:(const char *)roleName roleID:(nonnull const char *)roleid
{
    NSString* role_Name = CreateNSString(roleName);
    NSString* role_ID = CreateNSString(roleid);
    NSLog(@"Sdk OnRoleCreate name:%@, id:%@", role_Name, role_ID);
    [[GamedreamerManager shareInstance] gamedreamerNewRoleName:role_Name andRoleId:role_ID];
}

-(void) OnRoleSelect:(const char *)roleName roleID:(nonnull const char *)roleid lv:(nonnull const char *)rolelv
{
    NSString* role_Name = CreateNSString(roleName);
    NSString* role_ID = CreateNSString(roleid);
    NSString* lv = CreateNSString(rolelv);
    NSLog(@"Sdk OnRoleSelect name:%@, id:%@, lv:%@", role_Name, role_ID, lv);
    [[GamedreamerManager shareInstance] gamedreamerSaveRoleName:role_Name andRoleId:role_ID andRoleLevel:lv];
}

-(void) OnBegGame
{
    [[GamedreamerManager shareInstance] gamedreamerStartGameForEventRecorded];
}

-(void) OnUserCenter
{
    UIView* view = [self GetUIView];
    [[GamedreamerManager shareInstance] gamedreamerMemberCenterWithSuperView:view];
}

-(void) OnKefu
{
    [[GamedreamerManager shareInstance] gamedreamerCsWithSuperView:[UIApplication sharedApplication].keyWindow];
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

-(void) OnShareFbLink:(const char *)link
{
    NSString* str = CreateNSString(link);
    [[GDFacebookShare shareInstance] gamedreamerFacebookShareFrom:[UIApplication sharedApplication].keyWindow.rootViewController Link:str complete:^(BOOL shareResult) {
        NSLog(@"SDK share %@,result:%@", str, shareResult?@"suc":@"fail");
        if (shareResult==YES) {
            [self SendShareFbLink:"1"];
        }
        else
        {
            [self SendShareFbLink:"0"];
        }
    }];
}

-(void) OnShareFbTex:(const char *)persist streaming:(const char*)streamingPath name:(const char*) fileName;
{

    NSString* persistDir = CreateNSString(persist);
    NSString* streamingdir = CreateNSString(streamingPath);
    NSString* fn = CreateNSString(fileName);
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@", persistDir, fn];
    NSLog(@"SDK share tex, persist:%@, streaming:%@, name:%@, full:%@", persistDir,streamingdir, fn, fullPath);
    
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:fullPath]) {
        NSLog(@"SDK share tex, %@ not exist", fullPath);
        [self SendShareFbTex:"5"];
        return;
    }
    UIImage* image = [UIImage imageWithContentsOfFile:fullPath];
    [[GDFacebookShare shareInstance] gamedreamerNewFacebookShare:[UIApplication sharedApplication].keyWindow.rootViewController LocalImage:image completion:^(GDShareType shareResult) {
        NSLog(@"SDK share %@,result:%d", fullPath, (int)shareResult);
        if (shareResult==GDShareTypeSuccess) {
            [self SendShareFbTex:"1"];
        }
        else if (shareResult == GDShareTypeNoapp)
        {
            [self SendShareFbTex:"2"];
        }
        else if (shareResult == GDShareTypeCancel)
        {
            [self SendShareFbTex:"3"];
        }
        else
        {
            [self SendShareFbTex:"0"];
        }
    }];
}

-(void) OnLogEvent:(const char*)name
{
    NSString *en = CreateNSString(name);
    [[GamedreamerManager shareInstance] gamedreamerLogEventWithName:en parameters:nil];
}

-(void) OnLogEvent1:(const char*)name valName:(const char*) vn val:(const char*) val
{
    NSString *en = CreateNSString(name);
    NSString* k = CreateNSString(vn);
    NSString* v = CreateNSString(val);
    NSDictionary<NSString*, NSObject*>* dic = [NSDictionary<NSString*, NSObject*> dictionaryWithObject:v forKey:k];
    [[GamedreamerManager shareInstance] gamedreamerLogEventWithName:en parameters:dic];
}

void Login()
{
    [[Sdk instance] OnLogin];
}

void Logout()
{
    [[Sdk instance] OnLogout];
}

void Pay(const char *json)
{
    [[Sdk instance] OnPay:json];
}

void CheckSvr(const char* svrID)
{
    [[Sdk instance] OnCheckSvr:svrID];
}


void UploadRoleCreate(const char *roleName, const char*roleID)
{
    [[Sdk instance] OnRoleCreate:roleName roleID:roleID];
}

void UploadRoleSelect(const char *roleName, const char*roleID, const char*lv)
{
    [[Sdk instance] OnRoleSelect:roleName roleID:roleID lv:lv];
}

void UploadBegGame()
{
    [[Sdk instance] OnBegGame];
}

void UserCenter()
{
    [[Sdk instance] OnUserCenter];
}

extern void SetBSUrl(const char *url, const char* login)
{
    NSString *bsurl = CreateNSString(url);
    NSString *loginUrl = CreateNSString(login);
    [[App instance] setBSUrl:bsurl];
    [[App instance] setLogin:loginUrl];
}

int GetInitOP()
{
    return [[Sdk instance] initOP];
}


void ShowToolBar(int place)
{
    [[Sdk instance] OnShowToolBar:place];
}

void HideToolBar()
{
    [[Sdk instance] OnHideToolBar];
}

void ShareFbLink(const char *link)
{
    [[Sdk instance] OnShareFbLink:link];
}

void ShareFbTex(const char *persist, const char* streaming, const char* name)
{
    [[Sdk instance] OnShareFbTex:persist streaming:streaming name:name];
}

void LogEvent(const char* name)
{
    [[Sdk instance] OnLogEvent:name];
}

void LogEvent1(const char* name, const char* varName, const char* val)
{
    [[Sdk instance] OnLogEvent1:name valName:varName val:val];
}

void Kefu()
{
    [[Sdk instance] OnKefu];
}

-(void) Send:(const char *)method msg:(const char *)msg
{
    UnitySendMessage(SDK, method, msg);
}

-(void) SendInitSuc
{
    [self setInitOP:1];
    [self Send:"InitSuc" msg:" "];
}

-(void) SendInitFail
{
    [self setInitOP:2];
    [self Send:"InitFail" msg:" "];
}

-(void) SendLoginSuc:(const char*) msg
{
    [self Send:"LoginSuc" msg:msg];
}
-(void) SendLoginFail
{
    [self Send:"LoginFail" msg:" "];
}

-(void) SendCheckSvrFail
{
    [self Send:"CheckSvrFail" msg:" "];
}
-(void) SendCheckSvrSuc:(const char*)msg
{
    [self Send:"CheckSvrSuc" msg:msg];
}


-(void) SendPaySuc
{
    NSLog(@"SDK pay suc");
    [self Send:"PaySuc"  msg:" "];
}
-(void) SendPayFail
{
    [self Send:"PayFail" msg:" "];
}

-(void) SendLogoutSuc
{
    [self Send:"LogoutSuc"  msg:" "];
}
-(void) SendLogoutFail
{
    [self Send:"LogoutFail"  msg:" "];
}

-(void) SendNeedRelogin
{
    [self Send:"NeedRelogin"  msg:" "];
}

-(void) SendShareFbLink:(const char*) msg
{
    [self Send:"FBShareLink"  msg:msg];
}


-(void) SendShareFbTex:(const char*) msg
{
    [self Send:"FBShareTex"  msg:msg];
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
