//
//  FunctionKeyDelegate.h
//  Launchpad
//
//  Toolbar function keys delegate class
//
//  Created by Rich on 6/19/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomKeyButton.h"

@protocol FunctionKeyDelegate <NSObject>
- (void)customKeyAction:(CustomKeyButton*)button;

@end
