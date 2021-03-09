//
//  GameSDKDef.h
//  GameSDK
//
//  Created by iqiyi on 2018/1/19.
//  Copyright © 2018年 iqiyigame. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef __GAMESDKDEF_H__
#define __GAMESDKDEF_H__

typedef enum
{
    GameOpenSDKAPICallSuccess = 0,                        //成功
    GameOpenSDKAPICallErrorUnknown,                       //未知错误
    GameOpenSDKAPICallErrorReLogin,                       //重复登录
    GameOpenSDKAPICallErrorUnLogin,                       //未登录
    GameOpenSDKAPICallErrorNetwork,                       //网络未连接
    GameOpenSDKAPICallErrorPurchaseUnFinish,              //上一次订单未完成
    GameOpenSDKAPICallErrorParams,                        //参数错误
    GameOpenSDKAPICallErrorQQOAuthNotSurpport,            //QQ授权登录不支持
    GameOpenSDKAPICallErrorWXAuthNotSurpport,             //微信授权登录不支持
    GameOpenSDKAPICallErrorQYAuthNotSurpport,             //爱奇艺授权登录不支持
    GameOpenSDKAPICallErrorReBindPhone,                   //已绑定手机

} GameOpenSDKAPICallResult;

#endif
