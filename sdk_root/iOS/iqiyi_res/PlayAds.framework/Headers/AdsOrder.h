//
//  PlayAdsOderInfo.h
//  PlayAds
//
//  Created by hjo on 2017/2/15.
//  Copyright © 2017年 hjo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdsOrder : NSObject
@property (nonatomic,strong) NSString *orderNo; //订单号
@property (nonatomic,strong) NSString *goodsId; //商品Id，商品编号
@property (nonatomic,strong) NSString *goodsName; //商品名称
@property (nonatomic,assign) float amount;         //总金额
@property (nonatomic,strong) NSString *currency;//币种，如CNY，USD
+(instancetype)orderInfo;
@end
