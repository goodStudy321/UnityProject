//
//  GamePaymentDelegate.h
//  QYGSDKLib
//
//  Created by iqiyi on 2018/3/30.
//  Copyright © 2018年 iqiyigame. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark GamePurchaseDelegate


/**
 * \brief 处理支付结果的回调协议
 */
@protocol GamePurchaseDelegate

/**
 * 处理支付成功结果
 * 处理支付成功结果，登录成功返回的用户信息如下：
 *               | 字段名称        | 类型    | 描述                                   |
 *               | ------------- | ------- | ----------------                      |
 *               | uid           |  string | 爱奇艺平台用户ID                         |
 *               | productPrice  |  string | 商品价格                                |
 *               | productId     |  string | 商品ID                                 |
  *              | orderId       |  string | 透传调用支付接口时传入的订单ID              |
 *               | developerInfo |  string | 透传调用支付接口时传入的developerInfo      |
 */
@required
-(void) purchaseSuccess:(NSDictionary *) purchase;

/**
 * 处理支付失败结果

 @param msg 失败信息
 */
@required
-(void) purchaseFail:(NSString *) msg;
@end

#pragma mark -
#pragma mark GameRestoreDelegate
/**
 * \brief  处理恢复非消耗品的回调协议
 */
@protocol GameRestoreDelegate

/**
 * 处理恢复成功结果，restoredProducts字典包含字段如下：
 *
 *               | 字段名称            | 类型    | 描述                                   |
 *               | ----------------- | ------- | ----------------                      |
 *               | uid               |  string | 爱奇艺平台用户ID                         |
 *               | isRestored        |  string | 是否为恢复商品，值为true                  |
 *               | restoredProductId | NSArray | 恢复的商品列表，字符串数组                 |
 */
@required
-(void) restoredSuccess:(NSDictionary *) restoredProducts;

/**
 * 处理恢复失败结果

 @param msg 失败信息
 */
@required
-(void) restoredFail:(NSString *) msg;
@end
