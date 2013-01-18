//
//  LoginAssistantManager.h
//  Launchpad
//
//  Manager for handling Login Assistant functionality
//
//  Created by Rich Cowie on 10/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginAssistantCredentialsView.h"
#import "SessionManager.h"

/**
 * Login Assistant Delegate protocol
 */
@protocol LoginAssistantDelegate <NSObject>

- (void)loginAssistantAutoLoginStarted;
- (void)loginAssistantAutoLoginEnded;
- (void)autologinHasBeenPerformed;

@optional
- (CGPoint)loginAssistantButtonEndPosition;

@required
//- (void) keyboardMustAppear;
- (void) loginAssistantAnimationWillBegin;
- (void) loginAssistantAnimationCompleted;

@end

/**
 * Login Assistant Manager interface
 */
@interface LoginAssistantManager : NSObject <LoginAssistantViewDelegate, UIGestureRecognizerDelegate>
{
    // view that login assistant is attached to
    UIView *viewForLoginAssistant;

    // login credentials view (username & password)
    LoginAssistantCredentialsView *credentialsView;

    // login assistant dialog view
    UIView *loginAssistantView;
    // login assistant log me in button
    BlinkingButton *loginAssistantLogMeInButton;
    // login assistant dismiss button
    BlinkingButton *loginAssistantDismissButton;
    
    // timer for callback that login assistant animation will begin
    NSTimer *timerForCallBack;
    // timer for starting dismiss login assistant dialog
    NSTimer *timerForAnimation;
    
    // login assistant delegate
    id <LoginAssistantDelegate> __weak loginAssistantDelegate;

    // seconds
    double secondsForCallBack;
}

@property (nonatomic, strong) UIView *viewForLoginAssistant;
@property (nonatomic, weak) id <LoginAssistantDelegate> loginAssistantDelegate;
@property (atomic,strong) SessionKey sessionKey;
@property (nonatomic, strong) BlinkingButton *loginAssistantLogMeInButton;
@property (nonatomic, strong) BlinkingButton *loginAssistantDismissButton;

+ (LoginAssistantManager *) manager;
- (void) performLoginAssistantStartForView: (UIView *) view withSecondsForCallBack: (double) seconds;
- (void) performLoginAssistantForView:(UIView *)view;
- (void) dismissLoginAssistantDialogs;
- (void) assignLoginAssistantDelegate: (id) theLoginAssistantDelegate;

@end
