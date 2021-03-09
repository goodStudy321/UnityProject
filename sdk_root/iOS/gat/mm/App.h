//
//  App.h
//  Unity-iPhone
//
//  Created by 查理 on 2018/11/22.
//

#import <Foundation/Foundation.h>


@interface App : NSObject
//后台地址
@property NSString* BSUrl;

//登录接口
@property NSString* Login;

+(App *) instance;
@end
