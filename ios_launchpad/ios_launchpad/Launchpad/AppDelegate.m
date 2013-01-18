//
//  AppDelegate.m
//  Launchpad
//
//  Created by Rich Cowie on 5/15/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "AppDelegate.h"
#import "RootViewController.h"
#import "CommandCenter.h"
#import "MenuCommands.h"
#import "EULAViewController.h"
#import "File.h"
#import "OSMemoryNotification.h"
#import "Launchpad.h"
#import "SessionManager.h"
#import "SettingsUtils.h"
#import "GlobalDefines.h"

#define SHOW_EULA   1

// Keep alive thread for connection in background
#define BK_TIMEOUT_SECONDS 56*10
#define MAXIMUM_WAIT_SECONDS_BEFORE_BACKGROUNDING 5

@implementation AppDelegate
@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize mainController = _mainController;
@synthesize eulaController;

NSString* launchpadServiceUrl = LAUNCHPAD_SERVICE_URL;
BOOL bQuitOnExitEnabled;

#pragma mark -
#pragma mark AppDelegate Class Methods

+ (UIColor*)colorWithHtmlColor:(NSString*)htmlColor {
    NSString* s = [[htmlColor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    UIColor* grayColor = [UIColor colorWithRed:((float) 128.0/255.0)
                                         green:((float) 128.0/255.0)
                                          blue:((float) 128.0/255.0)
                                         alpha:1.0];

    if ([s length] < 6 || !s)
        return grayColor;

    if ([s hasPrefix:@"0X"])
        s = [s substringFromIndex:2];

    if ([s length] != 6)
        return grayColor;

    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString* red = [s substringWithRange:range];

    range.location = 2;
    NSString* green = [s substringWithRange:range];

    range.location = 4;
    NSString* blue = [s substringWithRange:range];

    unsigned int r, g, b;
    [[NSScanner scannerWithString:red] scanHexInt:&r];
    [[NSScanner scannerWithString:green] scanHexInt:&g];
    [[NSScanner scannerWithString:blue] scanHexInt:&b];

    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark -
#pragma mark UIApplicationDelegate Implementation

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{

    /*
    NSString *levelString;
    
    switch (OSMemoryNotificationCurrentLevel()) {
        case OSMemoryNotificationLevelNormal:
            levelString = @"Normal";
            break;
        case OSMemoryNotificationLevelWarning:
            levelString = @"Warning";
            break;
        case OSMemoryNotificationLevelUrgent:
            levelString = @"Urgent";
            break;
        case OSMemoryNotificationLevelCritical:
            levelString = @"Critical";
            break;
        default:
            break;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Memory Warning... Level:%@",levelString] message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];*/
}

/*
 * Session Management - persist user sessions
 */
-(void)saveSession{
    //Save session if valid
    int count = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                  cookiesForURL:[NSURL URLWithString:LAUNCHPAD_SERVICE_URL]] count];
    
    if (count > 0) {
        NSDate* expires = [[[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                             cookiesForURL:[NSURL URLWithString:LAUNCHPAD_SERVICE_URL]] objectAtIndex:0] expiresDate];
        NSDate * currDate = [NSDate date];
        
        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        if([currDate compare:expires] == NSOrderedAscending) {
            //logged in before - cookie cached - no need to login again
            //TODO: change to keychain
            [File writeFile:[[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                              cookiesForURL:[NSURL URLWithString:LAUNCHPAD_SERVICE_URL]] objectAtIndex:0] fileName:[NSString stringWithFormat:@"%@.session.dat",username]];
            
            DLog(@"$$$ Session Saved $$$");
        }
    }
}

-(BOOL)loadSession{
    // load username from settings
    NSString* username = [SettingsUtils getCurrentUserID];
    
    
    if ([File checkFileExists:[File getFilePath:[NSString stringWithFormat:@"%@.session.dat",username]]]) {
        
        NSHTTPCookie *cookie = (NSHTTPCookie *)[File readData:[NSString stringWithFormat:@"%@.session.dat",username]];
        
        NSDate* expires = [cookie expiresDate];
        NSDate * currDate = [NSDate date];
        
        if([currDate compare:expires] == NSOrderedAscending) {
            //logged in before - cookie cached - no need to login again
            DLog(@"$$$ Loaded Previous Session $$$");
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            return YES;
        }
    }
    
    return NO;
}

-(BOOL)validSession{
    
    int count = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                  cookiesForURL:[NSURL URLWithString:launchpadServiceUrl]] count];
    
    if (count > 0) {
        NSDate* expires = [[[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                             cookiesForURL:[NSURL URLWithString:launchpadServiceUrl]] objectAtIndex:0] expiresDate];
        
        NSDate * currDate = [NSDate date];
        
        if([currDate compare:expires] == NSOrderedAscending) {
            //logged in before - cookie cached - no need to login again
            DLog(@"$$$ USING VALID SESSION $$$");
            return YES;
        }
    }
    
    return NO;
}

-(void)deleteSession{
    int count = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                  cookiesForURL:[NSURL URLWithString:launchpadServiceUrl]] count];
    
    if (count > 0) {
        NSHTTPCookie *cookie = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                             cookiesForURL:[NSURL URLWithString:launchpadServiceUrl]] objectAtIndex:0];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        
        DLog(@"$$$ DELETED SESSION $$$");
        
        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        
        [File deleteDirectory:[File getFilePath:[NSString stringWithFormat:@"%@.session.dat",username]]];
    }
}

/*
 * application:didFinishLaunchingWithOptions
 */
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    BOOL bLoginUserUsingStoredCredentials = false;
    

    // default username & password set to nil
    NSString* username = nil;
    NSString* password = nil;
    
    
    // Debug output of NSUserDefaults
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    DLog(@"****** NSUserDefaults ******");
    DLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    DLog(@"****************************");
    
    // Check if the application has been launched previously since it was last installed
    if ([SettingsUtils applicationHasLaunchedPreviously])
    {
        // load username & password from settings
        username = [SettingsUtils getCurrentUserID];
        password = [SettingsUtils getCurrentUserPassword];
        
        if (username && password) {
            // login user using stored credentials
            bLoginUserUsingStoredCredentials = true;
        }
        // App already launched - so no need for cleanup from previous installs
//        CommandCenter* profiles = [CommandCenter get];
        //[profiles saveInstalledProfiles];
//        [profiles loadInstalledProfiles];
    }
    else
    {
        // This is the first launch for this install
        // so clean up any profiles remaining from previous installs
        //CommandCenter* profiles = [CommandCenter getFresh];
        //[profiles saveInstalledProfiles];
        
        // delete any existing settings
        [SettingsUtils deleteSettings];

        // Set boolean value in user defaults to signify application has been launched
        [SettingsUtils setApplicationHasLaunchedPreviously:YES];
    }
    
    // Check for override Studio URL
    NSString* StudioURL = [defaults stringForKey:kStudioUrlKey];
    if (StudioURL!=NULL)
    {
        // make sure URL is not an empty string
        if ([StudioURL length] > 0){
            if ([defaults objectForKey:kLastStudioUrlKey]) {
                if (![StudioURL isEqualToString:[defaults objectForKey:kLastStudioUrlKey]]) {
                    launchpadServiceUrl = [defaults objectForKey:kLastStudioUrlKey];
                    [self deleteSession];
                    // clear PIN, Username & Password from settings
                    [SettingsUtils clearCurrentUserPIN];
                    [SettingsUtils clearCurrentUserID];
                    [SettingsUtils clearCurrentUserPassword];
                    [SettingsUtils clearSelectedProfileId];
                    [SettingsUtils clearDefaultProfileId];
                    bLoginUserUsingStoredCredentials = false;
                }
            }
            launchpadServiceUrl = StudioURL;
        }
    }
    
    // Save launchpad url to defaults
    [defaults setObject:launchpadServiceUrl forKey:kLastStudioUrlKey];
    [defaults synchronize];
    

    // get background mode setting
    bQuitOnExitEnabled = [defaults boolForKey:kQuitOnExitKey];
    
    // TODO: remove any redundant data
    NSDictionary* appDefaults = [NSDictionary dictionaryWithObjects:
                                 [NSArray arrayWithObjects:
                                  @"https://fh.company.com",
                                  @"https://piqa.company.com",
                                  @"JSON",
                                  @"NO",
                                  @"NOT USED",
                                  @"NOT USED",
                                  nil]
                                                            forKeys:[NSArray arrayWithObjects:
                                                                     @"reverse_proxy_url",
                                                                     @"reverse_proxy_domain",
                                                                     @"url_file_type",
                                                                     @"cache_proxy",
                                                                     @"xml_menu_config",
                                                                     @"xml_menu_services",nil]];

    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    _viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];

    // Show EULA
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasAcceptedEULAKey])
    {
#if SHOW_EULA
        // if showing EULA then don't attempt to autologin, since user not yet signed in
        bLoginUserUsingStoredCredentials = false;
        eulaController = [[EULAViewController alloc] initWithNibName:( @"EULAViewController" ) bundle:nil];
        eulaController.appDelegate = self;
        [self.window setRootViewController:eulaController];
#else
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasAcceptedEULAKey];
#endif
    }

    // TODO: remember selected profile id 
    // Remove the selected profile identifier
    /* This resets the selection to the default on startup */
    // [SettingsUtils clearSelectedProfileId];
    
    // Attempt to autologin
    if (bLoginUserUsingStoredCredentials)
    {
        
        //Attempt to load session if we have a username and password
        [self loadSession];
        
        // if there is a valid username & password
        if ((![self validSession] && username && password) || (username == nil || password == nil))
        {
            // attempt to login user to studio to obtain profiles
            [_viewController loginUserToStudio:username pass:password];
        }else{
            
            [_viewController reloadProfilesList:YES];
            [_viewController showPinView:0];
        }
    }

    DLog(@"DID FINISH LAUNCHING");    

    return YES;
}

UIBackgroundTaskIdentifier bgTask;

/*
 * Handle Application resuming from background
 */
- (void)applicationWillEnterForeground:(UIApplication *)application {
    DLog(@"WILL ENTER FOREG:%@", _viewController);
    
        //Does not need to be on seperate thread.
        if (bgTask) {
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    
    
    // resume now done after PIN is entered in RootViewController
//    // resume connection of active view
//    [_mainController resumeConnection];
}


/*
 * resume connection on active view
 */
- (void)resumeActiveConnection
{
    // resume connection of active view
    [_mainController resumeConnection];
}


/*
 * applicationWillTerminate
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    DLog(@"WILL TERMINATE");
    
    //Attempt to save the previous users session
    [self saveSession];
    
    //Attempt to save installed profiles before crash
    [[CommandCenter get] saveInstalledProfiles];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // ensure any pending service connections complete before entering background
    // since any OpenGL commands during set up after going into background will
    // cause a crash
    int waitCount=0;
    while ((pendingServiceConnections!=0) && (waitCount<MAXIMUM_WAIT_SECONDS_BEFORE_BACKGROUNDING))
    {
        DLog(@"Waiting on connections...%i", waitCount);
        sleep(1);
        waitCount++;
    }
    // clear pending service connections
    pendingServiceConnections = 0;
    
    // hide status bar when settings are not visible
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    DLog(@"Completed connections");
    // pause connection of any current active session
    [_mainController pauseConnection];
    DLog(@"WILL RESIGN ACTIVE");
    // wait until any view being created has finished
    while ([SessionManager isCreatingSessionView])
    {
        DLog(@"Waiting on session views...");
        sleep(1);
    }

    // ensure pause connection of any current active session
    [_mainController pauseConnection];
    
    // is quit on exit enabled
    if (bQuitOnExitEnabled)
    {
        // Shut down all sessions
        [[MenuCommands get] clearAllSessions];
    }
    
    
    // show PIN view sometimes crashes if closing app as soon as session is opening
    // resulting in gpus_ReturnNotPermittedKillClient error
    [_viewController showPinView:0];
    
    glFinish(); // clear any Open GL commands when going into background
    
}

/*
 * Handle Application going into background
 */
- (void)applicationDidEnterBackground:(UIApplication *)application {
    DLog(@"DID ENTER BACKG:%@", _viewController);
    
    [[CommandCenter get] saveInstalledProfiles];
    
    //Save the session for possible next start
    [self saveSession];
    
    // dismiss any login assistant alert dialog
    [MenuViewController dismissLoginAssistantDisabledAlert];
    
    // if there are open sessions then keep alive
    if ([MenuCommands getNumberOfOpenCommands] > 0) {
    
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    

        // Start the long-running task and return immediately -- need thread so not to block main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (int i = 0; i < BK_TIMEOUT_SECONDS; i++)
            {
                if (bgTask)
                    [NSThread sleepForTimeInterval:1];
                else
                    break;
                DLog(@"Sleep for %d",i);
            }
                    
            if (bgTask) {
                DLog(@"End of Background Thread....");
                // Close any open sessions
                //[FHConnectionUtility terminateAllSessionConnections];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SessionBackgroundTimeout"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[MenuCommands get] clearAllSessions];
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
                return;
            }
        });
    }
}

/*
 * Application became active
 */
- (void)applicationDidBecomeActive:(UIApplication *)application {
    DLog(@"DID BECOME ACTIVE");
}

/*
 * Accepted EULA
 * Called when user accepts EULA - removes EULA screen allowing user to continue
 */
- (IBAction) acceptedEULA:(id)sender
{
    // replace EULA view
    [self.window setRootViewController:_viewController];
    // save that user accepted EULA
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasAcceptedEULAKey];
    // we won't need eulaController again when it is closed
    eulaController = nil;
    
}


@end