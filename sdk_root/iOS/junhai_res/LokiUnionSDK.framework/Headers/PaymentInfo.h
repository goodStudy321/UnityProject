//
//  PaymentInfo.h
//  AgentStaticLib
//
//  Created by 君海小mini on 15/9/1.
//  Copyright (c) 2015年 junhai. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef AgentStaticLib_PayMentInfo_h
#define AgentStaticLib_PayMentInfo_h


#endif

/**
 * 商品参数尤为重要，以下是例子
 * 例：充值10元，100钻石
 * productName = @“钻石”;
 * productCount = @"100";
 * payMoney = 1000;
 * rate = 10;
 **/

#import "HHCAPI.h"

@interface PaymentInfo : NSObject<NSCopying>

@property id object;// 用于动态绑定，CP无用
@property (strong) NSString *orderId;//订单号
@property (strong) NSString *productId;//商品ID
@property (strong) NSString *productName;//商品名称
@property (assign) unsigned int productCount;//商品数量
@property (assign) unsigned int payMoney;//总金额，单位为分
@property (assign) unsigned int serverId;//区服id
@property (strong) NSString *serverName;//区服名称
@property (strong) NSString *roleId;//角色id
@property (strong) NSString *roleName;//角色名
@property (assign) unsigned int rate;//兑换比例，即1元可以买多少商品
@property (strong) NSString *paymentDesc;//订单详情信息
@property (strong) NSString *notifyUrl;//充值回调地址
@property (strong) NSString *appleProductId;//苹果后台申请到的商品编码

- (NSDictionary *)toDictionary;

@end
