//
//  UIUtils.m
//  Launchpad
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import "UIUtils.h"

@implementation UIUtils

+(void)formatLoginLabel:(UILabel*)label
{
    label.font = [UIFont boldSystemFontOfSize:15];
    label.backgroundColor = [UIColor clearColor];
}

+ (void)layoutKeyboardToolbar:(UIToolbar*)toolbar
{
    toolbar.tintColor = [UIColor colorWithRed:.23 green:.23 blue:.23 alpha:1];
    toolbar.frame = CGRectMake(0, 0, 1024, 50);
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

+ (void)layoutKeyboardButton:(UIButton*)button
{
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal|UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0, 1);
    button.titleLabel.font = [UIFont systemFontOfSize:18];
}

+ (void)layoutKeyboardCustomButton:(UIButton*)button
{
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal|UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0, 1);
}

+ (BOOL)isOrientationAllowed:(UIInterfaceOrientation)interfaceOrientation 
{
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

+ (CGSize)viewSize:(UIView*)view
{
    CGPoint topLeft = [view convertPoint:CGPointZero toView:nil];
    CGPoint bottomRight = [view convertPoint:CGPointMake(view.frame.size.width, view.frame.size.height) toView:nil];
     return CGSizeMake(fabsf(topLeft.y - bottomRight.y),fabsf(topLeft.x - bottomRight.x));
   // return CGSizeMake(fabsf(topLeft.x - bottomRight.x), fabsf(topLeft.y - bottomRight.y));
}

+ (UIColor*)overlayBacgroundColor
{
    return [UIColor colorWithRed:220./255. green:221./255. blue:222./255. alpha:1.];
}

+ (CGFloat)screenPPI
{
    static CGFloat ppi = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ppi = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 163 : 132;
    });
    
    return ppi;
}

@end
