//
//  CustomButton.m
//  Launchpad
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "CustomButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation CustomButton

- (void)dealloc
{
    target = nil;
    selector = nil;
}

- (void)setHideListener:(id)_target:(SEL)_selector
{
    target = _target;
    selector = _selector;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
}

@end
