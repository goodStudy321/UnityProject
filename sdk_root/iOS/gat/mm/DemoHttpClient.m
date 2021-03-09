//
//  DemoHttpClient.m
//  AgentDemo
//
//  Created by 君海小mini on 15/9/2.
//  Copyright (c) 2015年 junhai. All rights reserved.
//

#import "App.h"
#import <UIKit/UIKit.h>
#import "DemoHttpClient.h"

@implementation DemoHttpClient

+ (DemoHttpClient *) sharedDemoHttpClient{
    static DemoHttpClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DemoHttpClient alloc] init];
    });
    return instance;
}

- (void)send:(Sdk *)viewController method:(NSString *)method url:(NSString *)url parameters:(NSDictionary *)parameters timeout:(float)timeout completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
        NSEnumerator *enumerator = [parameters keyEnumerator];
    
    NSMutableArray *paramArr = [[NSMutableArray alloc] init];
    id key;
    while (key = [enumerator nextObject]) {
        NSString * val = @"";
        if ([[parameters objectForKey:key] isKindOfClass:[NSString class]]){
            val = [DemoHttpClient encodeString:[parameters objectForKey:key]];
        }else{
            val = [parameters objectForKey:key];
        }
        [paramArr addObject:[NSString stringWithFormat:@"%@=%@", key, val]];
    }
    NSString *paramStr = [paramArr componentsJoinedByString:@"&"];
    NSString *SERVER_URL = [[App instance] BSUrl];
    NSString *responseStr = [SERVER_URL stringByAppendingString:url];
    if ([method isEqualToString:@"GET"]) {
        responseStr = [[responseStr stringByAppendingString:@"?"] stringByAppendingString:paramStr];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:responseStr]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:timeout];
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"POST"]) {
        [request setHTTPBody:[paramStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
        handler(response, data, connectionError);
    }];
}

+ (NSString *)encodeString:(NSString*)unencodedString
{
    // CharactersToBeEscaped = @":/?&=;+!@#$()~',*";
    // CharactersToLeaveUnescaped = @"[].";
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)unencodedString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
    return encodedString;
}


@end
