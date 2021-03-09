
#define WORK_LOG       @"WORK_LOG" //获取工作日志的通知
#define VERSION_STR    @"1.1.8"   //字符串版本号
#define VERSION_NO     @"118"       //数字版本号，取字符串版本号去掉点

#import <Foundation/Foundation.h>
#import "AdsRole.h"
#import "AdsOrder.h"


@interface AdsManager : NSObject

//初始化接口，需要在app finishLaunch时调用，可以使用Qu_ickS_DK的productCode
+ (void)initWithProductCode:(NSString *)productCode;
//统计登录用户信息,如果没有用户名，username可以填uid
//账号登录成功，不是角色
+ (void)onLogin:(NSString *)uid username:(NSString *)name;
//游戏激活，按需调用，统计游戏激活观察点，不是打开app的设备数
//uid 账号uid，可以为nil
//roleId 角色id，可以为nil
+ (void)onActivationWithUid:(NSString *)uid roleId:(NSString *)roleId;
//进入角色或者角色信息变化时调用
//isCreateRole表示该角色是否为刚刚创建的,默认否
+ (void)updateRoleInfo:(AdsRole *)roleInfo isCreate:(BOOL)isCreateRole;
//统计充值，这里会关联角色信息
+ (void)congziOverInfo:(AdsOrder *)orderInfo roleInfo:(AdsRole *)role;
//创建自定义事件  eventCode为必传
+ (void)onCustEventWithEventCode:(NSString *)eventCode eventParams:(NSString *)eventParams;

@end
