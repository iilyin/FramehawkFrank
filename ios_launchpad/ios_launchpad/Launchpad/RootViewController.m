//
//  LaunchpadViewController.m
//  Launchpad
//
//  Created by Rich Cowie on 5/15/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "AppDelegate.h"
#import "CommandCenter.h"
#import "RootViewController.h"
#import "MenuCommands.h"
#import "ProfileDefines.h"
#import "File.h"
#import "ImageAnimatorViewController.h"
#import "ProfileStorageManagement.h"
#import "SettingsUtils.h"
#import "StringUtility.h"
#import "ServiceScrollView.h"
#import "GlobalDefines.h"

// Profile initial selection dialog positioning
#define PROFILE_INITIAL_SELECTION_DIALOG_X      300
#define PROFILE_INITIAL_SELECTION_DIALOG_Y      40


#define FULL_SCREEN_WIDTH                       1024.0
#define FULL_SCREEN_HEIGHT                      768.0

// transition animation flag
//#define SPLASH_ANIMATION_ON          

// Alert dialog identifiers
typedef enum {
    kLoginInvalidErrorTag       = 1,
    kLoginConnectionErrorTag    = 2,
    kProfilesRetrieveErrorTag   = 3,
}LoginAlertDialogs;

// Profile retrieve dialog buttons
typedef enum {
    kProfileRetrieveRetryButton,
    kProfileExitRetryButton,
}ProfileRetrieveErrorDialogButtons;


// Framehawk Blue HTML color string
static NSString *const sFramehawkBlueHtmlColor  = @"112651";

@interface RootViewController () {
}

@property (strong, nonatomic) UIView* backgroundSkinColor;
@property (strong, nonatomic) UIImageView* backgroundImage;
@property (strong, nonatomic) UIImageView *backgroundLogo;

@end


@implementation RootViewController

@synthesize backgroundSkinColor;
@synthesize backgroundImage, backgroundImagePng;
@synthesize backgroundLogo;
@synthesize currentSessionIndex;
@synthesize scrollView;
@synthesize loginViewController;
@synthesize profileSelectionViewController;
@synthesize menuViewController;
@synthesize pinScreen;
@synthesize bDisplayingPINScreen;
@synthesize bforceLoginScreen;


- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    //Make sure profile selection is always around
    // ...And show the profile selection view
    if (!profileSelectionViewController){
        profileSelectionViewController = [[ProfileSelectionViewController alloc] initWithFrame:CGRectZero withMode:kProfileSelectionInitialSelectionMode];
        profileSelectionViewController.delegate = self;
        
        if ([(AppDelegate *)[UIApplication sharedApplication].delegate validSession] && [self hasPin]) {
            bUserAuthenticatedFailed = NO; //assume failed
        }else{
            bUserAuthenticatedFailed = YES; //assume failed
        }
        
        bforceLoginScreen = NO;
    }
    
    return self;
}


#pragma mark -
#pragma mark LaunchpadViewController Implementation


- (NSInteger)currentSessionIndex {
    return scrollView.currentIndex;
}


- (void) onProfileSelection {}


#pragma mark -
#pragma mark UI Events

/*
 * Login user to studio - login with specified credentials to studio and get profiles
 */
- (void)loginUserToStudio:(NSString*)username pass:(NSString*)password
{
    static BOOL bCurrentlyWaitingOnLoginResponse = false;
    
    // prevent multiple login attempts at same time
    if (bCurrentlyWaitingOnLoginResponse)
        return;
    
    // set flag for waiting on login response
    bCurrentlyWaitingOnLoginResponse = TRUE;
    
    // Get the command center
    CommandCenter* c = [CommandCenter get];

    // Declare the activity indicator
    UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    // After login...
    FHLoginResponse loginResponse = ^(NSDictionary* response, NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            // remove activity spinner from view
            [activity removeFromSuperview];

            // set flag for waiting on login response
            bCurrentlyWaitingOnLoginResponse = FALSE;

            // dismiss login view omce login submitted
            [loginViewController.view removeFromSuperview];
            loginViewController = nil;
            
            // If the login attempt was successful...
            if((!error) && ([[response valueForKey:@"success"] intValue] == 1)) {
                
                // set user authentication failed to true
                bUserAuthenticatedFailed = false;

                // Store user id & password if login was successful
                [SettingsUtils saveCurrentUserID:username];
                [SettingsUtils saveCurrentUserPassword:password];
                
                // Set proxy username & password for that will be sent to any secure proxy that is needed to create a connection
                [SettingsUtils saveStringSetting:username withKey:kSettingsProxyUserNameKey];
                [SettingsUtils saveStringSetting:password withKey:kSettingsProxyPasswordKey];
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate saveSession];
                
                [self reloadProfilesList:NO];

                [self showPinView:0];
            }
            else if (!error) {
                // display warning alert for invalid login
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Login Error!"
                                                                  message:@"Incorrect User Id or Password."
                                                                 delegate:self
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                [message setTag:kLoginInvalidErrorTag];
                
                [message show];
            }
            else if ((error) || ([[response valueForKey:@"success"] intValue] != 1)) {
                
                NSString* d = error.domain;
                NSInteger c = error.code;
                
                // Display an alert
                NSString* t = @"Error";
                NSString* m = @"An error occurred.  Please try again or contact support.";
                if (([d compare:@"NSURLErrorDomain"] == NSOrderedSame && (c == -1003 || c == -1004)) || ![CommandCenter networkIsAvailable]) {
                    t = @"Network Error";
                    m = @"The server could not be reached at this time.  Please check your network connections and try again or contact support.";
                }
                UIAlertView* av = [[UIAlertView alloc] initWithTitle:t
                                                             message:m
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
                [av setTag:kLoginConnectionErrorTag];
                [av show];
            }
        });
    };

    // set up position of activity animation centered in screen
    [activity sizeToFit];
    CGRect f = activity.frame;
    CGRect b = self.view.bounds;
    f.origin.x = (b.size.width - f.size.width)/2;
    f.origin.y = (b.size.height - f.size.height)/2;
    activity.frame = f;
    [self.view addSubview:activity];
    [activity startAnimating];

    // Attempt login
    [c loginUsername:username password:password response:loginResponse];
}

/*
 * Reload Profiles List from Studio
 */
- (void)reloadProfilesList:(BOOL)attemptFileLoad
{
    if (attemptFileLoad) {
        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        if ([[CommandCenter get] loadSavedProfileList:username]) {
            return;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
    // Get the command center
    CommandCenter* c = [CommandCenter get];
    
    // get list of profiles
    FHGetProfilesListResponse getProfilesListResponse = ^(NSData* response, NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // If the get profiles list attempt was successful...
            if ((!error) && (response!=nil)) {
                bErrorDownloadingProfiles = false;
                // get menu command center
                CommandCenter* c = [CommandCenter get];
                // parse the list of profiles
                [c parseProfilesListData:response];
                // build the launchpad menu
                [c buildLaunchPadMenu];
                                
            }
            else {
                // otherwise error handling for loading profiles
                bErrorDownloadingProfiles = true;
            }
            
            // only process profiles if already dismissed pin view
            if (!bDisplayingPINScreen)
                [self processDownloadedProfiles];
            
        });
    };

    // Attempt get profiles list
    [c getProfilesList:getProfilesListResponse];
    });
        
}


/*
 * When login button clicked - login with specified credentials
 */
- (void)loginButtonClicked
{
    // Obtain data from the login view
    NSString* username = loginViewController.userIdField.text;
    NSString* password = loginViewController.passwordField.text;

    // attempt to login user to studio to obtain profiles
    [self loginUserToStudio:username pass:password];
}


#pragma mark -
#pragma mark UIViewController Implementation


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


- (void)loadView {
    
    // Configure my view
    CGRect  viewRect = CGRectMake(0.0, 0.0, FULL_SCREEN_WIDTH, FULL_SCREEN_HEIGHT);
    self.view = [[UIView alloc] initWithFrame:viewRect];
    
    // Background Color View
    backgroundSkinColor = [[UIView alloc] init];
    backgroundSkinColor.frame = CGRectMake(0.0, 0.0, FULL_SCREEN_WIDTH, FULL_SCREEN_HEIGHT);
    backgroundSkinColor.backgroundColor = [UIColor colorWithRed:0.114 green:0.31 blue:0.5 alpha:1];
    
    // Background Image View
    backgroundImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    // Background Logo Image View
    backgroundLogo = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    // Framehawk Scroll View
    scrollView = [[ServiceScrollView alloc] initWithFrame:self.view.frame];    
    // Assemble view heirarchy
    [self.view addSubview:backgroundSkinColor];
    [self.view addSubview:backgroundImage];
    [self.view addSubview:backgroundLogo];
    [self.view addSubview:scrollView];
    
    // Obtain the CommandCenter
    CommandCenter* c = [CommandCenter get];
    
    // Register to observe the command center's state
    /* This enables me to update the state of the application based on the current profile state */
    [c addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
    
    // Obtain the menu
    MenuCommands* m = [MenuCommands get];
    
    // Register to observe the menu's state
    /* This enables me to update the state of the application based on the current profile state */
    [m addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
    
}


- (void)viewDidAppear:(BOOL)animated {

}

- (void)viewDidLoad {
#ifdef PROFILE_LOGIN_ENABLED 
    [self showLoginView];
#else
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [self didSelectProfile: [defaults objectForKey:kProfileIdKey] fromController:nil ];
#endif
}


- (void)viewDidUnload {
    CommandCenter* c = [CommandCenter get];
    [c removeObserver:self forKeyPath:@"state"];
    
    MenuCommands* m = [MenuCommands get];
    [m removeObserver:self forKeyPath:@"state"];
}


#pragma mark -
#pragma mark Observers

- (BOOL) hasPin {
    // load PIN from settings
    NSString* upin = [SettingsUtils getCurrentUserPIN];
    return (upin && upin.length == 4);
}

/*
 * Show user login dialog
 */
- (void) showLoginView {
    
    // If the the user has signed in previously, force them to sign in using the previous credentials
    // load username from settings
    NSString* username = [SettingsUtils getCurrentUserID];
    // load password from settings
    NSString* password = [SettingsUtils getCurrentUserPassword];
    
    // if don't have a PIN or there was an error with the user login...
    if (((![self hasPin]) && bUserAuthenticatedFailed) || bforceLoginScreen)
    {

        // Initialize the login view
        loginViewController = [[ProfileLoginViewController alloc] init];
        if (username) {
            UITextField* f = loginViewController.userIdField;
            f.text = username;
            // if authentication failed then allow user to re-enter username
            f.enabled = (bUserAuthenticatedFailed || bforceLoginScreen ? YES : NO);
        }
        if (password) {
            UITextField* f = loginViewController.passwordField;
            f.text = password;
            // if authentication failed then allow user to re-enter password
            f.enabled = (bUserAuthenticatedFailed || bforceLoginScreen ? YES : NO);
        }
        
        // Wire events to the login view
        [loginViewController.loginButton addTarget:self action:@selector(loginButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                        bforceLoginScreen = NO;
        // Show the login view
        [self.view addSubview:loginViewController.view];
    }
    else
    {
        // load profiles
        // Obtain the CommandCenter
        CommandCenter* c = [CommandCenter get];
        [c buildLaunchPadMenu];
    }
}

/**
 * Show PIN entry dialog
 */
- (void) showPinView:(NSInteger) num {
    // if not logging in, and PIN screen is not currently displayed...
    if ((!loginViewController) && (!bDisplayingPINScreen)){
        
        // dismiss any active keyboard for current session
        FHServiceViewController* svc  = (FHServiceViewController*)[[MenuCommands get] getCurrentSession];
        [svc hideKeyboard];
        
        // display PIN screen
        bDisplayingPINScreen = true;
        DLog(@"showPinView!!!!!!!!!!!!!!!!"); 
        // password lock
        pinScreen = [[PINViewController alloc] init];
        pinScreen.delegate = self;
        pinScreen.reset = (num == 1);
        [self.view addSubview:pinScreen.view];
        
    }
}


/**
 * Remove PIN entry dialog
 */
- (void) removePinView
{
    // remove PIN screen
    [[pinScreen view] removeFromSuperview];
    pinScreen = nil;
    // display PIN screen
    bDisplayingPINScreen = false;
}


- (void) refreshBackground {
    
    if(!self.menuViewController)
    {
       // [backgroundImage setImage:nil];
        [self.backgroundLogo setImage:nil];
        backgroundImage.image = [UIImage imageNamed:@"launchpad_splash"]; 
    }
    else 
    {
        // Obtain the latest profile
        MenuCommands* m = [MenuCommands get];
        NSDictionary* p = m.launchpadProfile;
        
        NSString* backColorStr = nil;
        UIImage* backScreen = nil;
        UIImage* backLogo = nil;
        
        // Service splash screen background
        // get profile skin
        NSMutableDictionary *skin = [p objectForKey:kProfileSkinKey];
        // get service splash background color
        backColorStr = [skin objectForKey:kProfileServiceSplashBackgroundColorKey];
        // - If the profile has a background color, use it
        self.backgroundSkinColor.backgroundColor = self.view.backgroundColor = [AppDelegate colorWithHtmlColor:backColorStr ? backColorStr : sFramehawkBlueHtmlColor];
        
        // Service Splash Logo Image
        NSString* splashBGLogoImage = [[skin objectForKey:kProfileServiceSplashLogoKey] URLEncodedString];
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:splashBGLogoImage] path]]]){
            backLogo = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:splashBGLogoImage] path]]];
        }
        else{
            NSURL* splashBGLogoImageURL = [NSURL URLWithString:splashBGLogoImage];
            backLogo = [UIImage imageWithData: [NSData dataWithContentsOfURL:splashBGLogoImageURL]];
        }
        self.backgroundLogo.image = backLogo;
        
        // Service Splash Background Image
        NSString* splashBGImage = [[skin objectForKey:kProfileServiceSplashBackgroundKey] URLEncodedString];
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:splashBGImage] path]]]){
            backScreen = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:splashBGImage] path]]];
        }else{
            
            NSURL* splashBGImageURL = [NSURL URLWithString:splashBGImage];
            if(splashBGImageURL)
            {
                NSData* d = [NSData dataWithContentsOfURL:splashBGImageURL];
                if(d) {
                    backScreen = [UIImage imageWithData: [NSData dataWithContentsOfURL:splashBGImageURL]];
                }
            }
        }
        
        if(!backScreen)
        { 
            // use default image if null 
            backScreen = [UIImage imageNamed:@"launchpad_splash"]; 
        }
        
        backgroundImage.image =backScreen;
        
    }
}

- (void) updateBackgroundFrame {
    
#ifdef SPLASH_ANIMATION_ON
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:1];
    [UIView setAnimationTransition:UIViewAnimationOptionTransitionCrossDissolve forView:self.view cache:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    self.view.alpha = 1; 
    
#endif
    
    if(self.backgroundLogo.image){
        // position logo centered in view
        int logoWidth   = self.backgroundLogo.image.size.width;
        int logoHeight  = self.backgroundLogo.image.size.height;
        int logoX       = (self.backgroundImage.image.size.width - logoWidth)/2;
        int logoY       = (self.backgroundImage.image.size.height - logoHeight)/2;
        self.backgroundLogo.frame = CGRectMake(logoX, logoY, logoWidth, logoHeight);
    }
    
    if (backgroundImage.image) {
        [backgroundImage sizeToFit];
        CGRect f = backgroundImage.frame;
        f.origin.x = 512.0 - f.size.width/2;
        f.origin.y = 384.0 - f.size.height/2;
        backgroundImage.frame = f;
        self.backgroundImagePng = backgroundImage.image; 
    }
    
#ifdef SPLASH_ANIMATION_ON
    [UIView commitAnimations];
#endif    
    
}


- (void) refreshProfile {
    
    if(self.menuViewController){
#ifdef SPLASH_ANIMATION_ON
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:1];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseOut];
        [UIView setAnimationTransition:UIViewAnimationOptionTransitionCrossDissolve forView:self.view cache:YES];
        [UIView setAnimationDidStopSelector:@selector(updateBackgroundFrame)];    
        
        self.view.alpha = 0.3;
        self.backgroundLogo.frame = CGRectMake(0,0,300, 200);
        self.backgroundLogo.center = CGPointMake(512, 384); 
        self.backgroundImage.frame = CGRectMake(0,0,1024*0.9, 768*0.9);
        self.backgroundImage    .center = CGPointMake(512, 384); 
        [self refreshBackground];
        
        [UIView commitAnimations];
#else
        [self refreshBackground];
        [self updateBackgroundFrame];
#endif
    }
    else {
        [self refreshBackground];
        [self updateBackgroundFrame];
    }
    
}


- (void) showLoadingSpinner {
    
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.frame = CGRectMake(20, 20, 50, 50);
    spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                UIViewAutoresizingFlexibleRightMargin |
                                UIViewAutoresizingFlexibleTopMargin |
                                UIViewAutoresizingFlexibleBottomMargin);
    
    
    UIImageView* v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"preloader_bg.png"]];
    [v sizeToFit];
    v.frame = CGRectMake(512-v.frame.size.width/2, 60, v.frame.size.width, v.frame.size.height); 
    
    v.tag = 1010;
    
    [self.view addSubview:v];    
    [self.view bringSubviewToFront:v];
    
    [v addSubview:spinner];
    
    [spinner startAnimating];
    
    [self performSelector:@selector(removeLoadingSpinner) withObject:nil afterDelay:1];
}

- (void) removeLoadingSpinner {
    UIView* v1 = [self.view viewWithTag:1010];
    [v1 removeFromSuperview];
    v1 = nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    // If the observed object is the CommandCenter...
    if ([object isKindOfClass:[CommandCenter class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is profile load completion...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if ([value integerValue] == CC_MENU_COMPLETE) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    // Hide the profile selection view if applicable
                    [self removeProfileSelectionFromView];
                    
                    // Refresh my profile aspects
                    [self refreshProfile];
                    
                });
            }
            
            // Handle stored profile was invalid (not found)
            if ([value integerValue] == CC_PROFILE_INVALID) {
                DLog(@"Invalid Profile on Launch!\n");
                
                // get profile Id
                NSString* profileId = [SettingsUtils getDefaultProfileId];
                NSString* selectedProfileId = [SettingsUtils getSelectedProfileId];

                // Remove previous default profile
                [SettingsUtils clearDefaultProfileId];
                [SettingsUtils clearSelectedProfileId];
                
                // remove profile from installed profiles list
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [ProfileStorageManagement deleteProfile:profileId];
                    [ProfileStorageManagement deleteProfile:selectedProfileId];
                    
                    CommandCenter* profiles = [CommandCenter getFresh];
                    [profiles saveInstalledProfiles];
                });
                
                
                // warn about invalid profile
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Profile!" message:[NSString stringWithFormat:@"Profile is no longer available!"] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                });
                
                // force reload of profiles
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self reloadProfilesList:YES];

                });
            }
            
        }
    }
    
    // Elsewise if the observed object is the menu...
    else if ([object isKindOfClass:[MenuCommands class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is application ready to open...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if ([value integerValue] == MC_SESSION_READY_TO_OPEN) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                });
            }
        }
    }
}

/*
 * Show page control
 */
-(void) showPageControl
{
    [[self scrollView] showPageControl];
}


/*
 * Remove profile selection from view
 */
-(void) removeProfileSelectionFromView
{
    // Hide the profile selection view if applicable
    if ([[profileSelectionViewController view] window]) {
        [profileSelectionViewController.view removeFromSuperview];
        [profileSelectionViewController dismissViewControllerAnimated:YES completion:nil];
        
        // adjust menu drawer frame size (removing extra size for profile view)
        [self.menuViewController updateFrame];
        
        //profileSelectionViewController = nil;
    }
}

-(void) setprofileSelectionViewController:(ProfileSelectionViewController*)p
{
    profileSelectionViewController = p;
}


- (BOOL) hasProfile {
    
    // Update user preferences
    if([SettingsUtils getSelectedProfileId] == nil || bErrorDownloadingProfiles)
        return NO;
    
    return YES;
}


- (void) shouldDismissPinView:(PINViewController *)control {
    
    if(control){
        [control.view removeFromSuperview];
        control = nil;
        bDisplayingPINScreen = false;
    }
    
    // resume active connection
    [(AppDelegate *)[UIApplication sharedApplication].delegate resumeActiveConnection];

    // show any pending error dialogs for current session
    FHServiceViewController* svc  = (FHServiceViewController*)[[MenuCommands get] getCurrentSession];
    [svc displayAnyConnectionErrorDialogs];
    
    // check if settings are active
    [menuViewController displayStatusBarIfSettingsActive];
    
    [self processDownloadedProfiles];
}

- (void) didSelectPinResetFromSettings 
{
    [self showPinView:1];
}

/*
 * Process Downloaded Profiles
 */
 - (void) processDownloadedProfiles
{
     if([self hasProfile])
     {
         [self didSelectProfile: [SettingsUtils getSelectedProfileId] fromController:nil];
     }
     else 
     {
         // display error if unable to download profiles
         if (bErrorDownloadingProfiles)
         {
             NSString *t,*m;
             if (![CommandCenter networkIsAvailable]) {
                 t = @"Connection Error";
                 m = @"Unable to retrieve profile list – you appear to not have an internet connection.";
             }else{
                 t = @"Unable to retrieve profiles list!";
                 m = @"Please try again or check with your administrator";
             }
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:t message:m delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Exit", nil];
             [alert setTag:kProfilesRetrieveErrorTag];
             [alert show];
         }
         else
         {
             // if user authentication succeeded then
             if (!bUserAuthenticatedFailed)
             {  // show profile selection
                [self showProfileSelection];
             }
         }
     }
}

/*
 * Show Profile Selection
 */
- (void) showProfileSelection
{
     if([[profileSelectionViewController view] window] == nil) {
         
         profileSelectionViewController.view.frame = CGRectMake(
                                                                PROFILE_INITIAL_SELECTION_DIALOG_X,
                                                                PROFILE_INITIAL_SELECTION_DIALOG_Y,
                                                                profileSelectionViewController.view.frame.size.width,
                                                                profileSelectionViewController.view.frame.size.height);
         
         [profileSelectionViewController clearTable];
         [self.view addSubview:profileSelectionViewController.view];
     }
}


/*
 * User selected a profile from profile selection dialog
 * profile can be NSDictionary* or NSNumber 
 */
- (void) didSelectProfile: (id) profile fromController:(ProfileSelectionViewController *)control{
    
    // THE FOLLOWING ORDER SHOULD NOT BE CHANGED! 
    
    BOOL needMenuBuild = (control != nil); 
    
    // remove profile selection from view
    [self removeProfileSelectionFromView];
    if(self.menuViewController){
        [self.menuViewController closeMenu];
    }
    
    if ([profile isKindOfClass:[NSNumber class]]) {
        if (![[[CommandCenter get] installedProfiles] objectForKey:profile]) {
            if (![CommandCenter networkIsAvailable]) {
                // Display an alert
                NSString* t = @"Network Error";
                NSString* m = @"The server could not be reached at this time.  Please check your network connections and try again or contact support.";
                
                UIAlertView* av = [[UIAlertView alloc] initWithTitle:t
                                                             message:m
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
                [av setTag:kLoginConnectionErrorTag];
                [av show];
                return;
            }
        }else{
            [MenuCommands get].launchpadProfile = [[CommandCenter get].installedProfiles objectForKey:profile];
        }
    }
    
    if(!profile /*|| [MenuCommands get].launchpadProfile == nil*/)
    {
        return;
    }//else{
//        [[CommandCenter get] saveInstalledProfiles];
//    }
    
    
    [self showLoadingSpinner];

    if(needMenuBuild) {

        [[CommandCenter get] buildLaunchPadMenu];
    }
    
    [self performSelector:@selector(updateMenuViewController) withObject:nil afterDelay:0];
}


- (void) updateMenuViewController {
    DLog(@"updateMenuViewController!!!!!!!!!!!!!!!!"); 

    // If a profile has been selected and the menu has not been added, do so now
    if (!self.menuViewController) {
        self.menuViewController = [[MenuViewController alloc] initWithNibName:nil bundle:nil];
        self.menuViewController.delegate = self;
        // start menu onscreen initially
        [self.menuViewController updateFrame];
        [self.menuViewController closeMenu];
        [self.view addSubview:menuViewController.view];
        [self refreshProfile];
    }
    

    [self.menuViewController openMenu];
    [self.menuViewController viewDidAppear:NO];
    //best place to save profile
    [[CommandCenter get] saveInstalledProfiles];
}


/**
 * remove MenuViewController
 */
- (void) removeMenuViewController {
    
//    [self.menuViewController.view removeFromSuperview];
//    self.menuViewController =nil;
    
    // TODO: Show profile selection
//    [self showProfileSelection];
//    profileSelectionViewController
}


/*
 * User cancelled profile selection from profile selection dialog
 */
- (void) didCancelProfileSelection:(ProfileSelectionViewController *)control{
    
    // remove profile selection dialog
    [self.menuViewController removeProfileSelection];
}

/*
 * Handle button presses for alert views
 */
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        switch (alertView.tag)
        {
            // User login response
            case kLoginInvalidErrorTag:
            case kLoginConnectionErrorTag:
            {
                // dismiss dialog and allow user to enter new username & password
                bUserAuthenticatedFailed = true;
                [self showLoginView];
                
            }
            break;
                
            // Profiles retrieve response
            case kProfilesRetrieveErrorTag:
            {
                switch (buttonIndex)
                {
                    case kProfileRetrieveRetryButton:
                        // retry downloading profiles
                        [self reloadProfilesList:YES];
                    break;
                    case kProfileExitRetryButton:
                        // exit application
                        exit(0); 
                    break;
                }
            }
            break;

            default:
            break;
        }
    
}


@end
