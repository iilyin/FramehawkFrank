//
//  FHServiceViewController.m
//  LaunchPad
//
//  Session/Service View Controller
//
//  Copyright (c) 2012 Framehawl Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <AudioToolbox/AudioToolbox.h>
#import "AppDelegate.h"
#import "BrowserServiceViewController.h"
#import "MenuCommands.h"
#import "RootViewController.h"
#import "UIUtils.h"
#import "FHServiceLaunchDelegate.h"
#import "LoginAssistantManager.h"
#import "FHServiceView.h"
#import "SessionManager.h"
#import "SessionView.h"
#import "GlobalDefines.h"
#import "CustomKeyButton.h"
#import "MenuCommands.h"
#import "ProfileDefines.h"
#import "FHServiceDefines.h"
#import "ServiceScrollView.h"
#import "StringUtility.h"
#import "SettingsUtils.h"
#import "File.h"
#include <sys/time.h>

/*
 Action ids
 */
#define menuHomeAction          @"menuHomeAction"
#define menuSearchAction        @"menuSearchAction"
#define menuHelpAction          @"menuHelpAction"
#define menuSettingsAction      @"menuSettingsAction"
#define RSABrowserMaxFrame         CGRectMake(0,0,1024,768)

#define FHViewIndex             0
#define SpinnerViewIndex        1
#define SubMenuViewIndex        2
#define KeyBoardViewIndex       3
#define FHPlaceHolderViewIndex  4
#define RSAViewIndex            5

#define keyboardTouchesNumber   3

// Magnifier defines
#define MAGNIFIER_ENABLED       1

/**
 * Connection error dialog buttons.
 */
typedef enum connectionErrorButtons 
{
kConnectionErrorCancelButton    = 0,
kConnectionErrorRetryButton     = 1
} connectionErrorButtons;


@interface FHServiceViewController(PrivateMethods)
- (void)initToolBars;
- (void)initGestureRecognizers;
- (void)startConnection;
- (FHServiceView *)placeholder;

- (void)showLoupe:(CGPoint)location;
- (void)hideLoupe;
- (CGPoint)actualFhViewLocation:(CGPoint)placeholderLocation;
@end

@implementation FHServiceViewController

@synthesize firstAppearCompleted;
@synthesize menu, command, sessionKey;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        bConnectionErrorOccurred = false;
        connectionErrorInfo = nil;
    }
    return self;
}

- (void)dealloc
{
    DLog(@"dealloc **** FHServiceViewController **** %@\n", [[self view] description]);
    DLog(@"**** FHServiceViewController **** 0x%x\n", (int)self);
    fhv = nil;
    self.menu = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    DLog(@"didReceiveMemoryWarning **** FHServiceViewController **** %@\n", [[self view] description]);
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
#pragma mark - Web View
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
    if ([webView viewWithTag:101]) {
        [[webView viewWithTag:101] removeFromSuperview];
    }
    
    DLog(@"*** Loaded Cookies ****");
    int count = 0;
    //DLog(@"Web Run Loop %@",[NSRunLoop currentRunLoop]);
    count = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
              cookiesForURL:
              [NSURL URLWithString:
               [[NSUserDefaults standardUserDefaults]
                objectForKey:@"reverse_proxy_domain"]]] count];
    
    DLog(@"%i",count);
    DLog(@"*** Loaded Cookies ****");
    DLog(@"Finished 1: %@",webView.request.URL.pathComponents);
    
    if (count == 2) {
        
        if ([[webView.request.URL.pathComponents objectAtIndex:1] isEqualToString:@"FHServiceRequest"]) {
            // DLog(@"Finished 2: %@",webView.request.URL.pathComponents);
            //[self startRSAService:nil]
            
            //[NSTimer scheduledTimerWithTimeInterval:13
            //                                 target:self
            //                               selector:@selector(removeRSA:)
            //                               userInfo:nil
            //                                repeats:NO];
            
            [self.view sendSubviewToBack:rsaWebView];
            [self cancelRSA:nil];
        }
        return;
    }
    
    //[[[rsaWebView view] viewWithTag:RSASpinnerTag] setHidden:YES];
    //[[[rsaWebView view] viewWithTag:CancelButtonTag] setHidden:NO];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
navigationType:(UIWebViewNavigationType)navigationType{
    if ([MenuCommands get].cookiesAreSet) {
        // return NO;
    }
    return YES;
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (![MenuCommands get].cookiesAreSet) {
        DLog(@"***** RSA Web Error ***** %@",error);
        if ([rsaWebView canGoBack]) [rsaWebView goBack];
    }
}
#pragma mark - View lifecycle

- (void)initPrivates
{
    panStart = CGPointZero;
    
    started = NO;
    firstAppear = YES;
    showKeyboard = NO;
    firstAppearCompleted = NO;
    DLog(@"%@", [self.menu description]);
    [self setCurrentKeyboardType:kAlphabeticXTabKeyboard];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initPrivates];
    
    submenu = nil;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if (submenu !=nil) {
        [submenu.view removeFromSuperview];
        submenu = nil;
    }
}

/**
 * Associates login assistant to current service view
 *
 */
- (void)associateLoginAssistantWithCurrentService
{
    // Set login assistant manager to reference this services view
    LoginAssistantManager *manager = [LoginAssistantManager manager];
    [manager assignLoginAssistantDelegate:self];
}


- (void)initializeActiveView
{
    // set any current view as offscreen
    FHServiceView *placeholder = [self placeholder];
    [placeholder viewGoesOffscreen];
    
    // set menu selected session from command
    // This call is needed to ensure the selected session in the Menu Command
    // is in synch with the actual session, in case a session is made active
    // by any other means than clicking on the menu
    // (e.g. if a session re-appears due to another one being closed)
    [[MenuCommands get] setSelectedCommandForSessionName:self.command];
    
    if (![MenuCommands get].cookiesAreSet) {
        [[MenuCommands get] checkForStaleCookie];
    }
    
    // resume service connection
    [self resumeConnection];
    
    // Set login assistant manager to reference this services view
    [self associateLoginAssistantWithCurrentService];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // send view goes offscreen message
    FHServiceView *placeholder = [self placeholder];
    [placeholder viewGoesOffscreen];
    
    // set menu selected session from command
    // This call is needed to ensure the selected session in the Menu Command
    // is in synch with the actual session, in case a session is made active
    // by any other means than clicking on the menu
    // (e.g. if a session re-appears due to another one being closed)
    [[MenuCommands get] setSelectedCommandForSessionName:self.command];
    
    // Set login assistant manager to reference this services view
    [self associateLoginAssistantWithCurrentService];
    
    // check for cookies
    if (![MenuCommands get].cookiesAreSet) {
        [[MenuCommands get] checkForStaleCookie];
    }
    
    DLog(@"**** Main Controller %@ Will Appear *****",self.command);
}

-(void)removeRSA{
    if (![MenuCommands get].cookiesAreSet) {
        [rsaWebView removeFromSuperview];
    }
    
    [[MenuCommands get] closeApplication:self.command];
}

-(void)cancelRSA:(id)sender{
    //NOW REMOVE FROM SUPERVIEW
    [rsaWebView removeFromSuperview];
    
    [MenuCommands get].cookiesAreSet = YES;
    
    [FHServiceLaunchDelegate performStartup:self];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (firstAppear)
    {
        firstAppear = NO;
        
        [(AppDelegate *)[UIApplication sharedApplication].delegate setMainController:self];

        [FHServiceLaunchDelegate performStartup:self];
    }
    
    // show title bubble
    [self showBubble];
    
    // show page control bubble
    AppDelegate* a = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [a.viewController showPageControl];
    
    // display any pending connection error dialogs
    [self displayAnyConnectionErrorDialogs];
}

/*
 * Show title bubble
 */
- (void) showBubble {
    
    DLog(@"++++++++++showBubble+++++++++++++++");
    
    UILabel* t = [[UILabel alloc] init];
    t.text = self.command; 
    t.layer.cornerRadius = 8; 
    t.textAlignment = UITextAlignmentCenter;
    t.backgroundColor = [UIColor colorWithWhite:0.2 alpha:.6];
    t.textColor = [UIColor whiteColor];
    t.font = [UIFont boldSystemFontOfSize:24];
    [t sizeToFit];
    CGRect fr = CGRectInset(t.frame, -20, -20); 
    fr.origin.x = 512 - fr.size.width/2;
    fr.origin.y = 50;
    t.frame = fr;
    [self.view addSubview:t];   
    
    
    [UIView animateWithDuration:PAGE_CONTROL_FADE_IN_OUT_TIME
                          delay:0
                        options:UIViewAnimationOptionTransitionCrossDissolve 
                     animations:^{
                         t.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [t removeFromSuperview];
                     }];
    
}

- (void) showSpinner {
    
    UIActivityIndicatorView* av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    av.frame = CGRectMake(512-30,120,60,60); 
    
    [av startAnimating];
    av.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                           UIViewAutoresizingFlexibleRightMargin |
                           UIViewAutoresizingFlexibleTopMargin |
                           UIViewAutoresizingFlexibleBottomMargin);
    
    [self.view addSubview:av];    
    
    [UIView animateWithDuration:4
                          delay:0
                        options:UIViewAnimationOptionTransitionCrossDissolve 
                     animations:^{
                         //t.alpha = .1;
                     }
                     completion:^(BOOL finished) {
                         [av removeFromSuperview];
                     }];
    
}

//Timer for allowing FH service to come up
-(void)removeSpinner:(NSTimer *)timer{
    DLog(@"%@",[self.view subviews]);
    [spinner.view removeFromSuperview];
    spinner.view = nil;
    spinner = nil;
}



//delegate method for older RSA auth.
-(void)finishedProxyAuthentication{
    [MenuCommands get].cookiesAreSet = YES;
    [FHServiceLaunchDelegate performStartup:self];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    //Pausing the connection
    [self pauseConnection];
    
    [self hideLoupe];
    
    DLog(@"**** Main Controller %@ View Will Disappear",self.command);
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [UIUtils isOrientationAllowed:interfaceOrientation];
}

#pragma mark StartupControllerDelegate methods
- (void)startupCompleted:(FHServiceLaunchDelegate*)startupController user:(NSString *)user password:(NSString *)password
{
    started = YES;
    
    [self initToolBars];
    [self initGestureRecognizers];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardDidShowNotification object:nil];

    // Set keyboard type based on session type
    [self setKeyboardTypeFromSelectedSession];
    [self startConnection];
}
- (void)startupFailed:(FHServiceLaunchDelegate *)startupController
{
    exit(0);
}

- (void)setKeyboardTypeFromSelectedSession
{
    MenuCommands* menuCommands = [MenuCommands get];
    if ([menuCommands selectedCommandUsesVDIKeyboard])
    {
        // Set to use VDI keyboard
        [self setCurrentKeyboardType:kAlphabeticXExtendedDesktopKeyboard];
    }
    else if ([menuCommands selectedCommandUsesBrowserKeyboard])
    {
        // Set to use browser keyboard
        [self setCurrentKeyboardType:kAlphabeticXTabKeyboard];
    }
    else {
        // default to use browser keyboard
        [self setCurrentKeyboardType:kAlphabeticXTabKeyboard];
    }
}


- (void)setAlphabetKeyboardType
{
    [self setCurrentKeyboardType:kAlphabeticKeyboard];
    currentKeyboardAccessoryView = nil;
}


- (void)moveHome:(id)sender
{
    NSAssert( TRUE, @"moveHome in FHServiceViewController is used." );
/*
    [SessionManager sendKeyPressedMessage:kKbEsc modifier:0 toSessionWithKey:[self.sessionKey intValue]];
    [SessionManager sendKeyPressedMessage:kKbBksp modifier:0 toSessionWithKey:[self.sessionKey intValue]];
*/
}

#pragma mark Private Methods

/**
 * Initializes the keyboard activate tab
 */
- (void)initToolBars
{
    //keyboard tag view
    MenuCommands* m = [MenuCommands get];
    NSDictionary* p = m.launchpadProfile;
    
    // get profile skin
    NSMutableDictionary *skin = [p objectForKey:kProfileSkinKey];
    
    // Keyboard activate tab image
    NSString* keyboardActivateTabImagePath = [[skin objectForKey:kProfileKeyboardActivateTabKey] URLEncodedString];
    UIImage* keyboardTabImage;
    NSURL* keyboardActivateTabImageURL = [NSURL URLWithString:keyboardActivateTabImagePath];
    
    if ([File checkFileExists:[File getProfileImagePath:[keyboardActivateTabImageURL path]]]) {
        keyboardTabImage = [UIImage imageWithContentsOfFile:
                     [File getProfileImagePath:[keyboardActivateTabImageURL path]]];
    }else{
        
        keyboardTabImage  = [UIImage imageWithData: [NSData dataWithContentsOfURL:keyboardActivateTabImageURL]];
    }
    
        
    UIImageView* keyBoardTag = [[UIImageView alloc] initWithImage:keyboardTabImage];
    
    CGSize viewSize = [UIUtils viewSize:self.view];
    //    keyBoardTag.frame = CGRectMake(0, 0, keyBoardTag.image.size.width, keyBoardTag.image.size.height);
    
    UIView *keyboardTagView = [[UIView alloc] initWithFrame:CGRectMake(viewSize.width - 75, viewSize.height - keyBoardTag.image.size.height, keyBoardTag.image.size.width, keyBoardTag.image.size.height)];
    [keyboardTagView addSubview:keyBoardTag];
    
    //[self.view insertSubview:keyboardTagView atIndex:KeyBoardViewIndex];
    [self.view addSubview:keyboardTagView];
    UITapGestureRecognizer *keyboardTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardTagTap:)];
    [keyboardTagView addGestureRecognizer:keyboardTapRecognizer];
}

/**
 * Set up gesture recognizers
 */
- (void)initGestureRecognizers
{
    //  Triple Tap Recognizer for keyboard
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(threeFingersTap:)];
    tripleTap.numberOfTapsRequired = 1;
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.delegate = self;
    [self.view addGestureRecognizer:tripleTap];
    
    
    //drag recognizer
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panRecognizer.minimumNumberOfTouches = 1;
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.cancelsTouchesInView = NO;
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    //long press recognizer for selection and dragging
    UILongPressGestureRecognizer *oneFingerLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerLongPress:)];
    oneFingerLongPressRecognizer.numberOfTouchesRequired = 1;
    oneFingerLongPressRecognizer.cancelsTouchesInView = NO;
    oneFingerLongPressRecognizer.delegate = self;
    [panRecognizer requireGestureRecognizerToFail: oneFingerLongPressRecognizer];
    [self.view addGestureRecognizer:oneFingerLongPressRecognizer];
    
    //magnifier recognizers (two finger tap)
    if ( MAGNIFIER_ENABLED )
    {
        // pinch gesture - dummy used to prevent 2-finger tap detection after pinch
        pinchGestureRecognizer = 
        [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        pinchGestureRecognizer.cancelsTouchesInView = NO;
        pinchGestureRecognizer.delegate = self;
        [self.view addGestureRecognizer:pinchGestureRecognizer];
        
        //two fingers tap for mouse offset node toggling
        UITapGestureRecognizer *twoFingersTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersTap:)];
        twoFingersTapRecognizer.numberOfTouchesRequired = 2;
        twoFingersTapRecognizer.cancelsTouchesInView = NO;
        twoFingersTapRecognizer.delegate = self;
        [twoFingersTapRecognizer requireGestureRecognizerToFail: pinchGestureRecognizer];
        [self.view addGestureRecognizer:twoFingersTapRecognizer];
    }
    
    //Add double touch pan recognizer (for drag)
    UIPanGestureRecognizer *panDoubleTouch = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    panDoubleTouch.minimumNumberOfTouches = 2;
    panDoubleTouch.maximumNumberOfTouches = 2;
    if ( MAGNIFIER_ENABLED )
    {   // this prevents drag/highlight when trying to swipe
        [panDoubleTouch requireGestureRecognizerToFail: pinchGestureRecognizer];
    }
    [[self view] addGestureRecognizer:panDoubleTouch];
    [panDoubleTouch setDelegate:self];
    
    
}

/**
 * @method handleDrag
 *
 * Handle a drag gesture (alternate gesture scheme).
 */
- (void)handleDrag:(UIPanGestureRecognizer *)recognizer{
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        scrollStart = [recognizer locationInView:(UIView*)[fhv.fhView renderer]];
        DLog(@"Pan location start = (%f,%f)", scrollStart.x, scrollStart.y);
        panStarted = NO;
        
        // adjust position if in magnifier view
        if (loupeView)
        {
            scrollStart = [fhv.fhView convertPoint:[loupeView adjustedCenter] fromView:self.view];
            
            // adjust location of magnifier to take into account any scroll when keyboard visible
            scrollStart = [self adjustLocationForYScrollForViewUnderKeyboard:scrollStart];
        }
        
        [fhv.fhView updateMousePosition:scrollStart.x y:scrollStart.y];
        [SessionManager sendMouseUpMessage:scrollStart.x yPos:scrollStart.y buttonNumber:kMouseButtonLeft toSessionWithKey:self.sessionKey];
        [SessionManager sendMousePositionMessageAlways:scrollStart.x yPos:scrollStart.y toSessionWithKey:self.sessionKey];
        return;
    }
    
    // if connection is not running or number of touches not equal to 2 then do nothing
    if (![SessionManager connectionIsRunning:self.sessionKey] || recognizer.numberOfTouches != 2)
        return;
    
    // if starting drag gesture
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        scrollStart = [recognizer locationInView:(UIView*)[fhv.fhView renderer]];
        DLog(@"Pan location start = (%f,%f)", scrollStart.x, scrollStart.y);
        panStarted = YES;
        
        // adjust position if in magnifier view
        if (loupeView)
        {
            scrollStart = [fhv.fhView convertPoint:[loupeView adjustedCenter] fromView:self.view];
            
            // adjust location of magnifier to take into account any scroll when keyboard visible
            scrollStart = [self adjustLocationForYScrollForViewUnderKeyboard:scrollStart];
        }
        
        [fhv.fhView updateMousePosition:scrollStart.x y:scrollStart.y];
        [SessionManager sendMouseDownMessage:scrollStart.x yPos:scrollStart.y buttonNumber:kMouseButtonLeft toSessionWithKey:self.sessionKey];
        [SessionManager sendMousePositionMessageAlways:scrollStart.x yPos:scrollStart.y toSessionWithKey:self.sessionKey];
        
        return;
    }

    //    if (!panStarted)
    //        return;
    
    BOOL ended = recognizer.state == UIGestureRecognizerStateEnded;
    
    FHServiceView *placeholder = [self placeholder];
    CGPoint translation = [recognizer translationInView:(UIView*)[fhv.fhView renderer]];
    
    static float fracX = 0.;
    static float fracY = 0.;
    
    if (loupeView)
    {
        DLog(@"drag with loupe");
        if (!ended)
        {
            CGFloat dx = translation.x - panStart.x;
            CGFloat dy = translation.y - panStart.y;
            CGPoint newPanLocation = CGPointMake(loupeView.frame.size.width / 2 + dx, loupeView.frame.size.height / 2 + dy);
            [loupeView changeLocation:newPanLocation];
            panStart = translation;
            
            // update offset mouse position (hover mode)
            CGPoint adjustedLocation = [[placeholder fhView] convertPoint:[loupeView adjustedCenter] fromView:self.view];
            // adjust location of magnifier to take into account any scroll when keyboard visible
            adjustedLocation = [self adjustLocationForYScrollForViewUnderKeyboard:adjustedLocation];
            
            DLog(@"Adjusted loupe center %f, %f", adjustedLocation.x, adjustedLocation.y);
            [placeholder.fhView updateMousePosition:adjustedLocation.x y:adjustedLocation.y];
            [SessionManager sendMousePositionMessage:adjustedLocation.x yPos:adjustedLocation.y toSessionWithKey:self.sessionKey];
        }
        else
        {
            panStart = CGPointZero;
            fracX = fracY = 0.;
        }
    }
    else
    {
        //CGFloat dy = translation.y - panStart.y;
        //DLog(@"Pan gesture %f", dy);
        CGPoint velocity = [recognizer velocityInView:(UIView*)[fhv.fhView renderer]];
        
        if (ended)
        {
            panStart = translation;

            [SessionManager generateScrollEvent:[recognizer locationInView:(UIView*)[fhv.fhView renderer]] delta:0 velocity:velocity.y toSessionWithKey:self.sessionKey];
            
            if (ended)
            {
                panStart = CGPointZero;
                panStarted = NO;
            }
        }
    }
}

- (FHServiceView *)placeholder
{
    return fhv;
    /*
     if([self.view isKindOfClass:[RemoteViewPlaceholder class]])
     {
     return (RemoteViewPlaceholder *)self.view;
     }
     
     return nil;
     */
}


#pragma mark Edge touch
-(void)touchedEdge:(UIView *)view location:(CGPoint)location{
    CGPoint scrollEdge = [fhv convertPoint:location fromView:view];
    
    if (self.placeholder && [[self placeholder] superview]){
        [SessionManager singleTapDetected:scrollEdge toSessionWithKey:self.sessionKey];
    }
    
    return;
}

#pragma mark Gesture Delegates
/**
 * Handle three finger tap - toggle keyboard
 */
- (void)threeFingersTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.numberOfTouches == keyboardTouchesNumber)
    {
        // only allow keyboard toggle if not swiping in between sessions
        if ([((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController).scrollView isViewFullyVisible])
        {
            // ... slide closed the menu drawer if it is open
            [self closeMenu];
            // toggle keyboard
            [self togglekeyboard];
        }
    }
}

/**
 * Code called at start of a gesture
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //    DLog(@"Following gesture recognizer is about to begin: %@", gestureRecognizer);
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}


/**
 * Pinch gesture recognizer - dummy only needed for
 * preventing 2-finger tap detected by mistake after pinch
 */
- (void)pinchGesture:(UIPinchGestureRecognizer*)recognizer
{
}

/**
 * Handle 2 finger tap
 */
- (void)twoFingersTap:(UITapGestureRecognizer*)recognizer
{
    // if connection is not running or no view then return
    if ( ![SessionManager connectionIsRunning:self.sessionKey] ||
         ![fhv fhView] ||
         !self.firstAppearCompleted)
            return;
    
    // if magnifier is enabled
    if ( MAGNIFIER_ENABLED )
    {
        // Toggle magnifier mode
        if (loupeView)
            [self hideLoupe];
        else
        {   // only allow user to activate magnifier if not in zoom mode
            if (![fhv.fhView isZoomed])
            {
                // adjust offset if keyboard is active
                [self showLoupe:[recognizer locationInView:self.view]];
            }
        }
        
        // only show halo outside of magnify mode
        [fhv showHalo:(loupeView==nil)];
    }
}

- (void)panGesture:(UIPanGestureRecognizer*)recognizer
{
    // if keyboard visible (& offset mouse not enabled) then scroll view when panning
    if (showKeyboard && (!loupeView))
    {
        // handle scrolling of view in region not covered by keyboard
        FHServiceView *placeholder = [self placeholder];

        // if scrolled view under keyboard then don't pass on scroll to service
        if ([placeholder scrollViewUnderKeyboard:recognizer])
            return;
    }
    
    if ([SessionManager connectionIsRunning:self.sessionKey] && recognizer.numberOfTouches == 1 && recognizer.state == UIGestureRecognizerStateBegan)
    {
        scrollStart = [recognizer locationInView:(UIView*)[fhv.fhView renderer]];
        CGPoint velocity = [recognizer velocityInView:(UIView*)[fhv.fhView renderer]];
        panStarted = YES;
        
        [SessionManager startScrollEvent:scrollStart velocity:velocity.y toSessionWithKey:self.sessionKey];
        
        return;
    }

    if (![SessionManager connectionIsRunning:self.sessionKey] || recognizer.numberOfTouches > 1)
        return;
    
    if (!panStarted)
    {
        return;
    }
    
    BOOL ended = recognizer.state == UIGestureRecognizerStateEnded;
    
    FHServiceView *placeholder = [self placeholder];
    CGPoint translation = [recognizer translationInView:(UIView*)[[fhv.fhView getView] renderer]];
    CGPoint location = [recognizer locationInView:(UIView*)[[fhv.fhView getView] renderer]];
    
    static float fracX = 0.;
    static float fracY = 0.;
    
    if (loupeView)
    {
        DLog(@"panning with loupe");
        if (!ended)
        {
            CGFloat dx = translation.x - panStart.x;
            CGFloat dy = translation.y - panStart.y;
            CGPoint newPanLocation = CGPointMake(loupeView.frame.size.width / 2 + dx, loupeView.frame.size.height / 2 + dy);

            [loupeView changeLocation:newPanLocation];
            panStart = translation;
            
            // update offset mouse position (hover mode)
            CGPoint adjustedLocation = [placeholder.fhView convertPoint:[loupeView adjustedCenter] fromView:self.view];
            
            // adjust location of magnifier to take into account any scroll when keyboard visible
            adjustedLocation = [self adjustLocationForYScrollForViewUnderKeyboard:adjustedLocation];
            
            DLog(@"Adjusted loupe center %f, %f", adjustedLocation.x, adjustedLocation.y);
            [placeholder.fhView updateMousePosition:adjustedLocation.x y:adjustedLocation.y];
            [SessionManager sendMousePositionMessage:adjustedLocation.x yPos:adjustedLocation.y toSessionWithKey:self.sessionKey];
        }
        else
        {
            [SessionManager endScrollEvent:location toSessionWithKey:self.sessionKey];
            panStart = CGPointZero;
            fracX = fracY = 0.;
        }
    }
    else
    {
        CGPoint velocity = [recognizer velocityInView:(UIView*)[fhv.fhView getView]];
        panStart = translation;
        if (ended)
        {
            [SessionManager endScrollEvent:[recognizer locationInView:(UIView*)[fhv.fhView renderer]] toSessionWithKey:self.sessionKey];
            panStart = CGPointZero;
            panStarted = NO;
        }
        else if (recognizer.state == UIGestureRecognizerStateChanged)
        {
            [SessionManager generateScrollEvent:[recognizer locationInView:(UIView*)[fhv.fhView renderer]] delta:0 velocity:velocity.y toSessionWithKey:self.sessionKey];
        }
    }
}

/**
 * Slide menu closed if it is open
 */
- (void)closeMenu
{
    // ... slide closed the menu drawer if it is open
    AppDelegate* a = [UIApplication sharedApplication].delegate;
    MenuViewController* mvc = a.viewController.menuViewController;
    [mvc closeMenu];
}

/**
 * Toggle keyboard when user taps on keyboard activate tab icon
 */
- (void)keyboardTagTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateChanged)
        panStart = CGPointZero;

    // ... slide closed the menu drawer if it is open
    [self closeMenu];
    
    // activate keyboard
    [self togglekeyboard];
}

// one finger long press for right mouse click
- (void)oneFingerLongPress:(UILongPressGestureRecognizer*)recognizer
{
    if (![SessionManager connectionIsRunning:self.sessionKey])
        return;
    
    FHServiceView *placeholder = [self placeholder];
    
    {
        // get location of gesture in view (accounts for rotation)
        CGPoint location = [recognizer locationInView:(UIView*)[fhv.fhView renderer]];
        int touchX = (int)location.x;
        int touchY = (int)location.y;
        
        // handle processing based on gesture state
        switch ([recognizer state]) {
            case UIGestureRecognizerStatePossible:
                DLog(@"One finger long press is possible");
                break;
            case UIGestureRecognizerStateBegan:
            {
                // send mouse down message when single touch is started
                DLog(@"One finger press started");
                
                if (loupeView){
                    CGPoint loupeCenter = [placeholder convertPoint:CGPointMake(loupeView.bounds.size.width / 2, loupeView.bounds.size.height / 2) fromView:loupeView];
                    touchX = loupeCenter.x;
                    touchY = loupeCenter.y;
                    DLog(@"loupe view center = %f, %f", loupeCenter.x, loupeCenter.y);
                }
                
                CGPoint newLocation = [self actualFhViewLocation:CGPointMake(touchX, touchY)];
                [placeholder.fhView updateMousePosition:newLocation.x y:newLocation.y];
                // send mouse right click
                [SessionManager sendMouseClickMessage:newLocation mouseButton:kMouseButtonRight toSessionWithKey:self.sessionKey];
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
            }
                break;
            case UIGestureRecognizerStateEnded:
            {
            }
                break;
            default:
                break;
        }
    }
}


- (void)oneFingerImmediatePress:(UILongPressGestureRecognizer*)recognizer
{
    if (![SessionManager connectionIsRunning:self.sessionKey])
        return;
    // get location of gesture in view (accounts for rotation)
    CGPoint location = [recognizer locationInView:(UIView*)[fhv.fhView renderer]];
    int touchX = (int)location.x;
    int touchY = (int)location.y;
    
    // handle processing based on gesture state
    switch ([recognizer state]) {
        case UIGestureRecognizerStatePossible:
            DLog(@"One finger immediate press is possible");
            break;
        case UIGestureRecognizerStateBegan:
            // send mouse down message when single touch is started
            DLog(@"One finger immediate started");
            [fhv.fhView updateMousePosition:touchX y:touchY];
            [SessionManager sendMouseDownMessage:touchX yPos:touchY buttonNumber:kMouseButtonLeft toSessionWithKey:self.sessionKey];
            break;
        case UIGestureRecognizerStateChanged:
            // update mouse position when user moves
            DLog(@"One finger immediate changed");
            [fhv.fhView updateMousePosition:touchX y:touchY];
            [SessionManager sendMousePositionMessage:touchX yPos:touchY toSessionWithKey:self.sessionKey];
            break;
        case UIGestureRecognizerStateEnded:
            // send mouse up message as touch is ended
            DLog(@"One finger immediate ended");
            static BOOL processEnd = NO;
            if (processEnd && recognizer.state == UIGestureRecognizerStateEnded && loupeView)
            {
                processEnd = NO;
            }
            
            [fhv.fhView updateMousePosition:touchX y:touchY];
            [SessionManager sendMouseUpMessage:touchX yPos:touchY buttonNumber:kMouseButtonLeft toSessionWithKey:self.sessionKey];
            break;
        default:
            break;
    }
}

#pragma mark SessionViewControllerDelegate methods
- (FHServiceView *)placeholderToShowFHView
{
    if (!fhv)
    {
        CGSize parentSize = [UIUtils viewSize:self.view];
        fhv = [[FHServiceView alloc] initWithFrame:CGRectMake(0, 0, parentSize.width, parentSize.height)];
        fhv.tapDelegate = self;
        [self.view addSubview:fhv];
        [self.view sendSubviewToBack:fhv]; //Sent to the Back
        fhv.fhPolicy = FHPolicyCentered|FHPolicyScaledAspectRatioLost;
    }
    
    return fhv;
}

#pragma mark RemoteViewCommandDelegate methods

- (void)singleTapDetected:(CGPoint)tapLocation
{
    FHServiceView *placeholder = [self placeholder];
    
    if (loupeView){
        tapLocation = [placeholder.fhView convertPoint:[loupeView adjustedCenter] fromView:self.view];
        // make sure mouse is clicked on pointer edge.
        // TODO: set offset in loupeview
        tapLocation.x -= 5.5;
        tapLocation.y -= 7.5;

        // adjust location of magnifier to take into account any scroll when keyboard visible
        tapLocation = [self adjustLocationForYScrollForViewUnderKeyboard:tapLocation];
    }
    
    [placeholder.fhView updateMousePosition:tapLocation.x y:tapLocation.y];
    [SessionManager singleTapDetected:tapLocation toSessionWithKey:self.sessionKey];
    [SessionManager sendMousePositionMessageAlways:tapLocation.x yPos:tapLocation.y toSessionWithKey:self.sessionKey];
    
    // reset any keyboard control keys when any regular key is pressed
    [self resetKeyboardToolbarControlKeys];
    AudioServicesPlaySystemSound(0x450);
    
    // hide magnifier after tap
    if (loupeView)
        [self hideLoupe];
}

#pragma mark SessionConnectionUtilityDelegate methods

- (void)connectionDidStart
{
    
}

- (void)connectionDidFinish
{
    
}

/**
 * Display any connection error dialogs
 */
- (void)displayAnyConnectionErrorDialogs
{
    DLog(@"++++ displayAnyConnectionErrorDialogs");
    if (bConnectionErrorOccurred)
    {
        // set connection failure dialogs
        RootViewController* rvc = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
        BOOL bIsActive = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
        DLog(@"++++ bIsActive=%i, displayingPIN=%i ", bIsActive, rvc.bDisplayingPINScreen);
        
        if ((bIsActive) && (!rvc.bDisplayingPINScreen))
            [self showConnectionError:connectionErrorInfo];
    }
}

/**
 * Show connection error dialog
 */
- (void)showConnectionError:(NSError *)error
{
    DLog(@"++++SHOW CONNECTION ERROR:%@ for %@", [error description], [[self view] description]);
    // get session key for session that has error
    SessionKey currentSessionKey = [SessionManager getSessionKeyForSessionWithView:fhv.fhView ];
    
    bConnectionErrorOccurred = false;

    // Session connection error must be displayed on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                     message:[error localizedDescription]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:nil, nil];
        // store current session key as tag so correct session is closed later
        av.tag = [currentSessionKey integerValue];
        // store connection index - used to associate alert with view, when displaying delayed alerts
        [av show];
        av = nil;
        connectionErrorInfo = nil;
    });
    
    //        av.tag = [self.sessionKey intValue];
}


- (void)connectionDidFailWithError:(NSError *)error
{
    // set connection failure dialogs
    RootViewController* rvc = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
    BOOL bIsActive = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
    DLog(@"++++ bIsActive=%i, displayingPIN=%i, isPresented=%i ", bIsActive, rvc.bDisplayingPINScreen, [self isBeingPresented]);
    if ((bIsActive) && (!rvc.bDisplayingPINScreen) && (self.isViewLoaded && self.view.window))
    {   // if view is currently visible then show error immediately
        [self showConnectionError:error];
    }
    else
    {   // otherwise set information for buffered connection error
        // set connection error flag
        bConnectionErrorOccurred = true;
        // set connection error
        connectionErrorInfo = error;
        DLog(@"++++BUFFER CONNECTION ERROR:%@ for %@", [error description], [[self view] description]);

    }
}

/**
 * When alert view is dismissed (after session failure alert), open up menu
 * Done here so that calls from AlertView to delegate occur before closing session view
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    DLog(@">>>>>> alertView didDismissWithButtonIndex\n");
    // if user selects cancels the connection after an error
    if (buttonIndex==kConnectionErrorCancelButton)
    {
        // ...Close the menu command
        MenuCommands* m = [MenuCommands get];

        // extract session key from alert view tag
        NSString* alertSessionKey = [NSString stringWithFormat:@"%d", alertView.tag];
        // get viewcontroller for session to close using session key
        UIViewController* vc = [m getSessionViewControllerWithKey:alertSessionKey];

        if (vc) {
            if ([vc isKindOfClass:[BrowserServiceViewController class]])
                [m closeApplication:((BrowserServiceViewController*)vc).command];
            if ([vc isKindOfClass:[FHServiceViewController class]])
            {
                DLog(@"Closing command for session %@", ((FHServiceViewController*)vc).command);
                [m closeApplication:((FHServiceViewController*)vc).command];
            }
        }

        // ... slide open the menu drawer
        AppDelegate* a = [UIApplication sharedApplication].delegate;
        MenuViewController* mvc = a.viewController.menuViewController;
        [mvc openMenu];
    }
}


/**
 * Show Login Assistant Screen
 */
- (void)showLoginAssistantScreen
{
    // Set login assistant manager to reference this services view
    [self associateLoginAssistantWithCurrentService];

    // check that login assistant is allowed for current service
    DLog(@"connectionReadyToStream\n");
    // Obtain the latest session command
    MenuCommands* menuInfo = [MenuCommands get];
    NSDictionary* sessionInfo = [menuInfo getCommandWithName:command];
    
    // Check if session is allowed to support login assistant
    BOOL bLoginAssistantAllowed = [SettingsUtils checkServiceInformationForloginAssistantAllowed:sessionInfo];
    
    // only show login assistant dialog if it is allowed for this service
    if (bLoginAssistantAllowed)
    {
        // perform login assistant start
        LoginAssistantManager *manager = [LoginAssistantManager manager];
        FHServiceView *placeholder = [self placeholder];
        [manager performLoginAssistantStartForView:placeholder withSecondsForCallBack:0.0];
    }
}

/**
 * Connection has been made & service is ready to stream
 */
- (void)connectionReadyToStream
{
    DLog(@"connectionReadyToStream\n");
    [fhv showHalo:(loupeView==nil)];
    [fhv.fhView updateMousePosition:0 y:0];
    
    DLog(@"firstAppearCompleted fhv.fhView-0x%x\n", (int)fhv.fhView);
    
    self.firstAppearCompleted = YES;
    // Only show if easy login enabled for the active profile service
    NSDictionary      *selectedCommand = [[MenuCommands get] selectedCommand];
    
    // get profile user id
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    
    // get profile id
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    
    // get service name
    NSString* aName = [selectedCommand objectForKey:kProfileServiceLabelKey];
    
    // check if login assistant setting enabled by user for this service
    if ([SettingsUtils loadLoginAssistantEnabledSettingForUserId:profileUserId profileId:pid appName:aName])
    {
        DLog(@"show Login Assistant Screen!!!\n");
        [self showLoginAssistantScreen];
    }
    return;
}


#pragma mark -
#pragma mark UIAlertViewDelegate Implementation


- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    DLog(@">>>>>>FHServiceViewController:alertView\n");
                                                                             
    // If the 'Retry' button...
    if (buttonIndex == kConnectionErrorRetryButton)
        // ...Retry the Framehawk connection
        [self startConnection];
    // Elsewise for the cancel button...
    else {
        // handled in didDismissWithButtonIndex method
    }
}

#pragma mark Connection control

- (void)startConnection
{
    /*
     Don't start connection startup is not completed
     */
    if (firstAppear || !started)
        return;
    

    @try {
        NSString* url = [[MenuCommands get].selectedCommand objectForKey:kFramehawkURLKey];
        NSString* service = [[MenuCommands get].selectedCommand objectForKey:kFramehawkServiceIdKey];
        NSNumber* region = [[MenuCommands get].selectedCommand objectForKey:kFramehawkServiceRegionKey];
        // load username from settings
        NSString* user = [SettingsUtils getCurrentUserID];
        // load password from settings
        NSString* password = [SettingsUtils getCurrentUserPassword];
        NSString* arguments = [[MenuCommands get].selectedCommand objectForKey:kFramehawkServiceArgumentsKey];

        DLog(@"%@, %@, %@, %@, %@, %@", url, service, region, user, password, arguments);
        DLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> START %@",self.command);
        DLog(@"self.sessionKey=0x%x", (int)self.sessionKey);
        DLog(@"self.sessionKey value=%i", [self.sessionKey intValue]);
        
        // Set up session connection parameters
        SessionParameters* sessionParams = [[SessionParameters alloc] init];
        [sessionParams setUrl:url];
        [sessionParams setServiceID:service];
        [sessionParams setRegion:region];
        [sessionParams setUsername:user];
        [sessionParams setPassword:password];
        [sessionParams setArguments:arguments];

        NSArray* internalCommands = [MenuCommands getAllFramehawkSessionCommands];
        NSInteger commandCount = [internalCommands count];
        NSString* sessionName = [[MenuCommands get].selectedCommand objectForKey:kProfileServiceLabelKey];
        
        // Create session
        SessionKey newSessionKey = [SessionManager createSessionNamed:sessionName withParameters:sessionParams viewDelegate:self connectionDelegate:self sessionCount:commandCount];
        // store session key
        [self setSessionKey:newSessionKey];
        // set login assistant session key
        [self associateLoginAssistantWithCurrentService];
    }
    @catch (NSException *exception) {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Connection error" message:[NSString stringWithFormat:@"%@: %@", exception.name, exception.reason] delegate:self cancelButtonTitle:@"Try again" otherButtonTitles: @"Exit", nil];
        [errorView show];
    }
}

- (void)stopConnection
{
    DLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STOP %@",self.command);
    DLog(@"self.sessionKey=0x%x", (int)self.sessionKey);
    DLog(@"self.sessionKey value=%@", self.sessionKey);
    SessionKey keyForSessionToStop = self.sessionKey;
    [SessionManager dropConnectionAndView:keyForSessionToStop];
    [fhv removeFromSuperview];
    fhv = nil;
}

- (void)pauseConnection
{
    DLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PAUSE %@",self.command);
    DLog(@"self.sessionKey=0x%x", (int)self.sessionKey);
    DLog(@"self.sessionKey value=%@", self.sessionKey);
    [SessionManager pauseConnection:self.sessionKey];
}

- (void)resumeConnection
{
    if ([MenuCommands get].cookiesAreSet) {
        
        if ([SessionManager connectionIsRunning:self.sessionKey]){
            [SessionManager resumeConnection:self.sessionKey];
        }/*else
          [self startConnection];*/
    }
    else {
        
        if([SessionManager connectionIsRunning:self.sessionKey]){
            DLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RESUME %@",self.command);
            DLog(@"self.sessionKey=0x%x", (int)self.sessionKey);
            DLog(@"self.sessionKey value=%@", self.sessionKey);
            [SessionManager resumeConnection:self.sessionKey];
        }
    }
    //    
    //    
    //    [NSTimer scheduledTimerWithTimeInterval:0.65
    //                                     target:self
    //                                   selector:@selector(removeSpinner:)
    //                                   userInfo:nil
    //                                    repeats:NO];
    //    
}

#pragma mark Keyboard controller methods overrides

/**
 * Converts a iOS Key input code into corresponding Framehawk key code.
 */
-(unichar) convertiOSKeyToFramehawkKey:(unichar)keyCode
{
    unichar framehawkKeyCode;
    
    switch (keyCode) {
        case 0x9:   // Tab key
            framehawkKeyCode = kKbTab;
            break;
        default:
            framehawkKeyCode = keyCode;
            break;
    }
    
    
    return framehawkKeyCode;
}


/**
 * Send text character(s) from iOS keyboard input as key press messages sent to connected service (overriding method from UIKeyInput class).
 */
- (void)insertText:(NSString* )text
{
    int n = [text length];
    int i;
    for (i = 0; i < n; i++)
    {
        [SessionManager sendKeyPressedMessage: [self convertiOSKeyToFramehawkKey:[text characterAtIndex:i]] modifier:[self keyboardFlags] toSessionWithKey:self.sessionKey];
    }
    
    // reset any keyboard control keys when any regular key is pressed
    [self resetKeyboardToolbarControlKeys];
}


/**
 * Reset keyboard toolbar control keys
 */
- (void)resetKeyboardToolbarControlKeys
{
    // reset any keyboard control keys when actual key is pressed
    [self resetXKeyboardModeButtonsSelected];
}

/**
 * Send backspace key press message
 */
- (void)deleteBackward
{
    [SessionManager sendKeyPressedMessage:kKbBksp modifier:[self keyboardFlags] toSessionWithKey:self.sessionKey];
}

- (void)xCtrlAltDelAction:(CustomKeyButton*)button
{
    [SessionManager sendKeyPressedMessage:kKbDel modifier:kKbModCtrl|kKbModAlt toSessionWithKey:self.sessionKey];
}

- (void)customKeyAction:(CustomKeyButton*)button
{
    if (button.keys != 0)
    {
        [SessionManager sendKeyPressedMessage:button.keys modifier:keyboardFlags toSessionWithKey:self.sessionKey];
        // reset any keyboard control keys when any toolbar key is pressed
        [self resetKeyboardToolbarControlKeys];
    }
    else
        switch (button.tag) {
            case kXBackward:
                //[SessionManager  sendKeyPressedMessage:kKbTab modifier:kKbModShift toSessionWithKey:[self.sessionKey intValue]];
                [SessionManager sendKeyPressedMessage:kKbLeft modifier:kKbModAlt toSessionWithKey:self.sessionKey];
                
                [self resetXKeyboardModeButtonsSelected];
                break;
            case kXForward:
                //[SessionManager sendKeyPressedMessage:kKbTab modifier:kKbModNone toSessionWithKey:[self.sessionKey intValue]];
                [SessionManager sendKeyPressedMessage:kKbRight modifier:kKbModAlt toSessionWithKey:self.sessionKey];
                
                [self resetXKeyboardModeButtonsSelected];
                break;
            case kxShiftTab:
                [SessionManager sendKeyPressedMessage:kKbTab modifier:kKbModShift toSessionWithKey:self.sessionKey];
                break;
            case kXTab:
                [SessionManager sendKeyPressedMessage:kKbTab modifier:kKbModNone toSessionWithKey:self.sessionKey];
                break;
            case kXFKeys:
            {
                break;
            }
            case kxMinimizeKeyBoard:
                [self togglekeyboard];
                break;
            default:
                break;
        }
}

#pragma mark Loupe control
/**
 * Called to get the scroll y-offset for the view beneath the keyboard
 *
 * @return (CGFloat) - y scroll offset within keyboard view
 */
- (CGFloat)scrollYOffsetForViewUnderKeyboard
{
    // adjust for any scrolling in region not obscured by keyboard
    FHServiceView *placeholder = [self placeholder];
    CGFloat scrollYOffset = [placeholder scrollYOffsetForViewUnderKeyboard];
    return scrollYOffset;
}

/**
 * Called to adjust a ppint for the scroll y-offset for the view beneath the keyboard
 *
 * @param (CGPoint) - point in view that needs to be modified
 * @return (CGPoint) - adjusted point in view to take into account any keyboard view scroll
 */
- (CGPoint)adjustLocationForYScrollForViewUnderKeyboard:(CGPoint)originalPoint
{
    CGPoint modifiedPoint = originalPoint;
    
    // if keyboard is visible then adjust for any scroll offset
    if (showKeyboard)
    {
        // adjust for any scrolling in region not obscured by keyboard
        modifiedPoint.y = modifiedPoint.y + [self scrollYOffsetForViewUnderKeyboard];
    }
    
    return modifiedPoint;
}


- (void)showLoupe:(CGPoint)initialLocation
{
    // disable scroll when hide loupe
    [((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController).scrollView disableScroll];
    
    // if keyboard is visible then adjust for any scroll offset within view underneath
    if (showKeyboard)
    {
        // adjust y-position taking into account scroll of view below keyboard
        initialLocation.y = initialLocation.y - [self scrollYOffsetForViewUnderKeyboard];
    }

    // set up magnifier view
    loupeView = [[MagnifierView alloc] initWithFrame:CGRectMake(initialLocation.x - 49 , initialLocation.y - 49, 98, 98)];
    //UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
    
    // disable zoom in magnify mode
    [fhv.fhView disableZoom];
    
    if ( MAGNIFIER_ENABLED )
    {
        // remove pinch gesture recognizer when in magnify mode
        // to allow drag functionality
        [self.view removeGestureRecognizer:pinchGestureRecognizer];
    }
        
    loupeView.center = initialLocation;
    loupeView.delegate = self;
    loupeView.scale = 2;
    loupeView.sourceView = [[FHUIView alloc] initWithFrame:fhv.fhView.frame];
    //    loupeView.sourceView = [self placeholder].fhView;
    DLog(@"SL: RemoteViewPlaceholder=0x%x", (int)[self placeholder]);
    DLog(@"SL: RemoteViewPlaceholder.fhView=0x%x", (int)[self placeholder].fhView);
    
    [[self placeholder] addSubview:loupeView];
    
    //    ((FHUIViewImpl*)[self placeholder].fhView.renderer)
    //    GLint x = [self placeholder].fhView.getViewFrameBuffer;
    //    DLog(@">>>>getViewFrameBuffer %d", x);
}

/**
 * Remove magnifier from view
 */
- (void)hideLoupe
{
    // enable scroll when hide loupe
    [((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController).scrollView enableScroll];
        
    if ( MAGNIFIER_ENABLED )
    {
        // remove pinch gesture recognizer when in magnify mode
        // to allow drag functionality
        if (self.view && pinchGestureRecognizer)
            [self.view addGestureRecognizer:pinchGestureRecognizer];
    }
    
    // re-enable zoom when exit magnify mode
    if (fhv!=nil)
    {
        [fhv.fhView enableZoom];
    }
    
    [loupeView stopCapturing];
    [loupeView removeFromSuperview];
    loupeView = nil;
    
    // only show halo outside of magnify mode
    [fhv showHalo:TRUE];
}


#pragma mark MagnifierViewDelegate methods

- (void)loupeView:(MagnifierView*)_loupeView hideAtPosition:(CGPoint)location click:(BOOL)click
{
    location = [[[self placeholder] fhView] convertPoint:location fromView:self.view];
    
    // adjust location of magnifier to take into account any scroll when keyboard visible
    location = [self adjustLocationForYScrollForViewUnderKeyboard:location];
    
    if (click)
    {
        [[[self placeholder] fhView] updateMousePosition:location.x y:location.y];
        [self singleTapDetected:location];
    }
    
    [self hideLoupe];
}

/**
 * Right hand-side of magnifier clicked - send right mouse-click
 */
- (void)loupeView:(MagnifierView *)view rightHalfClick:(CGPoint)location
{
    CGPoint fhLocation = [[self placeholder].fhView convertPoint:location fromView:self.view];
    //[self hideLoupe];

    // adjust location of magnifier to take into account any scroll when keyboard visible
    fhLocation = [self adjustLocationForYScrollForViewUnderKeyboard:fhLocation];
    
    // send right mouse click
    [SessionManager sendMouseClickMessage:fhLocation mouseButton:kMouseButtonRight toSessionWithKey:self.sessionKey];
}

/**
 * Magnifier clicked - send left mouse-click
 */
- (void)loupeView:(MagnifierView *)view magnifierClick:(CGPoint)location
{
    CGPoint fhLocation = [[self placeholder].fhView convertPoint:location fromView:[self view]];
    //[self hideLoupe];

    // adjust location of magnifier to take into account any scroll when keyboard visible
    fhLocation = [self adjustLocationForYScrollForViewUnderKeyboard:fhLocation];
    
    // send left mouse click
    [SessionManager sendMouseClickMessage:fhLocation mouseButton:kMouseButtonLeft toSessionWithKey:self.sessionKey];
}


- (CGPoint)actualFhViewLocation:(CGPoint)placeholderLocation
{
    return [[self placeholder].fhView convertPoint:loupeView ? [loupeView adjustedCenter] : placeholderLocation fromView:self.view];
}

- (NSArray *)xAccessoryButtonsInfoForKeyBoardType:(KeyboardType) typeForXKeyBoard
{
    switch (typeForXKeyBoard) {
        case kAlphabeticXTabKeyboard:
            return [NSArray arrayWithObjects:
                    //[CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"previous_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"previous_blue.png"  pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:74 tag:kXBackward],
                    //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:-10 tag:-1],
                    //[CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"next_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"next_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:74 tag:kXForward],
                    [CustomButtonInfo customButtonInfoWithTitle:@"Back" width:50 tag:kXBackward],
                    //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:-10 tag:-1],
                    [CustomButtonInfo customButtonInfoWithTitle:@"Forward" width:60 tag:kXForward],
                    //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:-10 tag:-1],
                    [CustomButtonInfo customButtonInfoWithTitle:@"Tab Previous" width:88 tag:kxShiftTab],
                    //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:-10 tag:-1],
                    [CustomButtonInfo customButtonInfoWithTitle:@"Tab Next" width:65 tag:kXTab],
                    [CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:585 tag:kXTab],
                    [CustomButtonInfo customButtonInfoWithTitle:@"Dismiss" width:65 tag:kxMinimizeKeyBoard],
                    nil];
            /*
             case kAlphabeticXExtendedDesktopKeyboard:
             return [NSArray arrayWithObjects:
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"ctrl_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"ctrl_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXCtrl],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"alt_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"alt_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXAlt],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"backtab_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"backtab_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXBackward],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"tab_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"tab_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXForward],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"esc_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"esc_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXEsc],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"del_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"del_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXDel],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"ins_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"ins_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXInsert],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"home_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"home_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXHome],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"end_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"end_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXEnd],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"pgup_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"pgup_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXPageUp],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"pgdn_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"pgdn_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXPageDown],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"leftarrow_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"leftarrow_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:34.0 tag:kXLeft],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"rightarrow_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"rightarrow_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:34.0 tag:kXRight],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"uparrow_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"uparrow_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:34.0 tag:kXUp],
             [CustomButtonInfo customButtonInfoWithTitle:@"fixed"  width:-4 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"downarrow_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"downarrow_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:34.0 tag:kXDown],
             [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:0 tag:kXNone],
             [CustomButtonInfo customButtonInfoWithTitle:nil image:nil backgroundImage:@"fkeys_black.png" backgroundInsets:UIEdgeInsetsMake(0, 0, 0, 0) pressedBackgroundImage:@"fkeys_blue.png" pressedInsets:UIEdgeInsetsMake(0, 0, 0, 0) width:48.0 tag:kXFKeys],
             nil];
             */
        default:
            return nil;
    }
}

#pragma mark - LoginAssistantDelegate methods

- (void) keyboardMustAppear
{
    [self togglekeyboard];
}

- (void) loginAssistantSettingsWillChange:(BOOL) disable {
    
}

/**
 * Login Assistant auto login started
 */
- (void)loginAssistantAutoLoginStarted
{
    DLog(@"Autologin started");
    if (self.isFirstResponder)
        [self resignFirstResponder];
    [self placeholder].autoscroll = NO;
    automateKeyboard = NO;
}

/**
 * Login Assistant auto login ended
 */
- (void)loginAssistantAutoLoginEnded
{
    DLog(@"Login Assistant setup process has been performed");
    [self placeholder].autoscroll = YES;
    automateKeyboard = YES;
}

/**
 * Auto Login has been performed
 */
- (void)autologinHasBeenPerformed
{
    DLog(@"Login Assistant has been performed");
}

/**
 * Called when Login Assistant Animation begins
 */
- (void) loginAssistantAnimationWillBegin
{
    DLog(@"Login Assistant animation is about to begin");
}

/**
 * Called when Login Assistant Animation is completed
 */
- (void) loginAssistantAnimationCompleted
{
    DLog(@"Login Assistant animation has completed");
}


@end
