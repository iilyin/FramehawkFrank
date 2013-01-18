//
//  ProfileSettingsViewController.m
//  Launchpad
//
//  Displays settings information for current profile:
//
//   Current profile.
//   List of services for current profile (can be selected to get detailed info).
//   User logged in information.
//   Application version information.
//   Reset user login button.
//   Reset application PIN button.
//
//  Created by Rich Cowie on 5/31/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "CommandCenter.h"
#import "GlobalDefines.h"
#import "MenuCommands.h"
#import "ProfileDefines.h"
#import "ProfileSettingsViewController.h"
#import "ProfileUtils.h"
#import "ServiceLoginSettingsViewController.h"
#import "SettingsUtils.h"

// Launchpad settings groups
typedef enum {
    LAUNCHPAD_SETTINGS_PROFILE,
    LAUNCHPAD_SETTINGS_SERVICES,
    LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO,
    LAUNCHPAD_VERSION_INFORMATION,
    LAUNCHPAD_SETTINGS_USER_RESET_LOGIN,
    LAUNCHPAD_SETTINGS_USER_RESET_PIN,
    TOTAL_LAUNCHPAD_SETTINGS_GROUPS,
}LaunchpadSettingGroups;

// Layout
#define LAUNCHPAD_SETTINGS_ROW_SPACING                      12
#define LAUNCHPAD_SETTINGS_ROW_HEIGHT                       20
#define LAUNCHPAD_SETTINGS_BUTTON_ROW_HEIGHT                60
#define LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO_ROW_HEIGHT   (LAUNCHPAD_SETTINGS_LOGGED_IN_AS_FONT_SIZE + LAUNCHPAD_SETTINGS_ROW_SPACING)
#define LAUNCHPAD_SETTINGS_CURRENT_SERVICES_ROW_HEIGHT       LAUNCHPAD_SETTINGS_CURRENT_SERVICES_FONT_SIZE + LAUNCHPAD_SETTINGS_ROW_SPACING

// Settings Colors & Opacity
#define LAUNCHPAD_SETTINGS_BG_COLOR             [UIColor clearColor]
#define LAUNCHPAD_SETTINGS_TEXT_COLOR           [UIColor whiteColor]
#define LAUNCHPAD_SETTINGS_SEPARATOR_COLOR      [UIColor clearColor]
#define LAUNCHPAD_SETTINGS_BORDER_COLOR         [UIColor clearColor]
#define LAUNCHPAD_SETTINGS_DIALOG_OPACITY       0.9
#define LAUNCHPAD_SETTINGS_SEPARATOR_OPACITY    0.2

// Font sizes
#define LAUNCHPAD_SETTINGS_CURRENT_PROFILE_FONT_SIZE    20
#define LAUNCHPAD_SETTINGS_CURRENT_SERVICES_FONT_SIZE   20
#define LAUNCHPAD_SETTINGS_LOGGED_IN_AS_FONT_SIZE       15

//AlertView Logout tag
#define LAUNCHPAD_LOGOUT_ALERTVIEW_TAG  1

// Launchpad Settings
static NSString *const kLaunchpadSettingsTitle  = @"Settings";

// Launchpad Current Profile Title
static NSString *const kCurrentProfileTitle     = @"Current profile: %@";

// Launchpad User Credentials
static NSString *const kLoggedInAsUserIdTitle   = @"Logged in as %@";

// Launchpad button titles
static NSString *const kUserLogout              = @"Reset Framehawk Login";
static NSString *const kUserPINResetTitle       = @"Reset PIN";

// Version Information
static NSString *const kVersionTitle            = @"Version: %@";


@implementation ProfileSettingsViewController
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        // Register to observe the Launchpad profile
        CommandCenter* c = [CommandCenter get];
        [c addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

        self.view.frame = LAUNCHPAD_SETTINGS_FRAME;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.scrollEnabled = YES;
        
        // no header or footer spacing on sections
        self.tableView.sectionHeaderHeight = 0;
        self.tableView.sectionFooterHeight = 0;
        
        // set background view image for settings
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"service_settings_bg"]];
        [iv sizeToFit];
        [[iv layer] setOpacity:LAUNCHPAD_SETTINGS_DIALOG_OPACITY];
        
        [self.tableView setBackgroundView:iv];
    }
    return self;
}


- (void) dealloc {
    CommandCenter* c = [CommandCenter get];
    [c removeObserver:self forKeyPath:@"state"];
}


#pragma mark -
#pragma mark Observers


- (void) refreshProfile {
    [self.tableView reloadData];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    // If the observed object is the command center...
    if ([object isKindOfClass:[CommandCenter class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is menu complete...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if ([value integerValue] == CC_MENU_COMPLETE) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    // ...Refresh my profile aspects
                    [self refreshProfile];
                });
            }
        }
    }
}

/**
 * Handle settings view appearing
 * Shows status bar when settings are displayed
 */
- (void)viewWillAppear:(BOOL)animated
{
    // view will appear
	[super viewWillAppear:animated];
    
    // show status bar when settings are displayed
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // set up title for launchpad settings
    self.title = kLaunchpadSettingsTitle;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = LAUNCHPAD_SETTINGS_SEPARATOR_COLOR;
    self.tableView.layer.borderColor = LAUNCHPAD_SETTINGS_BORDER_COLOR.CGColor;
    self.tableView.layer.borderWidth = 0;
    self.tableView.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;

    // set up right button for done
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exitSettings:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return TOTAL_LAUNCHPAD_SETTINGS_GROUPS;
}

/*
 * Return number of rows in section
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section)
    {
        case LAUNCHPAD_SETTINGS_PROFILE:
        case LAUNCHPAD_VERSION_INFORMATION:
        case LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO:
        case LAUNCHPAD_SETTINGS_USER_RESET_LOGIN:
        case LAUNCHPAD_SETTINGS_USER_RESET_PIN:
            return 1;
            break;
        case LAUNCHPAD_SETTINGS_SERVICES:
        {
            // get currentlu installed profile
            NSMutableDictionary* currentProfile = [[CommandCenter get] getCurrentProfile];
            // get total services in profile
            int totalServices = [ProfileUtils getTotalServicesInProfile:currentProfile];
            // return total services in profile
            return totalServices;
        }
            break;
    }
    return 0;
}

/*
 * Get table cell
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:18];
    
    
    switch (indexPath.section)
    {
        // Display current profile information
        case LAUNCHPAD_SETTINGS_PROFILE:
        {
            // set font color
            cell.textLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;
            // set font size
            cell.textLabel.font = [UIFont systemFontOfSize:LAUNCHPAD_SETTINGS_CURRENT_PROFILE_FONT_SIZE];
            NSDictionary* profile = [MenuCommands get].launchpadProfile;
            NSDictionary* pinfo = [profile objectForKey:kProfileInfoKey];
            NSString* name = [pinfo objectForKey:kProfileNameKey];
            // set up current profile string
            NSString *titleString = [NSString stringWithFormat:kCurrentProfileTitle, name];
            // set current profile title
            cell.accessibilityLabel = titleString;
            cell.textLabel.text = titleString;
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
            break;
            
        // Display current profiles services
        case LAUNCHPAD_SETTINGS_SERVICES:
        {
            // get current profile
            NSMutableDictionary* currentProfile = [[CommandCenter get] getCurrentProfile];
            
            // set up service name string
            NSString *serviceNameString = [ProfileUtils getApplicationNameForProfile:currentProfile withIndex:[indexPath row]];
            cell.accessibilityLabel = serviceNameString;
            cell.textLabel.text = serviceNameString;
            cell.textLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;

            // display service names in bold
            cell.textLabel.font = [UIFont boldSystemFontOfSize:LAUNCHPAD_SETTINGS_CURRENT_SERVICES_FONT_SIZE];
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            // set arrow at end of cell
            cell.accessoryType =  UITableViewCellAccessoryDetailDisclosureButton;
        }
            break;
         
        // Display logged in as user information
        case LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO:
        {
            // Get current user id
            NSString* userID = [SettingsUtils getCurrentUserID];
            // set up logged in as string
            NSString *titleString = [NSString stringWithFormat:kLoggedInAsUserIdTitle, userID];
            cell.accessibilityLabel = titleString;
            cell.textLabel.text = titleString;
            cell.textLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;
            cell.textLabel.font = [UIFont systemFontOfSize:LAUNCHPAD_SETTINGS_LOGGED_IN_AS_FONT_SIZE];
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
            break;

        // Display Launchpad version information
        case LAUNCHPAD_VERSION_INFORMATION:
        {
            // get version from settings
            NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            // set up version string
            NSString *versionString = [NSString stringWithFormat:kVersionTitle, version];
            cell.accessibilityLabel = versionString;
            cell.textLabel.text = versionString;
            cell.textLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;
            cell.textLabel.font = [UIFont systemFontOfSize:LAUNCHPAD_SETTINGS_LOGGED_IN_AS_FONT_SIZE];
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
            break;
            
        // Launchpad reset login button
        case LAUNCHPAD_SETTINGS_USER_RESET_LOGIN:
        {   // Reset Framehawk Login button
            UIButton* b = [UIButton buttonWithType:UIButtonTypeRoundedRect];

            [b setTitle:kUserLogout forState:UIControlStateNormal];
            b.titleLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;
            b.frame = CGRectMake(cell.bounds.size.width/8, 5, cell.bounds.size.width, cell.bounds.size.height);
            [b addTarget:self action:@selector(showLogoutDialog) forControlEvents:UIControlEventTouchUpInside];
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            [cell addSubview:b];
        }
            break;

        // Launchpad reset PIN button
        case LAUNCHPAD_SETTINGS_USER_RESET_PIN:
        {   // Reset PIN
            UIButton* b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [b setTitle:kUserPINResetTitle forState:UIControlStateNormal];
            b.titleLabel.textColor = LAUNCHPAD_SETTINGS_TEXT_COLOR;
            b.frame = CGRectMake(cell.bounds.size.width/8, 5, cell.bounds.size.width, cell.bounds.size.height);
            [b addTarget:self action:@selector(resetPIN) forControlEvents:UIControlEventTouchUpInside];
            cell.backgroundColor = LAUNCHPAD_SETTINGS_BG_COLOR;
            [cell addSubview:b];
        }
            break;
                    
        default:
            cell.textLabel.text = @"";
            break;
    }
    
    return cell;
}

/*
 *  Show logout dialog
 */
-(void)showLogoutDialog{
    //Make Sure User Wants to Logout
    UIAlertView* logout = [[UIAlertView alloc] initWithTitle:@"Logout of Framehawk?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    logout.tag = LAUNCHPAD_LOGOUT_ALERTVIEW_TAG;
    [logout show];
}

/*
 * Handle button clicked for alert
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
        switch (buttonIndex) {
            case 0:
                //Do Nothing on Cancel
                break;
            case 1:{
                    if (alertView.tag == LAUNCHPAD_LOGOUT_ALERTVIEW_TAG) {
                        // dismiss PIN
                        RootViewController * r = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
                        [r removePinView];
                        // logout user
                        [self logOutUser];
                    }
                }
                break;
            default:
                break;
        }
    
}

/*
 * Handle reset PIN
 */
-(void) resetPIN {
    
    if([self.delegate respondsToSelector:@selector(didSelectPinResetFromSettings)]){
        [self.delegate didSelectPinResetFromSettings];
    }
    
}

/*
 * Handle user logout
 */
- (void) logOutUser {
    
    // reset root level profile login
    [self removeSettingsFromView];
    
    // Save installed Profiles
    [[CommandCenter get] saveInstalledProfiles];
    [[CommandCenter get] deleteInstalledProfiles];
    [[CommandCenter get] deleteUnInstalledProfiles];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    // Clear current user PIN
    [SettingsUtils clearCurrentUserPIN];
    
    // clear password setting
    [SettingsUtils clearCurrentUserPassword];
    
    [defaults removeObjectForKey:kProfileIdKey];
    [SettingsUtils clearSelectedProfileId];
    [SettingsUtils clearDefaultProfileId];
    
    //Go off and delete all the open sessions and then remove
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [[MenuCommands get] clearAllSessions];
    
    RootViewController * r = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
    
    [[(MenuViewController *)[r menuViewController] view] removeFromSuperview];
    
    [r.profileSelectionViewController clearTable]; //CSP-60
    r.menuViewController = nil;
    r.bforceLoginScreen = YES;
    [(AppDelegate *)[UIApplication sharedApplication].delegate deleteSession];
    [SettingsUtils clearCurrentUserID];
    [r refreshBackground];
    [r showLoginView];
}

/*
 * Return height for header in section
 */
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}


/*
 * Return height for footer in section
 */
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}


/*
 * Return height of row at specified path
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section])
    {
        case LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO:
        case LAUNCHPAD_VERSION_INFORMATION:
            return LAUNCHPAD_SETTINGS_USER_LOGGED_IN_INFO_ROW_HEIGHT;

        case LAUNCHPAD_SETTINGS_PROFILE:
        case LAUNCHPAD_SETTINGS_SERVICES:
            return LAUNCHPAD_SETTINGS_CURRENT_SERVICES_ROW_HEIGHT;
            
        case LAUNCHPAD_SETTINGS_USER_RESET_LOGIN:
        case LAUNCHPAD_SETTINGS_USER_RESET_PIN:
            return LAUNCHPAD_SETTINGS_BUTTON_ROW_HEIGHT;
            break;
            
        default:
            return LAUNCHPAD_SETTINGS_ROW_HEIGHT;
            break;
    }
}


/*
 * accessoryButtonTappedForRowWithIndexPath
 * - if selector button pressed the pass on as row selection
 */
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // Handle selected accessory arrow - show specific service settings
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}


/*
 * Exit Settings dialog
 */
- (void) exitSettings: (id) sender
{
    // hide status bar when settings are dismissed
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    DLog(@"exitSettings\n");
    // animate settings offscreen
    [UIView beginAnimations:@"slideSettingsOffscreen" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:LAUNCHPAD_SETTINGS_ANIMATE_TIME];
    [UIView setAnimationDidStopSelector:@selector(slideSettingsOffscreeEnded:finished:context:)];
    
    CGRect r =LAUNCHPAD_SETTINGS_FRAME;
    
    [[[self navigationController]view] setFrame:r];
    
    [UIView commitAnimations];
}

/*
 * Called when settings dialog has been moved offscreen
 */
- (void) slideSettingsOffscreeEnded:(NSString *)id finished:(BOOL) finished context:(void *) context
{
    [self removeSettingsFromView];
}

/*
 * Remove settings dialog from view
 */
- (void) removeSettingsFromView
{
    // remove settings from view
    [self.view removeFromSuperview];
    // remove navigation controller from superview ??
    [self.navigationController.view removeFromSuperview];
}

/*
 * Get service information to display for session at given index
 */
-(NSDictionary*) applicationInfoAt:(NSIndexPath*)indexPath
{
    NSMutableDictionary* currentProfile = [[CommandCenter get] getCurrentProfile];
    return [ProfileUtils getApplicationInformationForProfile:currentProfile withIndex:indexPath.row];
}

#pragma mark - Table view delegate
/*
 * Handle selection of table row
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Did the user select an application?
    switch (indexPath.section)
    {
        case LAUNCHPAD_SETTINGS_SERVICES:
        {
            // show detailed service settings
            // get service application name
            UITableViewCell* c= [tableView cellForRowAtIndexPath:indexPath];
            NSString* serviceApplicationName = c.textLabel.text;
            
            // set up service view controller
            ServiceLoginSettingsViewController *loginControl = [[ServiceLoginSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            
            // store application name
            [loginControl setAppName:serviceApplicationName];
            
            // set up service information
            NSDictionary* serviceInfo = [self applicationInfoAt:indexPath];
            [loginControl setServiceInformation:serviceInfo];
            
            // display service view controller
            [self.navigationController pushViewController:loginControl animated:YES];
            
        }
        break;
            
    }
    
}


@end
