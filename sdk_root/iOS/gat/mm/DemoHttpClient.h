//
//  DemoHttpClient.h
//  AgentDemo
//
//  Created by 君海小mini on 15/9/2.
//  Copyright (c) 2015年 junhai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sdk.h"

@interface DemoHttpClient : NSObject

+ (DemoHttpClient *)sharedDemoHttpClient;

- (void)send:(Sdk *)viewController method:(NSString *)method url:(NSString *)url parameters:(NSDictionary *)parameters timeout:(float)timeout completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler;

@end
