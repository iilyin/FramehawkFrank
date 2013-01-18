//
//  MenuViewController.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/16/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "CommandCenter.h"
#import "ProfileSettingsViewController.h"
#import "MenuCommands.h"
#import "MenuViewController.h"
#import "ProfileDefines.h"
#import "AppDelegate.h"
#import "FeedbackViewController.h"
#import "File.h"
#import "StringUtility.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"
#import "LoginAssistantManager.h"
#import <QuartzCore/QuartzCore.h>

#define MENU_EDGE_CASE_TOUCH    308

// Profile dialog positioning
#define PROFILE_SELECTION_DIALOG_X      320
#define PROFILE_SELECTION_DIALOG_Y      40

// Settings dialog positioning
#define SETTINGS_DIALOG_X               320
#define SETTINGS_DIALOG_Y               40

// Menu toolbar positioning
#define MENU_TOOLBAR_X                  10
#define MENU_TOOLBAR_Y                  704

// Menu unselected text color
static NSString *const sMenuUnselectedTextColor = @"f0f0f0";
// Menu pressed text color
static NSString *const sMenuPressedTextColor    = @"336680";
// Menu selected text color
static NSString *const sMenuSelectedTextColor   = @"336680";
// Menu background color
static NSString *const sMenuBackgroundColor     = @"000000";

static NSInteger menuTabMargin = 16;

// state key path
static NSString *const sStateKeyPath     = @"state";

// Login Assistant Disabled alert dialog
static UIAlertView *loginAssistantDisabledAlert = nil;

// Login Assistant Dialog Strings
static NSString *const sLoginAssistantDisabledTitle         = @"Login Assistant is disabled for this service!";
static NSString *const sLoginAssistantDisabledSubTitle      = @"Contact your administrator for details.";
static NSString *const sLoginAssistantDisabledButtonText    = @"OK";

// Sessions Timed Out Dialog Strings
static NSString *const sSessionsTimedOutTitle               = @"Session Timeout";
static NSString *const sSessionsTimedOutSubTitle            = @"For security reasons, all sessions have been closed.";
static NSString *const sSessionsTimedOutButtonText          = @"Cancel";



@implementation MenuViewController {
    
    // Menu data source
    MenuDataSource* _menuDataSource;
    
    // Menu drawer logo image
    UIImageView* logo;
    // Settings dialog navigation controller
    UINavigationController* _settingsNavigationController;
    // Profile settings view controller
    ProfileSettingsViewController* _settingsViewController;
    // Profile selection view controller
    ProfileSelectionViewController* _profilesViewController;
    // Login Assistant Manager
    LoginAssistantManager  *loginAssistantManager;
    
    UIViewController* feedbackControl;
    
    // Menu settings toolbar
    UIToolbar* _toolbar;
    UIButton* feedbackButton;
    
    // Menu settings icon buttons
    UIButton *easyLoginButton;
    UIButton *profilesButton;
    UIButton *settingsButton;
    UIButton *helpButton;
    
    // Menu tab currently pressed flag
    BOOL    bMenuTabIsCurrentlyPressed;
    
    // Menu drawer graphics width
    int menuDrawerBGWidth;
    int menuDrawerTabWidth;
    
}


@synthesize menuTable, searchField, searchButton, backgroundPanel, backgroundColorLayer, menuTab, popcon, delegate;


- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Obtain the CommandCenter
        CommandCenter* c = [CommandCenter get];
        
        // Register to observe the command center's state
        /* This enables me to update the state of the application based on the current profile state */
        [c addObserver:self forKeyPath:sStateKeyPath options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
        
        // code to see menu frame - PLEASE LEAVE FOR NOW
        //self.view.backgroundColor = [UIColor redColor];
        
    }
    return self;
}

/**
 * Handle cleanup on deallocation
 */
- (void) dealloc {
    CommandCenter* c = [CommandCenter get];
    [c removeObserver:self forKeyPath:sStateKeyPath];
    
    [[MenuCommands get] removeObserver:self forKeyPath:sStateKeyPath];
}

/**
 * The app received a memory warning
 */
-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    DLog(@"Did Receive Memory Warning....");
}

/**
 * Returns a Boolean value indicating whether the view controller supports the specified orientation.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark -
#pragma mark Observers

/**
 * This message is sent to the receiver when the value at the specified key path relative to the given object has changed
 */
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    // If the observed object is the CommandCenter...
    if ([object isKindOfClass:[CommandCenter class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is profile load completion...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if([value integerValue] == CC_MENU_COMPLETE) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    // Refresh my profile aspects
                    [self refreshProfile];
                    // adjust login assistant button status
                    [self setLoginAssistantButtonStatus];
                });
            }
        }
    }
    
    // ...Elsewise, if the observed object is the MenuCommands singleton...
    else if ([object isKindOfClass:[MenuCommands class]]) {
        switch ([MenuCommands get].state) {
            case MC_SESSION_NEEDS_REVERSE_PROXY:
            case MC_SESSION_READY_TO_OPEN:{
                // remove profile selection if it is onscreen when user click to open service
                [self dismissOnscreeDialogs];
                //TODO: disable to rapidly open & close sessions
                [self closeMenu];
            }
            default:
                // adjust login assistant button status
                [self setLoginAssistantButtonStatus];
                break;
        }
    }
}

/**
 * Handle when one or more fingers touch down in view
 */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if ([touches count]==1) {
        UITouch *t = [touches anyObject];
        CGPoint p = [t locationInView:self.view];
        
        if (p.x > MENU_EDGE_CASE_TOUCH){
            [[MenuCommands get] sendMenuEdgeCaseTouch:self.view location:p];
        }
    }
}

/**
 * Refresh Menu Style
 */
- (void)refreshMenuStyle{
    
}

/**
 * Enable Login Assistant menu button
 */
- (void) enableLoginAssistantButton {
    [easyLoginButton setEnabled:YES];
}

/**
 * Disable Login Assistant menu button
 */
- (void) disableLoginAssistantButton {
    [easyLoginButton setEnabled:NO];
}

/**
 * Initialize profile graphics
 */
- (void)initProfileGraphics
{
    // Obtain the selected Launchpad profile
    MenuCommands* m = [MenuCommands get];
    NSDictionary* p = m.launchpadProfile;
    
    if (p == nil){
        p = [[CommandCenter get] getCurrentProfile];
        if (p == nil) {
            return;
        }
    }
    
    // clear menu tab pressed flag
    bMenuTabIsCurrentlyPressed  = false;
    
    // remove any existing profile
    [backgroundPanel removeFromSuperview];
    [backgroundColorLayer removeFromSuperview];
    [logo removeFromSuperview];
    [menuTab removeFromSuperview];
    [menuTable removeFromSuperview];
    [_toolbar removeFromSuperview];

    
    UIImage* drawerback     = nil;
    UIImage* drawertab      = nil;
    UIImage* drawerlogo     = nil; 
    UIImage* drawertoolbar  = nil;
    
    // get profile skin
    NSMutableDictionary *skin = [p objectForKey:kProfileSkinKey];
    
    // Menu Drawer Background Image
    NSString* menuDrawerBGImagePath = [[skin objectForKey:kProfileMenuDrawerBackgroundKey] URLEncodedString];
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerBGImagePath] path]]]){
        drawerback = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerBGImagePath] path]]];
    }else{
        NSURL* menuDrawerBGImageURL = [NSURL URLWithString:menuDrawerBGImagePath];
        drawerback = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuDrawerBGImageURL]];
    }
    
    menuDrawerBGWidth = drawerback.size.width;
    // ensure menu is offscreen until graphics are available
    if (menuDrawerBGWidth==0)
        menuDrawerBGWidth = 317;
        
    // Menu Drawer Tab Image
    NSString* menuDrawerTabBGImagePath = [[skin objectForKey:kProfileMenuDrawerTabKey] URLEncodedString];
    
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerTabBGImagePath] path]]]){
        drawertab = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerTabBGImagePath] path]]];
    }else{
        NSURL* menuDrawerTabBGImageURL = [NSURL URLWithString:menuDrawerTabBGImagePath];
        drawertab = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuDrawerTabBGImageURL]];
    }
    
    menuDrawerTabWidth = drawertab.size.width;
    
    // Menu Drawer Logo Image
    NSString* menuDrawerLogoImagePath = [[skin objectForKey:kProfileMenuDrawerLogoKey] URLEncodedString];
    if (menuDrawerLogoImagePath && [menuDrawerLogoImagePath length])
    {
         if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerLogoImagePath] path]]]){
             drawerlogo = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuDrawerLogoImagePath] path]]];
         }else{
             NSURL* menuDrawerLogoImageURL = [NSURL URLWithString:menuDrawerLogoImagePath];
             drawerlogo = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuDrawerLogoImageURL]];
         }
    }
    
    // Menu Toolbar BG Image
    NSString* menuToolbarBGImagePath = [[skin objectForKey:kProfileMenuToolbarBackgroundKey] URLEncodedString];
    
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuToolbarBGImagePath] path]]]){
        drawertoolbar = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuToolbarBGImagePath] path]]];
    }else{
        NSURL* menuDrawerToolbarBGImageURL = [NSURL URLWithString:menuToolbarBGImagePath];
        drawertoolbar = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuDrawerToolbarBGImageURL]];
    }
    // check for missing drawer images & use defaults
    if(!drawerback || !drawertab || !drawertoolbar)
    {        
        // default menu pieces
        NSString* backstr = @"menu_drawer_bg";
        NSString* tabstr = @"menu_drawer_tab"; 
        NSString* toolstr = @"menu_toolbar_bg";
        
        // if drawer background missing use default
        if(!drawerback)
        {
            drawerback = [UIImage imageNamed: backstr];
            menuDrawerBGWidth = drawerback.size.width;
        }
        
        // if drawer menu tab missing use default
        if(!drawertab)
        {
            drawertab = [UIImage imageNamed:tabstr];
            menuDrawerTabWidth = drawertab.size.width;
        }
        
        // if drawer toolbar missing use default
        if(!drawertoolbar)
            drawertoolbar = [UIImage imageNamed: toolstr];
    }
    
    // get menu row divider
    NSString* menuRowDividerImagePath = [[skin objectForKey:kProfileMenuRowDividerKey] URLEncodedString];
    
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuRowDividerImagePath] path]]]){
        [MenuCommands get].menuRowDividerImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuRowDividerImagePath] path]]];
    }else{
        NSURL* menuRowDividerImageURL = [NSURL URLWithString:menuRowDividerImagePath];
        [MenuCommands get].menuRowDividerImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuRowDividerImageURL]];
    }
    
    CGRect f;
    NSString* imgstr;
    
    // set up drawer background panel
    backgroundPanel = [[UIImageView alloc] init];
    backgroundPanel.image = drawerback;
    [backgroundPanel sizeToFit];
    f = backgroundPanel.frame;
    f.origin.x = 0;
    f.origin.y = 0;
    backgroundPanel.frame = f; 

    
    // set up drawer color layer panel
    backgroundColorLayer = [[UIImageView alloc] init];
    // get menu drawer background color
    NSString* menuBackgroundColorStr = [skin objectForKey:kProfileMenuDrawerBackgroundColorKey];
    backgroundColorLayer.backgroundColor = [AppDelegate colorWithHtmlColor:menuBackgroundColorStr ? menuBackgroundColorStr : sMenuBackgroundColor];    
    [backgroundColorLayer sizeToFit];
    f = backgroundPanel.frame;
    f.origin.x = 0;
    f.origin.y = 0;
    f.size.width -= menuTabMargin;  // adjust for shadow on drawer background
    backgroundColorLayer.frame = f; 
    
    
    // set up drawer menu tab handle
    menuTab = [UIButton buttonWithType:UIButtonTypeCustom];
    menuTab.imageView.image = drawertab;
    [menuTab setImage:drawertab forState:UIControlStateNormal];
    [menuTab sizeToFit];
    [menuTab addTarget:self action:@selector(menuTabTouched) forControlEvents:    UIControlEventTouchDown|UIControlEventTouchDragEnter];
    [menuTab addTarget:self action:@selector(menuTabReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    f = menuTab.frame;
    f.origin.x = menuDrawerBGWidth-menuTabMargin;
    f.origin.y = MENU_TAB_Y_OFFSET;
    menuTab.frame = f;
    
    // set up drawer logo
    logo = [[UIImageView alloc] init];
    logo.image = drawerlogo;
    [logo sizeToFit];
    f = logo.frame;
    f.origin.x = (menuDrawerBGWidth - menuTabMargin - f.size.width)/2.0;
    f.origin.y = MARGIN;
    logo.frame = f;
    
    // menu button text colors
    // menu group text color
    NSString* menuGroupTextColorStr = [skin objectForKey:kProfileGroupLabelTextColorKey];
    // if the profile has a unselected text color, use it
    [MenuCommands get].menuGroupTextColor = [AppDelegate colorWithHtmlColor:menuGroupTextColorStr ? menuGroupTextColorStr : sMenuUnselectedTextColor];
    // menu unselected text color
    NSString* menuUnselectedTextColorStr = [skin objectForKey:kProfileMenuUnselectedButtonTextColorKey];
    // if the profile has a unselected text color, use it
    [MenuCommands get].menuUnselectedTextColor = [AppDelegate colorWithHtmlColor:menuUnselectedTextColorStr ? menuUnselectedTextColorStr : sMenuUnselectedTextColor];
    // menu pressed text color
    //NSString* menuPressedTextColorStr = [skin objectForKey:kProfileMenuPressedButtonImageKey];
    // if the profile has a pressed text color, use it
    //UIColor* menuPressedTextColor = [AppDelegate colorWithHtmlColor:menuPressedTextColorStr ? menuPressedTextColorStr : sMenuPressedTextColor];
    // menu selected text color
    NSString* menuSelectedTextColorStr = [skin objectForKey:kProfileMenuSelectedButtonTextColorKey];
    // if the profile has a selected text color, use it
    [MenuCommands get].menuSelectedTextColor = [AppDelegate colorWithHtmlColor:menuSelectedTextColorStr ? menuSelectedTextColorStr : sMenuSelectedTextColor];

    
    // Menu Table
    menuTable = [[LaunchPadMenuTable alloc] initWithFrame:CGRectMake(0, 170, 300, 550) style:UITableViewStylePlain];
    [[MenuCommands get] addObserver:self forKeyPath:sStateKeyPath options:0 context:nil];
    _menuDataSource = [[MenuDataSource alloc] init];
    menuTable.dataSource = _menuDataSource;
    menuTable.delegate = _menuDataSource;    
    [menuTable reloadData];
        // Toolbar Background
    _toolbar = [[UIToolbar alloc] init];
    UIImage* i = [UIImage imageNamed:@"menu_toolbar_bg.png"];
    [_toolbar setBackgroundImage:i forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [_toolbar setFrame:CGRectMake(0, 0, i.size.width, i.size.height)];
    [_toolbar setFrame:CGRectMake(0, 0, drawertoolbar.size.width, drawertoolbar.size.height)];
    f = _toolbar.frame;
    f.origin.x = MENU_TOOLBAR_X;
    f.origin.y = MENU_TOOLBAR_Y;
    _toolbar.frame = f;

/*
    feedbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [feedbackButton setTitle:@"Feedback" forState:UIControlStateNormal];
    [feedbackButton sizeToFit];
    [feedbackButton addTarget:self action:@selector(feedbackClicked) forControlEvents:UIControlEventTouchUpInside];
    f =feedbackButton.frame;
    f.origin.x = MENU_TOOLBAR_X + _toolbar.frame.size.width/4;
    f.origin.y = MENU_TOOLBAR_Y - f.size.height-10;
    feedbackButton.frame = f;
*/
    
    // Toolbar Easy Login Icon
    imgstr = @"menu_easy_login_selected_bg";
    i = [UIImage imageNamed:imgstr];
    UIBarButtonItem* l;
    easyLoginButton = [[UIButton alloc] init];
    [easyLoginButton setImage:[UIImage imageNamed:@"menu_easy_login_icon.png"] forState:UIControlStateNormal];
    [easyLoginButton setImage:[UIImage imageNamed:@"menu_easy_login_icon_disabled.png"] forState:UIControlStateDisabled]; 
    easyLoginButton.tag = 3030; 
    easyLoginButton.alpha = 0.5;
    [easyLoginButton addTarget:self action:@selector(easyLoginTapped:) forControlEvents:UIControlEventTouchUpInside];
    [easyLoginButton setFrame:CGRectMake(0, 0, i.size.width, i.size.height)];
    l = [[UIBarButtonItem alloc] initWithCustomView:easyLoginButton];
    
    // Toolbar Profile Selection Icon
    imgstr = @"menu_profiles_selected_bg";
    i = [UIImage imageNamed:imgstr];
    UIBarButtonItem* ps;
    profilesButton = [[UIButton alloc] init];
    [profilesButton setFrame:CGRectMake(0, 0, i.size.width, i.size.height)];
    [profilesButton setImage:[UIImage imageNamed:@"menu_profiles_icon.png"] forState:UIControlStateNormal];
    [profilesButton addTarget:self action:@selector(profilesTapped) forControlEvents:UIControlEventTouchUpInside];
    ps = [[UIBarButtonItem alloc] initWithCustomView:profilesButton];    
    
    // Toolbar Settings Icon
    imgstr = @"menu_settings_selected_bg";
    i = [UIImage imageNamed:imgstr];
    UIBarButtonItem* s;
    settingsButton = [[UIButton alloc] init];
    [settingsButton setFrame:CGRectMake(0, 0, i.size.width, i.size.height)];
    [settingsButton setImage:[UIImage imageNamed:@"menu_settings_icon.png"] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    s = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];    
    
    // Toolbar Help Icon
    imgstr = @"menu_help_selected_bg";
    i = [UIImage imageNamed:imgstr];
    UIBarButtonItem* h;
    helpButton = [[UIButton alloc] init];
    [helpButton setFrame:CGRectMake(0, 0, i.size.width, i.size.height)];
    [helpButton setImage:[UIImage imageNamed:@"menu_help_icon.png"] forState:UIControlStateNormal];
    [helpButton addTarget:self action:@selector(helpTapped) forControlEvents:UIControlEventTouchUpInside];
    h = [[UIBarButtonItem alloc] initWithCustomView:helpButton];    
    
    // UIToolbar layout its items at least 10 point apart so this removes spaces
    UIBarButtonItem* noSpaceStart = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    noSpaceStart.width = -12;
    UIBarButtonItem* noSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    noSpace.width = -10;
    
    // Set up list of settings toolbar items
    NSArray* items = [NSArray arrayWithObjects:noSpaceStart, l, noSpace, ps, noSpace, s, noSpace, h, noSpace, nil];
    _toolbar.items = items;
    
    // Toolbar Divider
    UIImageView* toolbarDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_toolbar_divider"]];
    [toolbarDivider sizeToFit];
    [_toolbar addSubview:toolbarDivider];
    
    // position settings toolbar
    f = _toolbar.frame;
    f.origin.x = MENU_TOOLBAR_X;
    f.origin.y = MENU_TOOLBAR_Y;
    _toolbar.frame = f;
    
    // Assemble view hierarchy
    [self.view addSubview:backgroundColorLayer];
    [self.view addSubview:backgroundPanel];
    [self.view addSubview:logo];
    [self.view addSubview:menuTab];
    [self.view addSubview:menuTable];
//    [self.view addSubview:feedbackButton];
    [self.view addSubview:_toolbar];
    
    
    // set offscreen as default
    f = self.view.frame;
    f.origin.x = -menuDrawerBGWidth + menuTabMargin;
    if (f.size.width < menuTabMargin + 1) {
        f.size.width = menuDrawerBGWidth+menuDrawerTabWidth-menuTabMargin;
    }
    self.view.frame = f;

}

/**
 * Refresh Profile
 */
- (void)refreshProfile {
    
    [self initProfileGraphics];
    
    // Refresh menu data
    [_menuDataSource setMenuDataFromProfile];
    
    // Clear menu commands
    [[MenuCommands get] clearCommandsWhenSwitchingProfile];
    
    // ...The menu table's data source
    [menuTable reloadData];
    
    // refresh menu style
    [self refreshMenuStyle];
    
    // Show menu if hidden...
    if (self.view.frame.origin.x != 0.0)
        [self openMenu];
    
    // dismiss any onscreen dialogs
    [self dismissOnscreeDialogs];
}

/**
 * Handle Feedback button being clicked
 */
- (void) feedbackClicked {
    
    if(!feedbackControl) {
        feedbackControl = [[FeedbackViewController alloc] initWithStyle:UITableViewStyleGrouped];
     }
    
    feedbackControl.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:feedbackControl animated:YES];
}

/**
 * Set login assistant button status
 * Disables login assistant button if no sessions are open
 */
- (void)setLoginAssistantButtonStatus
{
    int numberOfOpenSessions = [MenuCommands getNumberOfOpenCommands];
    
    // if at least one sessions is open
    if (numberOfOpenSessions>0)
    {
        // enable login assistant button
        [self enableLoginAssistantButton];
    }
    else
    {
        // otherwise disable login assistant
        [self disableLoginAssistantButton];
    }
}


#pragma mark -
#pragma mark UIViewController Implementation

/**
 * viewDidLoad
 */
- (void)viewDidLoad {
    // set up menu graphics
    [self initProfileGraphics];
    
    // set status for login assistant button
    [self setLoginAssistantButtonStatus];
}

/**
 * Handle initial appearance of menu
 */
-(void)viewDidAppear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL timedout = (BOOL)[defaults boolForKey:@"SessionBackgroundTimeout"];
    if(timedout){
        [defaults setBool:NO forKey:@"SessionBackgroundTimeout"];
        [defaults synchronize];

        UIAlertView *av = [[UIAlertView alloc] initWithTitle:sSessionsTimedOutTitle
                                                     message:sSessionsTimedOutSubTitle
                                                    delegate:self
                                           cancelButtonTitle:sSessionsTimedOutButtonText
                                           otherButtonTitles:nil, nil];
        // store connection index - used to associate alert with view, when displaying delayed alerts
        [av show];
        av = nil;
    }
}

/**
 * viewDidUnload
 */
- (void) viewDidUnload {
    MenuCommands* c = [MenuCommands get];
    [c removeObserver:self forKeyPath:sStateKeyPath];
}

/**
 * Set frame size
 */
- (void) updateFrame {
    self.view.frame = CGRectMake(0,0,menuDrawerBGWidth+menuDrawerTabWidth-menuTabMargin, 768); 
}

/**
 * Dismiss profiles settings dialog offscreen
 */
- (void)  dismissProfileSettings
{
    [_profilesViewController.view removeFromSuperview];
    //_profilesViewController = nil;
}

/**
 * Profiles button tapped
 * display profiles dialog
 */
- (void)profilesTapped
{
    // if profiles not currently displayed want to display them
    BOOL bDisplayProfiles = ([[_profilesViewController view] window]==nil);
    
    // dismiss any onscreen dialogs
    [self dismissOnscreeDialogs];
    
    // ...And show the profile selection view if needed
    if (bDisplayProfiles)
    {
        // ...And show the profile selection view
        if (_profilesViewController == nil) {
            _profilesViewController = [[ProfileSelectionViewController alloc] initWithFrame:CGRectZero withMode:kProfileSelectionFromMenuProfilesMode];
        }else{
            [_profilesViewController clearTable];
        }
        
        // position profile selection view
        _profilesViewController.view.frame = CGRectMake(
                                                        PROFILE_SELECTION_DIALOG_X,
                                                        PROFILE_SELECTION_DIALOG_Y,
                                                        _profilesViewController.view.frame.size.width,
                                                        _profilesViewController.view.frame.size.height);
        [self.view addSubview:_profilesViewController.view];
        
        // Set profiles selection view controller in root view, so when profile selected dialog removed
        ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController).profileSelectionViewController = _profilesViewController;
        // set up delegate for profile view controller
        [_profilesViewController setDelegate:(RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController];
        
        
        // adjust frame to allow profile view to accept input
        [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, _profilesViewController.view.frame.origin.x + _profilesViewController.view.frame.size.width, self.view.frame.size.height)];
    }
}


/**
 * Help button tapped
 * display help dialog
 */
- (void)helpTapped {
    
    // dismiss any other active menus
    [self dismissOnscreeDialogs];
    
    // popover
    UIPopoverController *popover;
        popover = [[UIPopoverController alloc] initWithContentViewController:self];
        popover.delegate = self;
    
    
    self.popcon = popover;

    
    UIImage *i = [UIImage imageNamed:@"help_screen.png"];
    UIImageView *helpImage = [[UIImageView alloc] initWithImage:i];
    [helpImage sizeToFit];
    
    UIScrollView *helpScrollView = [[UIScrollView alloc] initWithFrame:helpImage.frame];
    [helpScrollView setContentSize:CGSizeMake(600,10220)];//5466
    helpScrollView.userInteractionEnabled =YES;
    helpScrollView.scrollEnabled = YES;
    helpScrollView.showsVerticalScrollIndicator = NO;
    [helpScrollView addSubview:helpImage];
    
    UIViewController* vc = [[UIViewController alloc] init];
    vc.view.frame = CGRectMake(0, 0, 600, 700);
    vc.view.userInteractionEnabled = YES;
    vc.view.backgroundColor = [UIColor whiteColor];

    UIViewController* vc2 = [[UIViewController alloc] init];
    vc2.view.frame = CGRectMake(0, 0, 600, 700);
    vc2.view.userInteractionEnabled = YES;
    vc2.view.backgroundColor = [UIColor whiteColor];

    UIButton* close = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    close.frame = CGRectMake(520, 10, 70, 40);
    [close addTarget:self action:@selector(closeClicked:) forControlEvents:UIControlEventTouchUpInside];


    vc.view = helpScrollView;
    
    [vc2.view addSubview:vc.view];
    [vc2.view addSubview:close];
    //[vc.view addSubview:helpScrollView];
    //vc.view.userInteractionEnabled = YES;
    popover.popoverContentSize= vc2.view.frame.size;
    popover.contentViewController = vc2;
    
    CGRect f = CGRectMake(250, 700, 80, 50);
    [popover presentPopoverFromRect:f
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionLeft 
                           animated:YES];
}

/**
 * Close help dialog button clicked
 */
- (void) closeClicked: (UIControl*) control
{
    [self.popcon dismissPopoverAnimated:YES];
}

/**
 * Dismiss login assistant if it is onscreen
 */
- (void) dismissLoginAssistantDialog
{
    [loginAssistantManager dismissLoginAssistantDialogs];
}

/**
 * Dismiss settings dialog if it is onscreen
 */
- (void)  dismissSettingsDialog
{
    // If the settings navigation view controller is visible, hide it
    if ([[_settingsNavigationController view] window]) {
        void (^animation)(void) = ^(void) {
            CGRect settingsHiddenFrame = LAUNCHPAD_SETTINGS_FRAME;
            settingsHiddenFrame.origin.y = 900;
            [_settingsNavigationController.view setFrame:settingsHiddenFrame];
            //_settingsNavigationController = nil;
        };
        void (^completion)(BOOL) = ^(BOOL finished) {
            [_settingsNavigationController.view removeFromSuperview];
           // _settingsViewController = nil; Hursh:causes crash on logout object re-cycle (might need workaround)
        };
        [UIView animateWithDuration:LAUNCHPAD_SETTINGS_ANIMATE_TIME animations:animation completion:completion];
    }
}


/**
 * Settings button tapped
 * display settings menu dialog
 */
- (void)settingsTapped {
    
    // if settings not currently displayed want to display them
    BOOL bDisplaySettings = ([[_settingsNavigationController view] window]==nil);
    
    // dismiss any onscreen dialogs
    [self dismissOnscreeDialogs];
    
    // ...And show the profile selection view if needed
    if (bDisplaySettings)
    {
        // show status bar when settings are visible
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        
        //No Need to always re-cycle view
        if (_settingsNavigationController == nil) {
            _settingsViewController = [[ProfileSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            _settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:_settingsViewController];
            _settingsNavigationController.view.frame = LAUNCHPAD_SETTINGS_FRAME;
        
            _settingsViewController.delegate = self;
        }
        // Assemble views
        [self.view.superview addSubview:_settingsNavigationController.view];
        
        // Show the settings navigation view
        CGRect fr = LAUNCHPAD_SETTINGS_FRAME;
        fr.origin.y  = 900;
        [_settingsNavigationController.view setFrame:fr];
        [UIView beginAnimations:@"animateTableView" context:nil];
        [UIView setAnimationDuration:LAUNCHPAD_SETTINGS_ANIMATE_TIME];
        _settingsNavigationController.view.frame = LAUNCHPAD_SETTINGS_FRAME;
        
        [UIView commitAnimations];
    }
}

/**
 * Show Alert advising user that Login Assistant is disabled for this service
 */
+ (void)showLoginAssistantDisabledAlert
{
    // display dialog to let user know that login assistant is disabled for service
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // clear any previous alert
        loginAssistantDisabledAlert = nil;
        
        // set up new login assistant disabled alert
        loginAssistantDisabledAlert = [[UIAlertView alloc] initWithTitle:sLoginAssistantDisabledTitle message:[NSString stringWithFormat:sLoginAssistantDisabledSubTitle] delegate:nil cancelButtonTitle:sLoginAssistantDisabledButtonText otherButtonTitles:nil, nil];
        
        // show login assistant disabled alert
        [loginAssistantDisabledAlert show];
    });
}

/**
 * Dismiss any Login Assistant disabled alert
 */
+ (void)dismissLoginAssistantDisabledAlert
{
    // dismiss any login assistant disabled alert
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // dismiss any login assistant disabled alert
        [loginAssistantDisabledAlert dismissWithClickedButtonIndex:0 animated:NO];
        // clear login assistant disabled alert
        loginAssistantDisabledAlert = nil;
    });
}

/**
 * Easy Login button tapped
 * display easy login dialog
 */
- (void)easyLoginTapped: (UIButton*) control {

    // assign view for login assistant to service view
    UIView* sessionView = [[MenuCommands get] getCurrentSession].view;
    
    // if no session view then don't to activate attempt login assistant
    if (nil!=sessionView)
    {
        // dismiss any other onscreen dialogs
        [self dismissOnscreeDialogs];

        // login assistant enabled flag (default to enabled)
        bool bLoginAssistantEnabled = true;
        
        // get currently open session view controller
        UIViewController* currentSessionViewController = [[MenuCommands get] getCurrentSession];
        
        // if it is a framehawk service
        if ([currentSessionViewController isKindOfClass:[FHServiceViewController class]])
        {
            // Obtain the latest session command
            MenuCommands* menu = [MenuCommands get];
            NSDictionary* sessionInfo = [menu getCommandWithName:[((FHServiceViewController *)currentSessionViewController) command]];
            
            // Check if session is allowed to support login assistant
            bLoginAssistantEnabled = [SettingsUtils checkServiceInformationForloginAssistantAllowed:sessionInfo];
            
        }

        // is login assistant is enabled for the currently open session?
        if (bLoginAssistantEnabled)
        {
            // create login assistant manager
            loginAssistantManager = [LoginAssistantManager manager];
            //    loginAssistantManager.loginAssistantDelegate = self;
            // start login assistant for view
            [loginAssistantManager performLoginAssistantForView:sessionView];
            // close menu when triggering login assistant
            [self closeMenu];
        }
        else
        {
            // display dialog to let user know that login assistant is disabled for service
            [MenuViewController showLoginAssistantDisabledAlert];
        }
    }
}

/**
 * Handle reset PIN being selected from settings
 */
- (void) didSelectPinResetFromSettings {
    [self settingsTapped];  // settings view will be dismissed 
    
    if([self.delegate respondsToSelector:@selector(didSelectPinResetFromSettings)]){
        [self.delegate didSelectPinResetFromSettings];
    }
}

/**
 * Display status bar if settings are currently active
 */
- (void) displayStatusBarIfSettingsActive
{
    // if settings are active then show status bar
    if ([[_settingsNavigationController view] window]) {

        // show status bar when settings are visible
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    
}


#pragma mark UIPopoverControllerDelegate

/**
 * Tells the delegate that the popover was dismissed.
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popcon = nil;
    //   popoverController = nil;
}

/**
 * Asks the delegate if the popover should be dismissed.
 */
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    
    return YES;
}

/**
 * Asks the delegate whether the specified text should be replaced in the text view.
 */
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    if ([text length]>0) {
        [self openCloseMenu];
        NSDictionary *option = [[NSDictionary alloc] initWithObjectsAndKeys:text,@"search", nil];
        [[MenuCommands get] openApplication:@"" withOption:option];
    }
    
    return YES;
}

/**
 * Handles drawer menu tab being pressed
 */
- (void)menuTabTouched {
    // if user finger is not currently being held down after pressing menu tab...
    if (!bMenuTabIsCurrentlyPressed)
    {   // set touch menu tab flags
        bMenuTabIsCurrentlyPressed  = true;
        // remove profile selection if onscreen
        [self dismissOnscreeDialogsExcludingLoginAssistant];
        // open/close menu
        [self openCloseMenu];
    }
    else
    {   // clear touch flag (prevents menu tab getting locked in currently pressed state if a release gesture is missed)
        bMenuTabIsCurrentlyPressed  = false;
    }
}

/**
 * Handles drawer menu tab being clicked
 */
- (void) menuTabReleased {
    // clear menu tab pressed button
    bMenuTabIsCurrentlyPressed  = false;
}

/**
 * Remove Profile Selection Dialog
 */
-(void)removeProfileSelection
{
    // remove profile selection if it is active
    [((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController) removeProfileSelectionFromView];
    //_profilesViewController = nil;
    
    
}

/**
 * Dismiss any onscreen dialogs
 * used when user selects another settings icon
 * or closes menu drawer
 */
-(void)dismissOnscreeDialogs
{
    // hide status bar when settings are not visible
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    // dismiss profile selection dialog
    [self removeProfileSelection];
    
    // dismiss settings dialog
    [self dismissSettingsDialog];
    
    // dismiss login assistant
    [self dismissLoginAssistantDialog];
}

/**
 * Dismiss any onscreen dialogs except for login assistant
 * used when user opens or closes menu drawer
 */
-(void)dismissOnscreeDialogsExcludingLoginAssistant
{
    // dismiss profile selection dialog
    [self removeProfileSelection];
    
    // dismiss settings dialog
    [self dismissSettingsDialog];
    
}

/**
 * Open menu panel
 */
- (void) openMenu {
    
    [UIView animateWithDuration:0.6
                     animations:^{
                         UIView* v = self.view;
                         CGRect f = v.frame;
                         f.origin.x = 0;
                         v.frame = f;
                         v.alpha = 1.0;
                     }
     ];
}

/**
 * Close menu panel
 */
- (void) closeMenu {
    
    UIView* v = self.view;
    CGRect f = v.frame;
    
    // ...Hide it by offsetting its frame left such that only the handle is visible...
    f.origin.x = -menuDrawerBGWidth + menuTabMargin;
    
    // Animate the changes
    [UIView animateWithDuration:0.55
                     animations:^(void) {
                         v.frame = f;
                         v.alpha = 0.65;
                     }
     ];
}

/**
 * Toggles menu drawer open and closed
 */
- (void)openCloseMenu {
    
    UIView* v = self.view;
    CGRect f = v.frame;
    
    // If the menu is visible...
    if (f.origin.x >= 0.0) 
    {
        [self closeMenu];
    }
    // Elsewise if the menu is hidden...
    else// if (f.origin.x < 0) //-menuDrawerBGWidth 
    {
        // ...Show it by removing the frame's left offsets and restoring its full height
        [self openMenu];

        // dismiss any active keyboard for currently open session
        UIViewController* uvc = [[MenuCommands get] getCurrentSession];
        if ([uvc isKindOfClass:[FHServiceViewController class]]) {
            [((FHServiceViewController *)uvc) resignFirstResponder];
        }
    }
}


@end
