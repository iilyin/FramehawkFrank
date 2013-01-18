//
//  LoginAssistantManager.m
//  Launchpad
//
//  Manager for handling Login Assistant functionality
//
//  Created by Rich Cowie on 10/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "LoginAssistantManager.h"
#import "LoginAssistantCredentialsView.h"
#import "FHServiceViewController.h"
#import "SessionManager.h"
#import "ProfileDefines.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"
#import "MenuCommands.h"

// Time (in seconds) that login assistant dialog will remain onscreen before dismissing
static const CGFloat TIME_LOGIN_ASSISTANT_DIALOG_REMAINS_ONSCREEN   =   10.0f;

// Login Assistant layout dimensions
static const CGFloat kLoginAssistantButtonWidth         = 140.0f;
static const CGFloat kLoginAssistantButtonHeight        = 40.0f;
static const CGFloat kLoginAssistantButtonMargin        = 14.0f;
static const CGFloat kLoginAssistantButtonCornerRadius  = 10.0;

// Left inset so "Log Me In" text doesn't overlap gutton graphic
static const CGFloat logMeInButtonTitleLeftInset     = 30.0;

@interface LoginAssistantManager()

- (void) performLoginAssistantStartAnimation;
- (void) performAutomatedLogin;
- (void) displayLoginDialog;
- (void) showCredentialsView;
- (void) showLoginAssistantView;
- (void) animate;

- (IBAction)loginAssistantButtonTouched: (id)sender;

@end

static NSString *const sLogMeInButtonTitle      = @"Log Me In";
static NSString *const sDismissButtonTitle      = @"Dismiss";


@implementation LoginAssistantManager

@synthesize viewForLoginAssistant;
@synthesize loginAssistantDelegate;
@synthesize sessionKey;
@synthesize loginAssistantLogMeInButton;
@synthesize loginAssistantDismissButton;

/**
 * Get Login Assistant Manager instance
 * Returns (& creates if necessary) Login Assistant Manager Singleton
 */
+ (LoginAssistantManager *) manager
{
    static LoginAssistantManager *manager = nil;
    static dispatch_once_t onceToken;
    // this will only be called once during the applications lifetime
    dispatch_once(&onceToken, ^{
        manager = [[LoginAssistantManager alloc] init];
    });
    return manager;
}

/**
 * Initialize Login Assistant 
 */
- (id) init
{
    self = [super init];
    if(self)
    {
        // Initialize set up for Login Assistant
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        // clear delegate
        loginAssistantDelegate      = nil;
        
        // Set login assistant button normal state
        UIColor *colorForButtonsNormalState = [UIColor colorWithWhite:0.0
                                                                alpha:0.75];
        // Set login assistant button highlighted state
        UIColor *colorForButtonsHighlightedState = [UIColor colorWithWhite:0.25
                                                                     alpha:0.75];
        // Set up login assistant dialog view
        loginAssistantView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_assistant_dialog_bg"]];
        [loginAssistantView sizeToFit];
        [loginAssistantView setUserInteractionEnabled:YES];
        
        // Set up login assistant log me in button
        loginAssistantLogMeInButton = [BlinkingButton buttonWithType:UIButtonTypeCustom];
        [loginAssistantLogMeInButton setTitle:sLogMeInButtonTitle forState:UIControlStateNormal];
        
        [loginAssistantLogMeInButton setTitleEdgeInsets:UIEdgeInsetsMake(0, logMeInButtonTitleLeftInset, 0.0, 0.0)];
        [loginAssistantLogMeInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [loginAssistantLogMeInButton setColor:colorForButtonsNormalState forControlState:UIControlStateNormal];
        [loginAssistantLogMeInButton setColor:colorForButtonsHighlightedState forControlState:UIControlStateHighlighted];
        [loginAssistantLogMeInButton setRoundedCornersWithRadius:kLoginAssistantButtonCornerRadius];
        [loginAssistantLogMeInButton addTarget:self action:@selector(performLoginAssistant:) forControlEvents:UIControlEventTouchUpInside];
        // set log me in button background
        [loginAssistantLogMeInButton setBackgroundImage:[UIImage imageNamed:@"login_assistant_ok_button_bg"]
                            forState:UIControlStateNormal];
        
        // Add log me in button inside login assistant view
        [loginAssistantView addSubview:loginAssistantLogMeInButton];
        [loginAssistantLogMeInButton setFrame:CGRectMake(kLoginAssistantButtonMargin, (loginAssistantView.frame.size.height - kLoginAssistantButtonHeight) / 2.0, kLoginAssistantButtonWidth, kLoginAssistantButtonHeight)];
        
        // Set up login assistant dismiss button
        loginAssistantDismissButton = [BlinkingButton buttonWithType:UIButtonTypeCustom];
        [loginAssistantDismissButton setTitle:sDismissButtonTitle forState:UIControlStateNormal];
        [loginAssistantDismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [loginAssistantDismissButton setColor:colorForButtonsNormalState forControlState:UIControlStateNormal];
        [loginAssistantDismissButton setColor:colorForButtonsHighlightedState forControlState:UIControlStateHighlighted];
        [loginAssistantDismissButton setRoundedCornersWithRadius:kLoginAssistantButtonCornerRadius];
        [loginAssistantDismissButton addTarget:self action:@selector(dismissLoginAssistant:) forControlEvents:UIControlEventTouchUpInside];

        // Add dismiss button inside login assistant view
        [loginAssistantView addSubview:loginAssistantDismissButton];
        [loginAssistantDismissButton setFrame:CGRectMake((loginAssistantView.frame.size.width) / 2.0, (loginAssistantView.frame.size.height - kLoginAssistantButtonHeight) / 2.0, kLoginAssistantButtonWidth, kLoginAssistantButtonHeight)];
    }
    
    return self;
}


/**
 * Show login assistant view
 */
- (void) showLoginAssistantView
{
    // if a view has been assigned for the login assistant
    if (self.viewForLoginAssistant)
    {
        // set up login assistant dialog initial layout
        int dialogWidth   = loginAssistantView.frame.size.width;
        int dialogHeight  = loginAssistantView.frame.size.height;
        [loginAssistantView setFrame:CGRectMake((self.viewForLoginAssistant.frame.size.width - dialogWidth) / 2.0, (self.viewForLoginAssistant.frame.size.height - dialogHeight) / 2.0, dialogWidth, dialogHeight)];

        // add login assistant to view
        [self.viewForLoginAssistant addSubview:loginAssistantView];

        // start login assistant animation
        [self performLoginAssistantStartAnimation];
    }
    else
    {
        DLog(@"Warning: no view specified for Login Assistant!");
    }
}


/**
 * Animate Login Assistant Manager Dialog
 */
- (void) animate
{
    CGPoint endPosition = ([loginAssistantDelegate respondsToSelector:@selector(loginAssistantButtonEndPosition)]) ?
    [loginAssistantDelegate loginAssistantButtonEndPosition] : CGPointMake(20.0, loginAssistantLogMeInButton.frame.origin.y);
    
    if (endPosition.x < 0)
        endPosition.x = 20.0;
    else
        if (endPosition.x + loginAssistantLogMeInButton.frame.size.width >= loginAssistantLogMeInButton.superview.bounds.size.width)
            endPosition.x = loginAssistantLogMeInButton.superview.bounds.size.width - loginAssistantLogMeInButton.frame.size.width - 20.0;
    
    [UIView animateWithDuration:2.0
                     animations:^{
                         // move login assistant dialog view offscreen
                         loginAssistantView.frame = CGRectMake(endPosition.x, loginAssistantView.frame.origin.y, loginAssistantView.frame.size.width, loginAssistantView.frame.size.height);
                         
                         // fade out log me in dialog
                         loginAssistantView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         // remove login assistant from view
                         [loginAssistantView removeFromSuperview];
                         
                         // send login assistant animation completed message to delegate
                         if([loginAssistantDelegate respondsToSelector:@selector(loginAssistantAnimationCompleted)]) [loginAssistantDelegate performSelector:@selector(loginAssistantAnimationCompleted)];
                     }];
}

/**
 * Animate Login Assistant Manager Dialog
 */
- (void) performLoginAssistantStartAnimation
{
    // clear timers
    [timerForCallBack invalidate];
    timerForCallBack = nil;
    [timerForAnimation invalidate];
    timerForAnimation = nil;
    
    // set up timer for callback that login assistant animation will begin
    if([loginAssistantDelegate respondsToSelector:@selector(loginAssistantAnimationWillBegin)])
    {
        timerForCallBack = [NSTimer scheduledTimerWithTimeInterval:secondsForCallBack target:loginAssistantDelegate selector:@selector(loginAssistantAnimationWillBegin)  userInfo:nil  repeats:NO];
    }

    // set login assistant alpha to 1 (view is completely visible)
    loginAssistantView.alpha = 1;
    
    // set up time before triggering animation to dismiss login dialog
    timerForAnimation = [NSTimer scheduledTimerWithTimeInterval:TIME_LOGIN_ASSISTANT_DIALOG_REMAINS_ONSCREEN target:self selector:@selector(animate)  userInfo:nil  repeats:NO];
    DLog(@"Timers: %@,%@",timerForCallBack,timerForAnimation);
}

/**
 * Send CTRL+A as two separate keys
 */
-(void) sendCtrlA
{
    static const int kUnicodeUserSpaceVKeys = 0xee00;
    
    int keyCodeCtrl = kUnicodeUserSpaceVKeys + 0x11;
    int keyCodeA    = kUnicodeUserSpaceVKeys + 0x41;
    
    [SessionManager sendKeyDownMessage:keyCodeCtrl modifier:0 toSessionWithKey:self.sessionKey];
    [SessionManager sendKeyDownMessage:keyCodeA modifier:0 toSessionWithKey:self.sessionKey];
    
    [SessionManager sendKeyUpMessage:keyCodeCtrl modifier:0 toSessionWithKey:self.sessionKey];
    [SessionManager sendKeyUpMessage:keyCodeA modifier:0 toSessionWithKey:self.sessionKey];
}


/**
 * Simulate automated login key input
 */
-(void) simulateAutomatedLoginKeyInput {
    DLog(@"Simulate Automated Login Assistant - key entry!");

    // get username stored in login assistant for currently active profile
    NSString* username = [self getCurrentSessionLoginAssistantUsername];

    // get password stored in login assistant for currently active profile
    NSString* password = [self getCurrentSessionLoginAssistantUserPassword];
    
    // Tell the receiver to suspend the handling of touch-related events during auto-login
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    // Select all characters in password text field (by sending CTRL+A key message)
    if ([self isNewCtrlASupported])
    {
        [self sendCtrlA];
    }
    else
    {
        [SessionManager sendKeyPressedMessage:'a' modifier:kKbModCtrl toSessionWithKey:self.sessionKey];
    }
    
    // input automatic login username characters
    for(NSInteger i = 0; i < [username length]; ++i)
    {
        // send login assistant current username character
        [SessionManager sendKeyPressedMessage:[username characterAtIndex:i] modifier:kKbModNone toSessionWithKey:self.sessionKey];
        // send right key pressed (prevents combining key press for paired characters)
        [SessionManager sendKeyPressedMessage:kKbRight modifier:kKbModNone toSessionWithKey:self.sessionKey];
    }
    
    // send tab message to move from username to password field
    [SessionManager sendKeyPressedMessage:kKbTab modifier:kKbModNone toSessionWithKey:self.sessionKey];
    
    // wait a bit while tap will be processed
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.]];

    // if a non-zero password has been entered
    if(password && password.length > 0)
    {
        // Select all characters in password text field (by sending CTRL+A key message)
        if ([self isNewCtrlASupported])
        {
            [self sendCtrlA];
        }
        else
        {
            [SessionManager sendKeyPressedMessage:'a' modifier:kKbModCtrl toSessionWithKey:self.sessionKey];
        }

        // input all password characters
        for(NSInteger i = 0; i < [password length]; ++i)
        {
            // send login assistant current password character
            [SessionManager sendKeyPressedMessage:[password characterAtIndex:i] modifier:kKbModNone toSessionWithKey:self.sessionKey];
            // send right key pressed (prevents combining key press for paired characters)
            [SessionManager sendKeyPressedMessage:kKbRight modifier:kKbModNone toSessionWithKey:self.sessionKey];
        }

        // send enter keyboard command to submit login commands
        [SessionManager sendKeyPressedMessage:kKbEnter modifier:kKbModNone toSessionWithKey:self.sessionKey];
        
        // tells the receiver to resume the handling of touch-related events
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        // wait a bit while app log in and after that let keyboard will become first responder if need
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.]];

        // let delegate know that auto login has been performed
        if([loginAssistantDelegate respondsToSelector:@selector(autologinHasBeenPerformed)])
        {
            [loginAssistantDelegate autologinHasBeenPerformed];
        }
    }
    else
    {
        // clear password field if there is no stored password in login assistant
        [SessionManager sendKeyPressedMessage:kKbDel modifier:kKbModNone toSessionWithKey:self.sessionKey];
        
        // since password setting is empty activate keyboard for user to enter password
        if([loginAssistantDelegate respondsToSelector:@selector(showKeyboard)]) [loginAssistantDelegate performSelector:@selector(showKeyboard)];

        // tells the receiver to resume the handling of touch-related events
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    
}

/**
 * Display Login Dialog
 *
 * Check if user has entered Login credentials (at least a username)
 * and if so display Login Assistant dialog box
 * otherwise display show Login Assistant Credentials view
 */
- (void)displayLoginDialog
{
    // get username stored for login assistant
    NSString* u = [self getCurrentSessionLoginAssistantUsername];

    // if username doesn't exist or is zero length
    if((!u || [u length] == 0))
    {
        // show credentials enter view
        [self showCredentialsView];
    }
    else
    {
        // prepare to show login assistant dialog
        [self showLoginAssistantView];
    }
}

/**
 * Perform Automated Login
 *
 * Performs automated login by sending user credentials to service
 * as key presses.
 */
- (void)performAutomatedLogin
{
    // let login assistant delegate know that login assistant auto login has started
    [self.loginAssistantDelegate loginAssistantAutoLoginStarted];
    
    // perform automatic login key input
    [self simulateAutomatedLoginKeyInput];
    
    // let login assistant delegate know that login assistant auto login has ended
    [self.loginAssistantDelegate loginAssistantAutoLoginEnded];
}


/**
 * Perform login assistant
 *
 * Perform automatic login process (when login assistant OK button is pressed)
 */
- (IBAction) performLoginAssistant:(id)sender
{
    // immediately remove login assistant dialog
    [self removeLoginAssistant];

    // then perform automated login
    [self performAutomatedLogin];
}

/**
 * Remove login assistant
 *
 * Immediately removes login assistant dialog from view (after dismiss or )
 */
- (void) removeLoginAssistant
{
    // remove login assistant dialog from view
    [loginAssistantView removeFromSuperview];
    
    // invalidate timers
    [timerForCallBack invalidate];
    timerForCallBack = nil;
    [timerForAnimation invalidate];
    timerForAnimation = nil;
}

/**
 * Dismiss login assistant
 */
- (IBAction) dismissLoginAssistant:(id)sender
{
    // remove login assistant
    [self removeLoginAssistant];
}

/**
 * Assign Login Assistant delegate
 */
- (void)assignLoginAssistantDelegate: (FHServiceViewController *) theLoginAssistantDelegate
{
    self.loginAssistantDelegate = (id <LoginAssistantDelegate>)theLoginAssistantDelegate;
    self.sessionKey             = theLoginAssistantDelegate.sessionKey;
}


/**
 * Show Login Assistant Credentials View
 */
- (void)showCredentialsView
{
    // remove & clear any previous credentials view
    if (credentialsView)
    {
        [credentialsView removeFromSuperview];
        credentialsView = nil;
    }

    // create credentials view
    credentialsView = [[LoginAssistantCredentialsView alloc] initWithFrame:CGRectZero];

    // set credentials view delegate
    credentialsView.delegate = self;
    
    // get size of credentials dialog
    int credentialsWidth    =   credentialsView.frame.size.width;
    int credentialsHeight   =   credentialsView.frame.size.height;

    // center credentials view centered onscreen
    [credentialsView setFrame:CGRectMake((self.viewForLoginAssistant.frame.size.width - credentialsWidth) / 2.0, (self.viewForLoginAssistant.frame.size.height - credentialsHeight) / 2.0, credentialsWidth, credentialsHeight)];

    // Set credentials view title
    [credentialsView setupTitleForCurrentSession];
    
    // Clear do not show checkbox for credentials view
    credentialsView.doNotShowCheck.titleLabel.text = @"";
    
    // clear username text field
    credentialsView.textFieldForName.text = nil;

    // clear password text field
    credentialsView.textFieldForPassword.text =  nil;
    
    // if credentials view not already assigned to login assistant view then assign it
    if(![credentialsView superview])
    {
        // add credentials view to login assistant view
        [self.viewForLoginAssistant addSubview:credentialsView];
    }
}

#pragma mark - LoginAssistantViewDelegate methods
/**
 * Handle login assistant enter credentials dialog OK button being pressed
 */
- (void) OKButtonPressedForView: (LoginAssistantCredentialsView *) view
{
    // remove login credentials view from view
    [credentialsView removeFromSuperview];
    
    // enable login assist toggled on key
    [[[MenuCommands get] selectedCommand] setValue:[NSNumber numberWithBool:YES] forKey:kProfileServiceLoginAssistantToggleKey];
    [[MenuCommands get] saveCommand: [[MenuCommands get] selectedCommand]];
    
    // display Login Assistant dialog
    [self displayLoginDialog];
}

#pragma mark - LoginAssistantManager action methods
/**
 * Handle login assistant button (from main menu) being pressed
 */
- (IBAction)loginAssistantButtonTouched: (id)sender
{
    // display login dialog
    [self displayLoginDialog];
}

/**
 * Cancel button pressed for the specified view
 */
- (void) CancelButtonPressedForView: (LoginAssistantCredentialsView *) view withOption: (BOOL) hideLoginView
{
    // remove login assistant credentials view
    [view removeFromSuperview];
    
    // if hide login view then toggle login assistant menu setting to off
    if(hideLoginView){
        [[[MenuCommands get] selectedCommand] setValue:0 forKey:kProfileServiceLoginAssistantToggleKey];
    }
}

/**
 * Get login assistant username string stored for current session
 * returns - current sessions login assistant username string or nil if none has been entered
 */
- (NSString *)getCurrentSessionLoginAssistantUsername
{
    // check if user has already stored a username for login assistant
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    NSString* aName = [[[MenuCommands get] selectedCommand] objectForKey:kProfileServiceLabelKey];

    // get username stored for login assistant
    NSString* u = [SettingsUtils loadLoginAssistantUsernameSettingForUserId:profileUserId profileId:pid appName:aName];
    
    return u;
}

/**
 * Get login assistant user password string stored for current session
 * @return (NSString *) - current sessions login assistant password string or nil if none has been entered
 */
- (NSString *)getCurrentSessionLoginAssistantUserPassword
{
    // check if user has already stored a username for login assistant
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    NSString* aName = [[[MenuCommands get] selectedCommand] objectForKey:kProfileServiceLabelKey];
    
    // get password stored for login assistant
    NSString* p = [SettingsUtils loadLoginAssistantPasswordSettingForUserId:profileUserId profileId:pid appName:aName];
    
    return p;
}


#pragma mark - LoginAssistantManager action methods
/**
 * Perform login assistant start
 */
- (void) performLoginAssistantStartForView: (UIView *) view withSecondsForCallBack: (double) seconds
{
    // set up time for callback
    secondsForCallBack = seconds;
    
    // perform login assistant
    [self performLoginAssistantForView:view];
}


/**
 * Peform Login Assistant for specified view
 */
- (void) performLoginAssistantForView:(UIView *)view
{
    // assign view used to display login assistant
    self.viewForLoginAssistant = view;

    // display login dialog
    [self displayLoginDialog];
    
}

/**
 * Dismiss Login Assistant Manager
 * removes any login assistant dialogs currently onscreen
 */
- (void) dismissLoginAssistantDialogs
{
    // remove login assistant dialog from view
    [loginAssistantView removeFromSuperview];
}


#pragma mark - keyboardWillChangeFrame Notification method
/**
 * Handle moving credentials view so it is still visible if keyboard is activated
 */
- (void) keyboardWillChangeFrame: (NSNotification *) notification
{
    double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // get position of credentials view when keyboard frame begins
    CGPoint begin = [credentialsView convertPoint:((NSValue*)[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey]).CGRectValue.origin
                                         fromView:nil];
    // get position of credentials after when keyboard frame ends
    CGPoint end = [credentialsView convertPoint:((NSValue*)[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey]).CGRectValue.origin fromView:nil];

    // get size of full application screen
    CGRect appRect = [credentialsView convertRect:[UIApplication sharedApplication].keyWindow.bounds fromView:nil];
    
    // get size of onscreen keyboard
    CGRect frame1 = [credentialsView convertRect:((NSValue*)[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey]).CGRectValue
                                        fromView:nil];
    
    CGFloat diffY = end.y - begin.y;
    
    CGFloat newY = appRect.size.height / 2;
    if (diffY < 0)
        newY += diffY / 2;
    else
        if (diffY == 0)
            newY -= frame1.size.height / 2;
    
    DLog(@"Diff value = %f, window height = %f, newY = %f", diffY,appRect.size.height, newY);

    // animate credentials view to above the onscreen keyboard
    [UIView animateWithDuration:duration
                     animations:^{
                         credentialsView.center = CGPointMake(credentialsView.center.x, newY);
                     }];
    
}

// server version compatability numbers for support of new ctrl-a code
static NSString *const sCtrlAServerMajorCompatabilityNumber = @"3";
static NSString *const sCtrlAServerMinorCompatabilityNumber = @"2";

/**
 * Check if new ctrl-a input is supported on current version of server
 *
 * @return (BOOL) - true if version of server session is connected to
 *                  supports new ctrl-a key entry code
 */
-(BOOL)isNewCtrlASupported
{
    BOOL bNewCtrlSupported = FALSE;
    
    // get server version for current session
    NSString* serverVersion = [SessionManager getServerVersionForSessionWithKey:self.sessionKey];

    // check server version
    // anything version 3.2 and above supports the new ctrl-A code

    // extract from server version string individual sections of version number
    NSArray* versionArray = [serverVersion componentsSeparatedByString:@"."];
    
    NSString* versionComponentStr;
    versionComponentStr = [versionArray objectAtIndex:0];

    // compare server version major number to the major compatability number
    switch ([versionComponentStr compare:sCtrlAServerMajorCompatabilityNumber])
    {
        // if the major version number is less than compatability major version number
        // then new ctrl-a is not supported
        case NSOrderedAscending:
            bNewCtrlSupported = false;
        break;
        
        // if the major version number matches compatability major version number
        // then we need to check the minor number
        case NSOrderedSame:
        {
            // get string for minor component
            versionComponentStr = [versionArray objectAtIndex:1];

            // compare server version minor number to the minor compatability number
            if ([versionComponentStr compare:sCtrlAServerMinorCompatabilityNumber]==NSOrderedAscending)
            {
                // if server version earlier than 3.2 then new ctrl-a not supported
                bNewCtrlSupported = false;
            }
            else
            {   // if server version 3.2 or greater then new ctrl-a is supported
                bNewCtrlSupported = true;
            }
        }
        break;
            
        // if the major version number is greater then new ctrl-a will be supported
        case NSOrderedDescending:
            bNewCtrlSupported = true;
        break;
    }
    
    // return if new ctrl is supported on current server
    return bNewCtrlSupported;
}



@end
