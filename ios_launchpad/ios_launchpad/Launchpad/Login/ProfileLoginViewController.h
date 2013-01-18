//
//  LoginViewController.h
//  Launchpad
//
//  Verifies user creditials on intial launch of application
//
//  Created by Rich Cowie on 5/23/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileLoginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic,strong) UIButton *loginButton;
@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) UITextField* passwordField;
@property (nonatomic,strong) UITextField* userIdField;

@end
