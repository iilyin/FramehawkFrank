//
//  LoginAssistantCredentialsView.h
//  Launchpad
//
//  View for entering Login Assistant Credentials
//
//  Created by Rich Cowie on 10/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlinkingButton.h"

@protocol LoginAssistantViewDelegate;

@interface LoginAssistantCredentialsView : UIView/* <UITextFieldDelegate>*/
{
    // login assistant view delegate
    id <LoginAssistantViewDelegate>  __weak delegate;

    // login assistant background color
    UIColor *colorForBackground;
    
    // Login assistant title
    UILabel *title;
    // Login assistant instruction label
    UILabel *instructionLabel;

    // Table for user credentials (username & password)
    UITableView *tableForCredentials;
    
    // background image view
    UIImageView *backgroundView;
    // user name text field
    UITextField *textFieldForName;
    // password text field
    UITextField *textFieldForPassword;
    
    // Do not show again check button
    UIButton *doNotShowCheck;
    // Login Assistant dialog OK button
    BlinkingButton *OKButton;
    // Login Assistant dialog Cancel button
    BlinkingButton *cancelButton;

    // Allow resign keyboard
    BOOL allowResign;
}

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) UIColor *colorForBackground;

@property (nonatomic, strong) UILabel *instructionLabel;
@property (nonatomic, strong) UITableView *tableForCredentials;

@property (nonatomic, strong) UITextField *textFieldForName;
@property (nonatomic, strong) UITextField *textFieldForPassword;

@property (nonatomic, strong) UIButton *doNotShowCheck;

@property (nonatomic, strong) BlinkingButton *OKButton;
@property (nonatomic, strong) BlinkingButton *cancelButton;


- (IBAction) OKButtonTouched:(id)sender;
- (IBAction) CancelButtonTouched:(id)sender;
- (void) setupTitleForCurrentSession;

@end

@protocol LoginAssistantViewDelegate <NSObject>

//@required
- (void) OKButtonPressedForView: (LoginAssistantCredentialsView *) view;
- (void) CancelButtonPressedForView: (LoginAssistantCredentialsView *) view withOption: (BOOL) hideLoginView;

@end
