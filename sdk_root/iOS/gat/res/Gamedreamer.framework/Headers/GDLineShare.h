//
//  GDLineShare.h
//  InternationalSDK_Third
//
//  Created by gd on 4/1/18.
//  Copyright © 2018年 Efunfun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDLineShare : NSObject

/*!
 @method
 
 Line share
 
 @param message share text
 
 */
+ (BOOL)LineShareWithContentMessage:(NSString *)message;

@end
