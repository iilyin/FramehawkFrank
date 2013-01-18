//
//  NavigationCommands.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/14/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "AppDelegate.h"
#import "CommandCenter.h"
#import "BrowserServiceViewController.h"
#import "FHServiceViewController.h"
#import "SessionManager.h"
#import "MenuCommands.h"
#import "GlobalDefines.h"
#import "ProfileDefines.h"
#import "FHServiceDefines.h"
#import "StringUtility.h"
#import "SettingsUtils.h"

#define FramehawkFrame CGRectMake(0,0,1024,768)
static MenuCommands *mCenter;
@implementation MenuCommands
@synthesize state = mState;
@synthesize error, cmds = _cmds;
@synthesize launchpadProfile;
@synthesize selectedCommand;
@synthesize closeIndex;
@synthesize openSessions;
@synthesize menuGroupTextColor;
@synthesize menuUnselectedTextColor;
@synthesize menuSelectedTextColor;
@synthesize menuRowDividerImage;
@synthesize cookiesAreSet;
@synthesize goToIndex;


#pragma mark -
#pragma mark Class Methods


+(MenuCommands *)get{
    if (nil == mCenter) {
        mCenter = [[MenuCommands alloc] init];
        mCenter.cookiesAreSet = NO;
        mCenter.state = MC_IDLE;
        
        // Register the new instance to observe the command center
        CommandCenter* c = [CommandCenter get];
        [c addObserver:mCenter forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    }
    return mCenter;
}

- (NSArray*) cmds 
{
    if(!_cmds)
    {
        [self setUpCommandForCurrentProfile];
    }
    
    return _cmds;
}

- (void)clearCommandsWhenSwitchingProfile
{
    _cmds = nil;
}

- (void)setUpCommandForCurrentProfile
{
    DLog(@">>>> setUpCommandForCurrentProfile");

    // create command list from currently loaded profile
    NSMutableArray* commandsArray = [[NSMutableArray alloc] init];
    
    // get button groups from current profile information
    NSDictionary* p = [MenuCommands get].launchpadProfile;
    // get profile skin
    NSMutableDictionary *skin = [p objectForKey:kProfileSkinKey];
    
    NSArray *buttonGroups = [p objectForKey:kProfileButtonGroupsKey];
    
    // get total button groups
    int totalButtonGroups = [buttonGroups count];
    
    // parse list of buttons for all button groups
    for (int groupIndex=0; groupIndex<totalButtonGroups; groupIndex++)
    {
        // get button information from current button group
        NSMutableDictionary* buttonGroup = [buttonGroups objectAtIndex:groupIndex];
        NSArray *buttons = [buttonGroup objectForKey:kProfileButtonsKey];
        
        // get total buttons in this group
        int totalButtonsInGroup = [buttons count];
        
        // generate array of button commands for this group
        for (int buttonIndex=0; buttonIndex<totalButtonsInGroup; buttonIndex++)
        {
            // get current button
            NSMutableDictionary* button = [buttons objectAtIndex:buttonIndex];
            
            // create command information
            NSMutableDictionary* commandInfo = [[NSMutableDictionary alloc] init];

            // add service type
            NSNumber* serviceType = [button objectForKey:kProfileServiceTypeKey];
            if (nil!=serviceType)
                [commandInfo setObject:serviceType forKey:kFramehawkServiceTypeKey];
            
            // add browser url
            NSString* browserUrl = [button objectForKey:kProfileBrowserUrlKey];
            if (nil!=browserUrl)
            {
                switch ([serviceType integerValue]) {
                    case kNativeBrowserService:
                        // set up URL for native browser
                        [commandInfo setObject:browserUrl forKey:kWebBrowserURLKey];
                        break;
                        
                    default:
                        // set up URL for framehawk browser
                        [commandInfo setObject:browserUrl forKey:kFramehawkWebURLKey];
                        break;
                }
            }
            // add service url
            NSString* serviceUrl = [button objectForKey:kProfileServiceUrlKey];
            if (nil!=serviceUrl)
                [commandInfo setObject:serviceUrl forKey:kFramehawkURLKey];
            
            // add service id
            NSString* serviceId = [button objectForKey:kProfileServiceIdKey];
            if (nil!=serviceId)
                [commandInfo setObject:serviceId forKey:kFramehawkServiceIdKey];

            // add supported regions
            NSNumber* serviceRegion = [button objectForKey:kProfileServiceRegionKey];
            if (nil!=serviceRegion)
                [commandInfo setObject:serviceRegion forKey:kFramehawkServiceRegionKey];
            
            // add service arguments
            NSString* serviceArguments = [button objectForKey:kProfileServiceArgumentsKey];
            if (nil!=serviceArguments)
                [commandInfo setObject:serviceArguments forKey:kFramehawkServiceArgumentsKey];
            
            // add sevice button label
            NSString* serviceLabel = [button objectForKey:kProfileServiceLabelKey];
            if (nil!=serviceLabel)
                [commandInfo setObject:serviceLabel forKey:kProfileServiceLabelKey];
            
            // check login assistant allowed
            NSNumber* loginAssistantAllowed = [button objectForKey:kProfileServiceLoginAssistantAllowedKey];
            // if login assistant allowed setting not there then default is enabled
            // (handled by SettingsUtils:checkServiceInformationForloginAssistantAllowed method)
            if (nil!=loginAssistantAllowed)
            {   // use login assistant allowed setting from studio
                [commandInfo setObject:loginAssistantAllowed forKey:kProfileServiceLoginAssistantAllowedKey];
            }
            
            // if login assistant is not allowed then clear user settings from keychain
            if (![SettingsUtils checkServiceInformationForloginAssistantAllowed:commandInfo])
            {
                // load username from settings
                NSString* username = [SettingsUtils getCurrentUserID];

                // get currently selected profile id from settings
                NSString* profileID = [SettingsUtils getSelectedProfileId];
                
                DLog(@">>>> CLEARING OUT LOGIN ASSISTANT INFO for User:%@ Profile:%@!!!!", username, profileID);

                // clear user login assistant credentials (username & password) for this service
                [SettingsUtils clearLoginAssistantCredentialsForUserId:username profileId:profileID appName:serviceLabel];

                // set user login assistant toggle to off for this service
                [SettingsUtils toggleLoginAssistantOffForUserId:username profileId:profileID appName:serviceLabel];
            }
            
            // login assistant toggled to off by default
            [commandInfo setObject:sSettingsBoolFalse forKey:kProfileServiceLoginAssistantToggleKey];
            
            // set unselected service icon graphic
            NSString* serviceIcon = [[button objectForKey:kProfileButtonIconKey] URLEncodedString];
            if (nil!=serviceIcon)
                [commandInfo setObject:serviceIcon forKey:kProfileButtonIconKey];
            
            // set selected service icon graphic
            NSString* serviceSelectedIcon = [[button objectForKey:kProfileSelectedButtonIconKey] URLEncodedString];
            if (nil!=serviceSelectedIcon)
                [commandInfo setObject:serviceSelectedIcon forKey:kProfileSelectedButtonIconKey];

            // set unselected service background graphic
            NSString* serviceUnselectedBG = [[skin objectForKey:kProfileMenuItemSelectedBackgroundKey] URLEncodedString];
            if (nil!=serviceUnselectedBG)
                [commandInfo setObject:serviceUnselectedBG forKey:kProfileMenuItemSelectedBackgroundKey];

            // set selected service background graphic
            NSString* serviceSelectedBG = [[skin objectForKey:kProfileMenuItemUnselectedBackgroundKey] URLEncodedString];
            if (nil!=serviceSelectedBG)
                [commandInfo setObject:serviceSelectedBG forKey:kProfileMenuItemUnselectedBackgroundKey];
            
            // set close service icon graphic
            NSString* closeServiceIcon = [[skin objectForKey:kProfileMenuCloseServiceIconKey] URLEncodedString];
            if (nil!=closeServiceIcon)
                [commandInfo setObject:closeServiceIcon forKey:kProfileMenuCloseServiceIconKey];
            
            // set session divider graphic
            NSString* sessionDividerGraphic = [[skin objectForKey:kProfileMenuRowDividerKey] URLEncodedString];
            if (nil!=sessionDividerGraphic)
                [commandInfo setObject:sessionDividerGraphic forKey:kProfileMenuRowDividerKey];
            
            // set gesture map session
            NSNumber* serviceGestureMap = [button objectForKey:kProfileServiceGestureMapKey];
            if (nil!=serviceGestureMap)
                [commandInfo setObject:serviceGestureMap forKey:kProfileServiceGestureMapKey];
            
            // set keyboard type
            NSNumber* serviceKeyboardType = [button objectForKey:kProfileServiceKeyboardTypeKey];
            if (nil!=serviceKeyboardType)
                [commandInfo setObject:serviceKeyboardType forKey:kProfileServiceKeyboardTypeKey];
            
            // Create single command entry
            NSMutableDictionary* commandEntry = [[NSMutableDictionary alloc] initWithCapacity:1];
            // set command entry item key as button label
            NSString* buttonLabel = [button objectForKey:kProfileServiceLabelKey];
            // add command info to entry
            [commandEntry setObject:commandInfo forKey:buttonLabel];
            
            // insert command entry into commands array
            [commandsArray addObject:commandEntry];
        }
    }

    // set commands array of services
    _cmds = commandsArray;

}

/**
 * Close all open sessions
 */
-(void) closeAllSessions
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // Close all open commands
        NSArray* os = [NSArray arrayWithArray:openSessions];
        for (UIViewController* viewController in os) {
            mCenter.state = MC_IDLE; // reset per loop
            if ([viewController isKindOfClass:[BrowserServiceViewController class]])
                [self closeApplication:[((BrowserServiceViewController*)viewController) command]];
            else if ([viewController isKindOfClass:[FHServiceViewController class]])
                [self closeApplication:[((FHServiceViewController*)viewController) command]];
        }
    });
}


#pragma mark -
#pragma mark Observers


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    // If the observed object is the CommandCenter...
    if ([object isKindOfClass:[CommandCenter class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is profile load completion...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if ([value integerValue] == CC_MENU_COMPLETE) {
                [self closeAllSessions];
            }
        }
    }
}


#pragma mark -
#pragma mark MenuCommand Implementation

/**
 * Set Selected Command From Sessions Name
 * sessionName - name of selected session
 * Sets up currently selected command
 */
- (void)setSelectedCommandForSessionName:(NSString*)sessionName
{
    selectedCommand = [mCenter getCommandWithName:sessionName];
}


/**
 * Open Application
 * @returns BOOL
 * - TRUE if was able to open a new or existing session.
 * - FALSE if was unable to open a session e.g. another session is currently being opened
 */
- (BOOL)openApplication:(NSString*)applicationName withOption:(NSDictionary*)option {
    DLog(@"Opening Session for %@ !!!!", applicationName);
    
    [self setSelectedCommandForSessionName:applicationName];
    
    if ([MenuCommands checkIfCommandIsOpen:applicationName]) {
        
        int index = [MenuCommands getIndexOfOpenSession:applicationName];
        
        if (option) {
            BrowserServiceViewController *b = (BrowserServiceViewController *)[mCenter.openSessions objectAtIndex:index];
            b.search = [option objectForKey:@"search"];
        }
        
        mCenter.goToIndex = [NSNumber numberWithInt:index];
        mCenter.state = MC_SESSION_READY_TO_SCROLLTO;
        return TRUE;
    }
    
    if (mCenter.openSessions == nil) {
        mCenter.openSessions = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    // Obtain parameters from the command
    NSString* mobileWebBrowserUrl = [selectedCommand objectForKey:kWebBrowserURLKey];
    NSNumber* serviceType = [selectedCommand objectForKey:kFramehawkServiceTypeKey];
    
    // If the command is for a local web browser...
    if ([serviceType integerValue] == 3) {
        
        BrowserServiceViewController *fbvc = [[BrowserServiceViewController alloc] initWithNibName:nil bundle:nil];
        [fbvc browseToURL:mobileWebBrowserUrl forCommand:applicationName];
        
        if (option) {
            fbvc.search = [option objectForKey:@"search"];
        }
        
        [[mCenter openSessions] addObject:fbvc];
        
        mCenter.state = MC_SESSION_READY_TO_OPEN;
        
        [fbvc browseToURL];
        
        return TRUE;
    }
    // Elsewise, if the command if for a Framehawk session...
    else if ([serviceType integerValue] == 1 || [serviceType integerValue] == 2) {
        
        FHServiceViewController *fmc = [[FHServiceViewController alloc] initWithNibName:nil bundle:nil];
        fmc.command = [NSMutableString stringWithString:applicationName];
        
        if ([[mobileWebBrowserUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0) {
        }
        
        fmc.view.frame = FramehawkFrame;
        fmc.view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        ((FHServiceView*)fmc.view).serviceName = applicationName;
        
        [[mCenter openSessions] addObject:fmc];
        
        if ([[selectedCommand objectForKey:@"Options"] objectForKey:@"authentication"] && !mCenter.cookiesAreSet) {
            mCenter.state = MC_SESSION_NEEDS_REVERSE_PROXY;
        }else {
            mCenter.state = MC_SESSION_READY_TO_OPEN;
        }
        
        return TRUE;
    }
    return FALSE;
}


+(int)getIndexOfOpenSession:(NSString *)command{
    if ([mCenter.openSessions count]<1)
        return -1;
    
    int count = 0;
    for (UIViewController *viewC in mCenter.openSessions) {
            
        if([viewC isKindOfClass:[BrowserServiceViewController class]]){
            if ([command isEqualToString:[(BrowserServiceViewController*)viewC command]]) {
                return count;
            }
        }
        if([viewC isKindOfClass:[FHServiceViewController class]]){
            if ([command isEqualToString:[(FHServiceViewController*)viewC command]]) {
                return count;
            }
        }
        
        count++;
    }
    
    return -1;
}

+(BOOL)checkIfCommandIsOpen:(NSString *)command{
    if ([mCenter.openSessions count]<1)
        return NO;
    
    for (UIViewController *viewC in mCenter.openSessions) {
        if([viewC isKindOfClass:[BrowserServiceViewController class]]){
            if ([command isEqualToString:[(BrowserServiceViewController*)viewC command]]) {
                return YES;
            }
        }
        if([viewC isKindOfClass:[FHServiceViewController class]]){
            if ([command isEqualToString:[(FHServiceViewController*)viewC command]]) {
                return YES;
            }
        }
        
    }
    
    return NO;
}

+(int)getNumberOfCommands{
    return [mCenter.launchpadProfile count];
}

+(int)getNumberOfOpenCommands{
    
    int count = 0;
    
    for(id object in mCenter.openSessions)
        if ([[[object class] description] isEqualToString:@"FHServiceViewController"]) {
            count++;
        }

    return count;
}

-(void)dissmissRSAPrompt{
    [mCenter setState:MC_SESSION_CANCEL_REVERSE_PROXY];
}

-(void)startProxyedService:(NSString *) command{
    
    mCenter.cookiesAreSet = YES;
    
    if ([MenuCommands checkIfCommandIsOpen:command]) {
        [mCenter closeApplication:command];
    }

    [mCenter openApplication:command withOption:nil];
}

-(void)closeApplication:(NSString *)applicationName{
    int found = -1;
    int count = 0;
    DLog(@"closeApplication %@ !!!!", applicationName);
    
    for (UIViewController *viewC in mCenter.openSessions) {
        
        if([viewC isKindOfClass:[BrowserServiceViewController class]]) {
            if ([applicationName isEqualToString:[(BrowserServiceViewController*)viewC command]]) {
                found = count;
            }
        }
        if([viewC isKindOfClass:[FHServiceViewController class]])
        {
            if ([applicationName isEqualToString:[(FHServiceViewController*)viewC command]]) {
                found = count;
            }
        }

        count++;
    }
    
    if (found > -1) {
        mCenter.closeIndex = [NSNumber numberWithInt:found];
        mCenter.state = MC_SESSION_READY_TO_CLOSE;
    }
}

-(UIView *)getViewAtIndex:(int)index{
    if ([mCenter.openSessions count]>index) {
        return [[mCenter.openSessions objectAtIndex:index] view];
    }
    return nil;
}

-(BOOL)isProxyedServiceCommand:(NSString *)command{
    NSDictionary *currentlySelectedCommand = [mCenter.launchpadProfile objectForKey:command];
    
    if ([[currentlySelectedCommand objectForKey:@"type"] isEqualToString:@"Framehawk"]) {
        if ([[currentlySelectedCommand objectForKey:@"Options"] objectForKey:@"authentication"]) {
            return YES;
        }
    }
    
    return NO;
}

-(void)clearAllSessions{
    // close all sessions
    [self closeAllSessions];
}

-(BOOL)deleteSession:(NSNumber *)index{
    UIViewController *d = [mCenter.openSessions objectAtIndex:[index intValue]];
    
    [[[d view] subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
    
    [d.view removeFromSuperview];
    [mCenter.openSessions removeObjectAtIndex:[index intValue]];
    
    if ([d isKindOfClass:[FHServiceViewController class]]) {
        [(FHServiceViewController *)d stopConnection];
    }
    
    d = nil;
    
    mCenter.closeIndex = [NSNumber numberWithInt:-1];
    
    if ([MenuCommands getNumberOfOpenCommands] < 1) {
        mCenter.openSessions = nil;
    }
    
    DLog(@"******** deallocated ************ %i %@",[MenuCommands getNumberOfOpenCommands],mCenter.openSessions);
    return YES;
}


+ (NSArray*)getAllInternalSessionCommands {
    
#ifdef PROFILE_ENABLED
    
    NSMutableArray* results = [NSMutableArray array];
    NSDictionary* categories = [mCenter.launchpadProfile objectForKey:kProfileButtonGroupsKey];
    for (NSDictionary* category in categories) {
        for ( NSDictionary* service in [category objectForKey:@"buttons"]) {
            NSNumber* serviceType = [service objectForKey:kFramehawkServiceTypeKey];
            if (serviceType && [serviceType integerValue] == 3)
                [results addObject:service];
        }
    }
    return results;
#else    
    
    NSMutableArray* results = [NSMutableArray array];
    for (NSDictionary* dict in mCenter.cmds) {
        
        for(NSString* k in dict.allKeys){
            NSDictionary* val = [dict objectForKey:k];
            NSNumber* serviceType = [val objectForKey:kFramehawkServiceTypeKey];
            if (serviceType && ([serviceType integerValue] == 3))
                [results addObject:val];
        }
    }
    
    
    return results;   
    
#endif
}


+ (NSArray*)getAllFramehawkSessionCommands {
    
#ifdef PROFILE_ENABLED
    NSMutableArray* results = [NSMutableArray array];
    NSDictionary* categories = [mCenter.launchpadProfile objectForKey:kProfileButtonGroupsKey];
    for (NSDictionary* category in categories) {
        for ( NSDictionary* service in [category objectForKey:@"buttons"]) {
            NSNumber* serviceType = [service objectForKey:kFramehawkServiceTypeKey];
            if (serviceType && ([serviceType integerValue] == 1 || [serviceType integerValue] == 2))
                [results addObject:service];
        }
    }
    return results;
    
#else    
    NSMutableArray* results = [NSMutableArray array];
    for (NSDictionary* dict in mCenter.cmds) {
        
        for(NSString* k in dict.allKeys){
            NSDictionary* val = [dict objectForKey:k];
            NSNumber* serviceType = [val objectForKey:kFramehawkServiceTypeKey];
            if (serviceType && ([serviceType integerValue] == 1 || [serviceType integerValue] == 2))
                [results addObject:val];
        }
    }
    
    return results;    
#endif

}


-(void)checkForStaleCookie{
    int count = 0;
    
    count = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
              cookiesForURL:
              [NSURL URLWithString:
               [[NSUserDefaults standardUserDefaults]
                objectForKey:@"reverse_proxy_domain"]]] count];
    
    if (1 == count) {
        NSHTTPCookie *latestCookie = [[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                                       cookiesForURL:
                                       [NSURL URLWithString:
                                        [[NSUserDefaults standardUserDefaults]
                                         objectForKey:@"reverse_proxy_domain"]]] objectAtIndex:0];
        
        NSTimeInterval createInterval = [[[latestCookie properties] objectForKey:@"Created"] doubleValue];
        NSDate *createdDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:createInterval];
        DLog(@"****** Created Date ******** %@",createdDate);
        NSDate *now = [NSDate date];
        
        NSTimeInterval timeDiff = [now timeIntervalSinceDate:createdDate]/60;
        
        if (timeDiff > 1) { //If older then two minutes
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:latestCookie];
            DLog(@"Cookie was older then 2 minutes deleted");
            DLog(@"%@",[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                        cookiesForURL:
                        [NSURL URLWithString:
                         [[NSUserDefaults standardUserDefaults]
                          objectForKey:@"reverse_proxy_domain"]]]);
        }
        
    }
}


#pragma mark -
#pragma mark MenuCommands Implementation


-(NSDictionary*) getCommandWithName:(NSString*)name {
    
    for(int i = 0; i < self.cmds.count; i++)
    {
        NSDictionary* el = [self.cmds objectAtIndex:i];
        
        if( [el objectForKey:name])
        {
            return [el objectForKey:name];
        }
    }    
    return nil;
    
}

/**
 * Return the index of the command name
 * -1 if not found
 */
-(int) getCommandIndex:(NSString*)command {
    for(int i = 0; i < self.cmds.count; i++)
    {
        NSDictionary* el = [self.cmds objectAtIndex:i];
        if( [el objectForKey:command])
        {
            return i;
        }
    }    
    return -1;
    
}

/**
 * Return the index of the connection index
 * for Framehawk sessions
 * -1 if not found or session is not a Framehawk session
 */
/*
-(int) getConnectionIndex:(NSString*)command {
    int connectionIndex = -1;
    for(int i = 0; i < self.cmds.count; i++)
    {
        NSDictionary* el = [self.cmds objectAtIndex:i];
        
        NSEnumerator *keyEnumerator = [el keyEnumerator];
        id key;
        // Get service information
        key = [keyEnumerator nextObject];
        NSDictionary* service = [el objectForKey:key];
        NSNumber* serviceType = [service objectForKey:kFramehawkServiceTypeKey];
        if ([serviceType integerValue] != kNativeBrowserService)
        {
            connectionIndex++;
            // if this is a framehawk service
            if( [el objectForKey:command])
            {
                return connectionIndex;
            }
        }
    }    
    return -1;
    
}
*/

/**
 * returns TRUE if selected command is a Framehawk session
 */
- (BOOL)selectedCommandIsFramehawk {
    return [self selectedCommandIsFramehawkBrowser] || [self selectedCommandIsFramehawkVDI];
}

/**
 * returns TRUE if selected command is a Framehawk VDI session
 */
- (BOOL)selectedCommandIsFramehawkVDI {
    NSInteger serviceType = [[selectedCommand objectForKey:kFramehawkServiceTypeKey] integerValue];

    return (serviceType == kFramehawkVDIService);
}

/**
 * Returns TRUE if selected command is a Framehawk Browser session
 */
- (BOOL)selectedCommandIsFramehawkBrowser {
    NSInteger serviceType = [[selectedCommand objectForKey:kFramehawkServiceTypeKey] integerValue];

    return (serviceType == kFramehawkBrowserService);
}

/**
 * returns TRUE if selected command service uses a VDI keyboard
 */
- (BOOL)selectedCommandUsesVDIKeyboard {
    NSInteger keyboardType = [[selectedCommand objectForKey:kProfileServiceKeyboardTypeKey] integerValue];

    return (keyboardType == kVDIKeyboard);
}

/**
 * returns TRUE if selected command service uses a Browser keyboard
 */
- (BOOL)selectedCommandUsesBrowserKeyboard {
    NSInteger keyboardType = [[selectedCommand objectForKey:kProfileServiceKeyboardTypeKey] integerValue];
    return (keyboardType == kBrowserKeyboard);
}


- (void)saveSelectedCommand {
    [self saveCommand:selectedCommand];
}


- (void)saveCommand:(NSDictionary*)command {
    
    // Add the selected command back to the active profile
    NSArray* bgroups = [launchpadProfile objectForKey:kProfileButtonGroupsKey];
    NSString* selectedLabel = [command objectForKey:kProfileServiceLabelKey];
    
    for (NSDictionary* bg in bgroups) {
        NSMutableArray* buttons = [bg objectForKey:@"buttons"];
        for (NSUInteger i = 0, l = [buttons count]; i < l; i++) {
            NSDictionary* button = [buttons objectAtIndex:i];
            NSMutableDictionary* cmd = [self.cmds objectAtIndex:i];
            
            NSString* buttonLabel = [button objectForKey:kProfileServiceLabelKey];
            if ([buttonLabel compare:selectedLabel] == NSOrderedSame)
            {
                [buttons replaceObjectAtIndex:i withObject:command];
                [cmd setObject:command forKey:buttonLabel];     

                if(selectedCommand){
                    NSString* sel = [selectedCommand objectForKey:kProfileServiceLabelKey];
                    if([sel compare:selectedLabel] == NSOrderedSame){
                        selectedCommand = command;
                    }
                }
                break;   
            }
        }
    }
    
    // Save the selected profile back to the downloaded profile list
    NSString* profileIdStr = nil;
    // get profile Info
    NSMutableDictionary *profileInfo = [launchpadProfile objectForKey:kProfileInfoKey];
    // get profile Id
    profileIdStr = [profileInfo objectForKey:kProfileIdKey];

    // Obtain the downloaded profiles list from user preferences
    CommandCenter* profiles = [CommandCenter get];
    NSMutableDictionary* downloads = profiles.installedProfiles;

    [downloads setObject:launchpadProfile forKey:profileIdStr];
    [profiles saveInstalledProfiles];
}

/*
 * Get current session
 */
- (UIViewController*)getCurrentSession {
    AppDelegate* a = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSInteger currentIndex = a.viewController.currentSessionIndex;
    DLog(@"++++++ getCurrentSession:%i\n", currentIndex);
    
    // if session is outside range of sessions, use the last session
    if (currentIndex>=[openSessions count])
        currentIndex = [openSessions count]-1;
    
    // if currentindex is negative then no sessions are opened
    return ((currentIndex>=0) ? [openSessions objectAtIndex:currentIndex] : nil);
}

/**
 * Get session view controller with specified key
 *
 * @param (SessionKey) - session key of session to get view controller for
 *
 * @return (UIViewController*) - view controller for session with specified key
 *                             - nil if no session found with specified key
 */
- (UIViewController*)getSessionViewControllerWithKey:(SessionKey)sessionKey {
    
    UIViewController* sessionViewController = nil;

    // search sessions for session with matching key
    for(id object in mCenter.openSessions)
    {
        if ([[[object class] description] isEqualToString:@"FHServiceViewController"])
        {
            // check if current view controller sssion key matches requested key
            FHServiceViewController* currentViewController = (FHServiceViewController*)object;
            if ([[currentViewController sessionKey] isEqualToString:sessionKey])
            {
                // set session view controller as the one we want to return
                sessionViewController = currentViewController;
                break;
            };
        }
    }
    
    // return session view controller with specified key
    return sessionViewController;
}


-(void)sendMenuEdgeCaseTouch:(UIView*)view location:(CGPoint)point{
    
    UIViewController * curr = [self getCurrentSession];
    
    if ([curr isKindOfClass:[FHServiceViewController class]]) {
        [(FHServiceViewController *)curr touchedEdge:view location:point];
    }
}
@end