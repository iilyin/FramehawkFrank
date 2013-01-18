//
//  BrowserServiceViewController.h
//  Framehawk
//
//  Browser view controler for Framehawk Session
//
//  Created by Hursh Prasad on 4/19/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardController.h"

@interface BrowserServiceViewController : KeyboardController<UIWebViewDelegate>
@property (weak,nonatomic) NSString *command;
@property (weak,nonatomic) NSString *search;
@property (strong,nonatomic) UIViewController *submenu;
-(void)browseToURL:(NSString *)url forCommand:(NSString *)objCommand;
-(void)browseToURL;
-(void)addSubmenu:(UIViewController *)submenucontroller;
@end