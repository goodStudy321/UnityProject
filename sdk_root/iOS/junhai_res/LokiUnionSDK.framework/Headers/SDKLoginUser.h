//
//  TGLoginUser.h
//  TrigirlsSDK
//
//  Created by Season on 2017/4/14.
//  Copyright © 2017年 junhai. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HHCAPI.h"

@interface SDKLoginUser : NSObject

@property (strong,nonatomic)NSString *uid;
@property (strong,nonatomic)NSString *userName;
@property (strong,nonatomic)NSString *accessToken;

@end
