//
//  CustomButton.h
//  Launchpad
//
//  Generic custom button class
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomButton : UIButton {
    SEL selector;
    NSObject *target;
}

- (void)setHideListener:(NSObject*)_target:(SEL)_selector;

@end
