//
//  App.m
//  Unity-iPhone
//
//  Created by 查理 on 2018/11/22.
//

#import "App.h"

@implementation App
@synthesize BSUrl;
@synthesize Login;

+(id) instance
{
    static App * instance = nil;
    if (instance==nil)
    {
        @synchronized(self)
        {
            if(instance==nil)
            {
                instance = [[self alloc] init];
            }
        }
    }
    return (instance);
}


@end
