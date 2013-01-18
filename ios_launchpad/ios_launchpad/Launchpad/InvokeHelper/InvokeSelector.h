//
//  InvokeSelector.h
//  Launchpad
//
//  Utility method to assign customized behavior for buttons
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InvokeSelector : NSObject

+(id)invokeSelector:(SEL)selector onTarget:(NSObject*)target withArgument:(id)argument1, ... NS_REQUIRES_NIL_TERMINATION;

@end
