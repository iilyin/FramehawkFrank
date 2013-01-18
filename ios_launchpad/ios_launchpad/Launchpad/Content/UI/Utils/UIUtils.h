//
//  UIUtils.h
//  Launchpad
//
//  General Utility methods for Launchpad
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIUtils : NSObject

+ (void)formatLoginLabel:(UILabel*)label;

+ (void)layoutKeyboardToolbar:(UIToolbar*)toolbar;
+ (void)layoutKeyboardButton:(UIButton*)button;
+ (void)layoutKeyboardCustomButton:(UIButton*)button;

+ (BOOL)isOrientationAllowed:(UIInterfaceOrientation)interfaceOrientation;

+ (CGSize)viewSize:(UIView*)view;

+ (UIColor*)overlayBacgroundColor;

+ (CGFloat)screenPPI;

@end
