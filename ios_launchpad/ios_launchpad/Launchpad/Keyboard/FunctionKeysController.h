//
//  FunctionKeysViewController.h
//  Launchpad
//
//  Handles Function keys for toolbar
//
//  Created by Rich Cowie on 6/13/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomKeyButton.h"

@protocol FunctionKeyDelegate <NSObject>
- (void) customKeyAction:(CustomKeyButton*) button;
@end


@interface FunctionKeysController : UIViewController

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *functionKeys;
@property (assign) id<FunctionKeyDelegate> functionKeyDelegate;

@end
