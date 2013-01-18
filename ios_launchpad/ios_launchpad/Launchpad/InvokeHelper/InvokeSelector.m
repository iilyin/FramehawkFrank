//
//  InvokeSelector.h
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "InvokeSelector.h"

@implementation InvokeSelector

+(id)invokeSelector:(SEL)selector onTarget:(NSObject*)target withArgument:(id)argument, ...
{
    if([target respondsToSelector:selector])
    {
        @try {
            NSMethodSignature *signature = [target methodSignatureForSelector:selector];
            
            // initialize invocation object with given selector and target
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = selector;
            invocation.target = target;
            
            // fill in invocation parameters from arguments passed
            // nil value indicates end of the arguments list 
            if (argument != nil)
            {
                if (![argument isKindOfClass:[NSNull class]])
                    [invocation setArgument:&argument atIndex:2];
                
                va_list args;
                va_start(args, argument);
                
                id param = nil;
                int argInd = 3;
                
                while ((param = va_arg(args, id)) != nil)
                    if (![argument isKindOfClass:[NSNull class]])
                        [invocation setArgument:&param atIndex:argInd++];
                
                va_end(args);
            }
            
            // invoke target
            [invocation invoke];
            
            // check whether target should return a value
            if (signature.methodReturnLength != 0)
            {
                // if yes, get return value from the invocation object and return it 
                void *result = nil;
                [invocation getReturnValue:&result];
                // return value as is, without any retain
                return (__bridge id)result;
            }
            else
                return nil;
        }
        @catch (NSException *exception) {
            DLog(@"Exception in file %s, libe %d: %@", __FILE__, __LINE__, exception);
        }
        
    }
    else
    {
        DLog(@"Target %@ does not respond to selector %@", target, NSStringFromSelector(selector));
    }
    
    return nil;
};

@end
