//
//  AdsRole.h
//  PlayAds
//
//  Created by hjo on 2017/2/15.
//  Copyright © 2017年 hjo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdsRole : NSObject
@property (nonatomic,strong) NSString *uid;//登录的用户uid，如果没有就填角色id
@property (nonatomic,strong) NSString *userName;//登录的用户名，如果没有就填uid
@property (nonatomic,strong) NSString *roleId;//角色Id,如果没有没有就填uid
@property (nonatomic,strong) NSString *roleName; //角色名称，如果没有就填角色Id
@property (nonatomic,assign) int roleLevel; //角色等级,如果没有就不填
@property (nonatomic,strong) NSString *serverName;//服务器名，如果没有就不填
@property (nonatomic,assign) float balance; //虚拟货币余额，如果没有就不填
@property (nonatomic,assign) int vipLevel; //vip等级，如果没有就不填
@property (nonatomic,strong) NSString *partyName; //公会名称，没有就不填
@property (nonatomic,strong) NSString *serverId; //服务器Id

+ (instancetype)roleInfo;
@end
