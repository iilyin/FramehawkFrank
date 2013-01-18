//
//  FHServiceViewController.h
//  Launchpad
//
//  Session/Service View Controller
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FHServiceLaunchDelegate.h"
#import "Session.h"
#import "SessionManager.h"
#import "KeyboardController.h"
#import "FHServiceView.h"
#import "SpinnerController.h"
#import "MagnifierView.h"
#import "LoginAssistantManager.h"

@class OverlayContainer;
@class SubMenuItem;


@interface FHServiceViewController : KeyboardController<StartupControllerDelegate, UIKeyInput, UIAlertViewDelegate, UIGestureRecognizerDelegate, SessionConnectionUtilityDelegate,
    SessionViewControllerDelegate,
    FHServiceViewDelegate,
    MagnifierViewDelegate, UIWebViewDelegate, LoginAssistantDelegate
    >  
{
    /*
     First appear flag
     */
    BOOL firstAppear;
    BOOL started;
    BOOL panStarted;
    CGPoint panStart;
    CGPoint scrollStart;
    FHServiceView *fhv;
    
    BOOL bConnectionErrorOccurred;
    NSError* connectionErrorInfo;

    // Loupe Magnifier View
    MagnifierView *loupeView;

    // Dummy pinch gesture recognizer used to prevent highight text when swiping between sessions
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    
    /*
     Timer firing on idle timeout after magnifier is shown 
     This feature is currently disabled (code is commented now)
     */
    NSTimer *magnifierIdleTimer;
    
    //LaunchPad Views added
    SpinnerController   *spinner;
    UIViewController *submenu;
    UIWebView *rsaWebView;
    
    BOOL automateKeyboard;
}

@property (atomic,strong) SessionKey sessionKey; // session key (to access session currently open)
@property (nonatomic,strong) NSMutableString *command;
@property (nonatomic, strong) NSArray *menu;
@property (nonatomic) BOOL firstAppearCompleted;

#pragma LaunchPad
-(void)removeSpinner:(NSTimer *)timer;

- (void)initializeActiveView;

#pragma mark StartupControllerDelegate methods

- (void)startupCompleted:(FHServiceLaunchDelegate*)startupController user:(NSString *)user password:(NSString *)password;
- (void)startupFailed:(FHServiceLaunchDelegate *)startupController;

- (void)startConnection;
- (void)stopConnection;
- (void)pauseConnection;
- (void)resumeConnection;

#pragma mark SessionViewControllerDelegate methods

- (FHServiceView *)placeholderToShowFHView;

#pragma mark RemoteViewCommandDelegate methods

- (void)singleTapDetected:(CGPoint)tapLocation;


#pragma mark Connection did fail methods
- (void)displayAnyConnectionErrorDialogs;

#pragma mark SessionConnectionUtilityDelegate methods

- (void)connectionDidStart;
- (void)connectionDidFinish;
- (void)connectionDidFailWithError:(NSError *)error;
- (void)connectionReadyToStream;

#pragma mark MagnifierViewDelegate methods

- (void)loupeView:(MagnifierView*)view hideAtPosition:(CGPoint)location click:(BOOL)click;
- (void)loupeView:(MagnifierView *)view rightHalfClick:(CGPoint)location;
- (void)loupeView:(MagnifierView *)view magnifierClick:(CGPoint)location;

/**
 * Login Assistant auto login started
 */
- (void)loginAssistantAutoLoginStarted;

/**
 * Login Assistant auto login ended
 */
- (void)loginAssistantAutoLoginEnded;

- (void)setKeyboardTypeFromSelectedSession;
- (void)setAlphabetKeyboardType;

#pragma mark Edge touch
-(void)touchedEdge:(UIView *)view location:(CGPoint)location;
@end
