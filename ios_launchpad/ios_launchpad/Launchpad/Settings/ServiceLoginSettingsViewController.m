//
//  ServiceLoginSettingsViewController.m
//  Launchpad
//
//  Displays Service Login Assistant Settings & Connection Information
//  for a single service.
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "ServiceLoginSettingsViewController.h"
#import "ProfileDefines.h"
#import "MenuCommands.h"
#import "MenuViewController.h"
#import "FHServiceDefines.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"
#import <QuartzCore/QuartzCore.h>

// Service Settings groups
typedef enum {
    SERVICE_SETTING_LOGIN_ASSISTANT_SETTINGS,
    SERVICE_SETTING_CONNECTION_PARAMETERS,
    TOTAL_SERVICE_SETTING_GROUPS,
}ServiceSettingGroups;

// Login Assistant Settings
typedef enum {
    SERVICE_SETTING_LOGIN_ASSISTANT_ENABLED,
    SERVICE_SETTING_LOGIN_ASSISTANT_USER_ID,
    SERVICE_SETTING_LOGIN_ASSISTANT_ENTER_PASSWORD,
//    SERVICE_SETTING_LOGIN_ASSISTANT_REENTER_PASSWORD,
    TOTAL_SERVICE_SETTING_USER_CREDENTIALS,
}ServiceSettingUserCredentials;

// Service settings title
static NSString *const sSeviceSettingsTitle                         = @"%@";
// Service Login Assistant settings strings
static NSString *const sEnableLoginAssistantSubtitle                = @"Enable Login Assistant";
static NSString *const sLoginAssistantUserIdSubtitle                = @"User ID";
static NSString *const sLoginAssistantUserIdPlaceholder             = @"Enter User ID";
static NSString *const sLoginAssistantPasswordSubtitle              = @"Password";
static NSString *const sLoginAssistantPasswordPlaceholder           = @"Enter Password";
static NSString *const sLoginAssistantReEnterPasswordSubtitle       = @"Re-Enter Password";
static NSString *const sLoginAssistantReEnterPasswordPlaceholder    = @"Re-Enter Password";

// Service parameters title
static NSString *const sServiceConnectionParametersTitle            = @"Parameters";

// Framehawk connection types
static NSString *const sFramehawkSecureSession                      = @"Framehawk Secure Session";

// Service Connection Settings strings
static NSString *const sFramehawkTypeSubtitle                       = @"Type: %d";
static NSString *const sFramehawkWebUrlSubtitle                     = @"Web URL: %@";
static NSString *const sFramehawkConnectionURLSubtitle              = @"Framehawk Connection:";
static NSString *const sFramehawkServiceSubtitle                    = @"Service: %@";
static NSString *const sFramehawkRegionSubtitle                     = @"Region: %d";

static NSString *const sWebURLSubtitle                              = @"Web URL";

// Settings Colors & Opacity
#define SERVICE_SETTINGS_TEXT_COLOR             [UIColor whiteColor]
#define SERVICE_SETTINGS_BG_COLOR               [UIColor clearColor]
#define SERVICE_SETTINGS_DIALOG_OPACITY         0.9

// Font sizes
#define SERVICE_SETTINGS_LOGIN_ASSISTANT_CREDENTIALS_FONT_SIZE      15
#define SERVICE_SETTINGS_TITLE_FONT_SIZE                            20
#define SERVICE_SETTINGS_FONT_SIZE                                  15

// Service settings table layout
#define SERVICE_SETTINGS_SPACING                                    8
#define SERVICE_SETTINGS_TITLE_ROW_HEIGHT (SERVICE_SETTINGS_TITLE_FONT_SIZE*2)
#define SERVICE_SETTINGS_LOGIN_ASSISTANT_HEADER_HEIGHT              30
#define SERVICE_SETTINGS_LOGIN_ASSISTANT_FOOTER_HEIGHT              0
static const CGFloat kSettingsEnableLoginAssistantRowHeight         = 50.0;
static const CGFloat kSettingsLoginAssistantDefaultRowHeight        = 50.0;
static const CGFloat kSettingsServiceInformationDefaultRowHeight    = SERVICE_SETTINGS_FONT_SIZE + SERVICE_SETTINGS_SPACING;


// Service Connection Settings
typedef enum {
    SERVICE_SETTING_CONNECTION_TITLE,
    SERVICE_SETTING_CONNECTION_TYPE,
    SERVICE_SETTING_CONNECTION_WEB_URL, 
    SERVICE_SETTING_CONNECTION_URL_TITLE,
    SERVICE_SETTING_CONNECTION_URL,
    SERVICE_SETTING_CONNECTION_SERVICE,
    SERVICE_SETTING_CONNECTION_REGION,
    TOTAL_FRAMEHAWK_SERVICE_SETTING_CONNECTION_PARAMETERS,
}FramehawkServiceSettingConnectionParameters;


// Web browser connection settings
typedef enum {
    WEB_BROWSER_SETTING_CONNECTION_URL,
    TOTAL_WEB_BROWSER_SETTING_CONNECTION_PARAMETERS,
}WebBrowserSettingConnectionParameters;


// Tags for Service Settings UI elements
typedef enum {
    kLoginAssistantUserIdFieldTag       = 2020,
    kLoginAssistantPasswordFieldTag     = 2021,
}LoginAssistantAlertDialogs;


@interface ServiceLoginSettingsViewController ()
{
}

@end

@implementation ServiceLoginSettingsViewController
@synthesize appName, userField, pwdField; 

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // set up service settings menu
    }
    
    return self;
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

/**
 * Handle when view is loaded
 */
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    self.tableView.layer.borderWidth = 0;
    self.tableView.layer.borderColor = [UIColor blackColor].CGColor;
    self.tableView.layer.backgroundColor = [UIColor blackColor].CGColor;
    self.tableView.opaque = YES;
    
    // set no separator between rows
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = SERVICE_SETTINGS_LOGIN_ASSISTANT_HEADER_HEIGHT;
    self.tableView.sectionFooterHeight = SERVICE_SETTINGS_LOGIN_ASSISTANT_FOOTER_HEIGHT;

    // set clear background
    self.tableView.backgroundColor = SERVICE_SETTINGS_BG_COLOR;

    // set background image view for settings
    UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"service_settings_bg"]];
    [iv sizeToFit];
    [[iv layer] setOpacity:SERVICE_SETTINGS_DIALOG_OPACITY];
    [self.tableView setBackgroundView:iv];
    
    // set title to service name
    self.title = [NSString stringWithFormat:sSeviceSettingsTitle, self.appName];
    
    // set up right button for done
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exitSettings:)];

}

/**
 * Handle when view is unloaded
 */
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/**
 * Set up service information
 */
-(void) setServiceInformation:(NSDictionary*)serviceInfo {
    _serviceInformation = (NSMutableDictionary*)serviceInfo;
    
    /* TODO: Use 'service type' here in future */
    // check if native browser service if web browser url is set
    NSString* mobileWebBrowserUrl = [_serviceInformation objectForKey:kWebBrowserURLKey];
    bIsNativeBrowserService   = (0!=[mobileWebBrowserUrl length]);
}

#pragma mark - Table view data source
/**
 * Returns total number of sections within the table view
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return TOTAL_SERVICE_SETTING_GROUPS;
}


/**
 * Display header for section
 * User Login Assistant Credentials, Service Connection Parameters
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}

/**
 * Return number of rows in specified section of table view
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section)
    {
        case SERVICE_SETTING_LOGIN_ASSISTANT_SETTINGS:
        {
           Boolean bAutoLoginToggledOn = [[_serviceInformation valueForKey:kProfileServiceLoginAssistantToggleKey] boolValue];
            // if login assistant is enabled then show all user credentials
            return (bAutoLoginToggledOn ? TOTAL_SERVICE_SETTING_USER_CREDENTIALS : 1);
        }
            break;
        case SERVICE_SETTING_CONNECTION_PARAMETERS:
            if (bIsNativeBrowserService)
                return TOTAL_WEB_BROWSER_SETTING_CONNECTION_PARAMETERS;
            else
                return TOTAL_FRAMEHAWK_SERVICE_SETTING_CONNECTION_PARAMETERS;
            break;
    }
    return 0;
}

/**
 * Return Service Settings cell for specified row in table
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    //    cell.textLabel.textColor = cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.section)
    {
        case SERVICE_SETTING_LOGIN_ASSISTANT_SETTINGS:
            // Configure the cell...
            
            switch (indexPath.row) {
                case     SERVICE_SETTING_LOGIN_ASSISTANT_ENABLED:
                default:
                {
                    // allow selection of user credentials
                    if (SERVICE_SETTING_LOGIN_ASSISTANT_ENABLED==indexPath.row)
                    {
                        cell.textLabel.text = sEnableLoginAssistantSubtitle;
                        
                        // Check Auto-Login allowed from setting service information
                        Boolean bLoginAssistantAllowed = [SettingsUtils checkServiceInformationForloginAssistantAllowed:_serviceInformation];
                        
                        // Save Auto-Login toggled on setting to service information
                        Boolean bAutoLoginToggledOn = [[_serviceInformation valueForKey:kProfileServiceLoginAssistantToggleKey] boolValue];
                        
                        UISwitch* toggleAutoLoginSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                        
                        // if login assistant is not allowed then disable auto login switch
                        if (!bLoginAssistantAllowed)
                        {
                            [toggleAutoLoginSwitch setEnabled:NO];
                        }
                        
                        [toggleAutoLoginSwitch addTarget:self action:@selector(toggleLoginAssistantPressed:)
                                        forControlEvents:UIControlEventValueChanged];
                        
                        toggleAutoLoginSwitch.on = bAutoLoginToggledOn;
                        cell.accessoryView = toggleAutoLoginSwitch;
                        
                        // save login assistant setting
                        [self saveLoginAssistantSetting:bAutoLoginToggledOn];
                    }
                    
                }
                    break;
                    
                case SERVICE_SETTING_LOGIN_ASSISTANT_USER_ID:
                {
                    // set login assistant enter userword title
                    cell.textLabel.text = sLoginAssistantUserIdSubtitle;
                    
                    // get current profiles user id
                    NSString* profileUserId = [SettingsUtils getCurrentUserID];
                    // get information for current profile service
                    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
                    // get profile identifier
                    NSString* pid = [pInfo objectForKey:kProfileIdKey];
                    // get service name
                    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];
                    // get username stored for login assistant for this service
                    NSString* storedUserName = [SettingsUtils loadLoginAssistantUsernameSettingForUserId:profileUserId profileId:pid appName:aName];
                    
                    // set up username text field
                    UITextField *usernameField = [[UITextField alloc] initWithFrame:CGRectMake((cell.bounds.size.width/2), kSettingsLoginAssistantDefaultRowHeight/2,
                        cell.bounds.size.width/2, kSettingsLoginAssistantDefaultRowHeight/2)];
                    [usernameField setBorderStyle:UITextBorderStyleNone];
                    usernameField.userInteractionEnabled = YES;
                    usernameField.tag = kLoginAssistantUserIdFieldTag;
                    usernameField.placeholder = sLoginAssistantUserIdPlaceholder;
                    [usernameField setText:storedUserName];

                    // set password textfield settings
                    [usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [usernameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [usernameField setTextAlignment:UITextAlignmentRight];
                    [usernameField setEnabled:YES];
                    
                    // store username field
                    self.userField = usernameField;
                    self.userField.delegate= self;
                    cell.accessoryView = self.userField;
                }
                    break;

                case SERVICE_SETTING_LOGIN_ASSISTANT_ENTER_PASSWORD:
                {
                    // set login assistant enter password title
                    cell.textLabel.text = sLoginAssistantPasswordSubtitle;

                    // get current profiles user id
                    NSString* profileUserId = [SettingsUtils getCurrentUserID];
                    // get information for current profile service
                    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
                    // get profile identifier
                    NSString* pid = [pInfo objectForKey:kProfileIdKey];
                    // get service name
                    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];

                    // get password stored for login assistant for this service
                    NSString* storedUserPassword = [SettingsUtils loadLoginAssistantPasswordSettingForUserId:profileUserId profileId:pid appName:aName];

                    // set up user password textfield
                    UITextField *passwordField = [[UITextField alloc] initWithFrame:CGRectMake((cell.bounds.size.width/2), kSettingsLoginAssistantDefaultRowHeight/2,
                        cell.bounds.size.width/2, kSettingsLoginAssistantDefaultRowHeight/2)];
                    passwordField.userInteractionEnabled = YES;
                    passwordField.tag = kLoginAssistantPasswordFieldTag;
                    [passwordField setBorderStyle:UITextBorderStyleNone];
                    passwordField.placeholder = sLoginAssistantPasswordPlaceholder;
                    [passwordField setText:storedUserPassword];
                    // set secure entry for password entry
                    [passwordField setSecureTextEntry:YES];
                    
                    // set password textfield settings
                    [passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [passwordField setTextAlignment:UITextAlignmentRight];
                    [passwordField setEnabled:YES];
                    
                    // store password field
                    self.pwdField = passwordField;
                    self.pwdField.delegate = self;
                    cell.accessoryView = self.pwdField;
                }
                    break;
/*
                case SERVICE_SETTING_LOGIN_ASSISTANT_REENTER_PASSWORD:
                {   // password confirmation entry
                    cell.textLabel.text = sLoginAssistantReEnterPasswordSubtitle;
                    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                    NSString* profileUserId = [defaults objectForKey:sLaunchpadCurrentUserIdKey];
                    NSDictionary* pInfo = [_serviceInformation objectForKey:kProfileInfoKey];
                    NSString* pid = [pInfo objectForKey:kProfileIdKey];
                    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];
                    //NSString* profileUserAppId = [profileUserId stringByAppendingFormat:sProfileServiceAppUserId, pid, aName];
                    NSString* profileUserAppPwd = [profileUserId stringByAppendingFormat:sProfileServiceAppUserPwd, pid, aName];
                    
                    UITextField *passwordField = [[UITextField alloc] initWithFrame:CGRectMake(250, 5, 260, cell.frame.size.height-10)];
                    passwordField.userInteractionEnabled = YES;
                    passwordField.tag = kLoginAssistantPasswordFieldTag;
                    [passwordField setBorderStyle:UITextBorderStyleNone];
                    passwordField.placeholder = sLoginAssistantReEnterPasswordPlaceholder;
                    [passwordField setText:(NSString*)[defaults objectForKey:profileUserAppPwd]];

                    // set secure entry for password entry
                    [passwordField setSecureTextEntry:YES];
 
                    // set password textfield settings
                    [passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [passwordField setTextAlignment:UITextAlignmentRight];
                    [passwordField setEnabled:YES];
                    self.pwdField = passwordField;
                    self.pwdField.delegate = self;
                    [cell addSubview:self.pwdField];
                }
                    break;
*/                    
            }
            
            break;
        
        case SERVICE_SETTING_CONNECTION_PARAMETERS:
        {
            // Configure the cell...
            // connection params style1 - text title on left and detail text on right
            // don't allow selection of connection settings
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            // Parameters are displayed on clear color
            cell.backgroundColor = [UIColor clearColor];
            
            // if native nrowser service
            if (bIsNativeBrowserService)
            {
                cell.textLabel.text = sWebURLSubtitle;
                cell.detailTextLabel.text = (NSString*)[_serviceInformation objectForKey:kWebBrowserURLKey];
            }
            else
            {   // Framahawk service connection
                cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                // set default font size
                cell.textLabel.font = [UIFont systemFontOfSize:SERVICE_SETTINGS_FONT_SIZE];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:SERVICE_SETTINGS_FONT_SIZE];
                // default indent for parameters
                cell.indentationLevel = 1;
                
                switch (indexPath.row)
                {
                    case SERVICE_SETTING_CONNECTION_TITLE:
                    {
                        // set title for service connection parameters
                        cell.textLabel.text = sServiceConnectionParametersTitle;
                        // set bold font for connection parameters title
                        cell.textLabel.font = [UIFont boldSystemFontOfSize:SERVICE_SETTINGS_TITLE_FONT_SIZE];
                        // don't indent the title
                        cell.indentationLevel = 0;
                    }
                        break;
                     
                    // Service Type
                    case SERVICE_SETTING_CONNECTION_TYPE:
                    {
                        NSNumber*  t = [_serviceInformation objectForKey:kFramehawkServiceTypeKey];
                        cell.textLabel.text = [NSString stringWithFormat:sFramehawkTypeSubtitle, [t intValue]];
                        
                    }
                        break;

                    // Service Web URL
                    case SERVICE_SETTING_CONNECTION_WEB_URL:
                    {
                        // set up web url string
                        NSString *webUrlString = [NSString stringWithFormat:sFramehawkWebUrlSubtitle, (NSString*)[_serviceInformation objectForKey:kFramehawkWebURLKey]];
                        cell.textLabel.text = webUrlString;
                    }
                        break;
                        
                    // Service URL Title
                    case SERVICE_SETTING_CONNECTION_URL_TITLE:
                    {
                        cell.textLabel.text = sFramehawkConnectionURLSubtitle;
                    }
                        break;
                        
                    // Service URL
                    case SERVICE_SETTING_CONNECTION_URL:
                    {
                        cell.textLabel.text = (NSString*)[_serviceInformation objectForKey:kFramehawkURLKey];
                    }
                        break;

                    // Service
                    case SERVICE_SETTING_CONNECTION_SERVICE:
                    {
                        // set up current service string
                        NSString *serviceString = [NSString stringWithFormat:sFramehawkServiceSubtitle, (NSString*)[_serviceInformation objectForKey:kFramehawkServiceIdKey]];
                        cell.textLabel.text = serviceString;
                    }
                        break;

                    // Service Region
                    case SERVICE_SETTING_CONNECTION_REGION:
                    {
                        // set up current region string
                        NSNumber* region = [_serviceInformation objectForKey:kFramehawkServiceRegionKey];
                        NSString *regionString = [NSString stringWithFormat:sFramehawkRegionSubtitle, [region intValue]];
                        cell.textLabel.text = regionString;
                    }
                        break;
                }
                
                // Set Service parameters information text color
                cell.textLabel.textColor        = SERVICE_SETTINGS_TEXT_COLOR;
                cell.detailTextLabel.textColor  = SERVICE_SETTINGS_TEXT_COLOR;
            }
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

/**
 * Return height of row at specified path
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section])
    {
        case SERVICE_SETTING_LOGIN_ASSISTANT_SETTINGS:
        {
            switch ([indexPath row])
            {
                case SERVICE_SETTING_LOGIN_ASSISTANT_ENABLED:
                    return kSettingsEnableLoginAssistantRowHeight;
                break;
                default:
                    return kSettingsLoginAssistantDefaultRowHeight;
                break;
            }
            break;
        }
        break;
            
        case SERVICE_SETTING_CONNECTION_PARAMETERS:
        {
            switch (indexPath.row)
            {
                case SERVICE_SETTING_CONNECTION_TITLE:
                {
                    return SERVICE_SETTINGS_TITLE_ROW_HEIGHT;
                }
            }
        }
        break;
            
            
        default:
            break;
    }
    return kSettingsServiceInformationDefaultRowHeight;
}

/**
 * Handle saving login credential information
 * when user is finished editing a text field
 */
- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    // save user name / pwd 
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];

    // get textfield value
    NSString* val = textField.text;
    
    // set value to nil if zero length
    if (val.length <= 0)
        val = nil;
    
    // Login Assistant user id
    if(textField.tag == kLoginAssistantUserIdFieldTag)
    {
        // save Login Assistant user id
        [SettingsUtils saveLoginAssistantUsernameSetting:val userId:profileUserId profileId:pid appName:aName];
    }
    
    // Login Assistant password
    if(textField.tag == kLoginAssistantPasswordFieldTag)
    {
        // save Login Assistant user password
        [SettingsUtils saveLoginAssistantPasswordSetting:val userId:profileUserId profileId:pid appName:aName];
    }
}

/**
 * Handle saving login assistant setting when user toggles setting
 */
- (void)saveLoginAssistantSetting:(BOOL)bIsLoginAssistantEnabled {
    // save login assistant enabled setting

    // get profile user id
    NSString* profileUserId = [SettingsUtils getCurrentUserID];

    // get profile id
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];

    // get service name
    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];
    
    // save login assistant enabled setting
    [SettingsUtils saveLoginAssistantEnabledSetting:(BOOL)bIsLoginAssistantEnabled userId:profileUserId profileId:pid appName:aName];
    
}

/**
 * Clear credentials for Assisted Login for current service
 */
- (void) clearCredentials {

    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    NSString* aName = [_serviceInformation objectForKey:kProfileServiceLabelKey];
    
    // save empty Login Assistant user id
    [SettingsUtils saveLoginAssistantUsernameSetting:nil userId:profileUserId profileId:pid appName:aName];

    // save empty Login Assistant user password
    [SettingsUtils saveLoginAssistantPasswordSetting:nil userId:profileUserId profileId:pid appName:aName];
    
}

/**
 * Handle Reset Login Assistant
 * Clears Login Assistant credentials
 */
- (void) resetLoginAssistantCredentials
{
    // clear login assistant credentials
    [self clearCredentials];
    self.userField.text = @"";
    self.pwdField.text = @""; 
    [self.tableView reloadData];
}


/**
 * Handle when Login Assistant Enabled switch is toggled
 */
-(void) toggleLoginAssistantPressed:(UISwitch *)sender
{
    // toggle login assistant enabled switch
    if ([(UISwitch*)(sender) isOn])
    {
        DLog(@"Toggled Login Assistant On!!");
    }
    else
    {
        [self clearCredentials];
        DLog(@"Toggled Login Assistant Off!!");
    }
    
    // Save Auto-Login enabled setting to service information
    NSString* value = [NSString stringWithFormat:@"%d", [((UISwitch*)sender) isOn]];
    [_serviceInformation setValue:value forKey:kProfileServiceLoginAssistantToggleKey];

    // Save Auto-Login enabled setting to MenuCommands
    MenuCommands* menu = [MenuCommands get];
    NSDictionary* c = [menu getCommandWithName:[_serviceInformation objectForKey:kProfileServiceLabelKey]];
    // set service login assitant key
    [c setValue:value forKey:kProfileServiceLoginAssistantToggleKey];
    // save menu command with updated service key
    [menu saveCommand:c];
    
    [self.tableView reloadData];
}

/**
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
    
    CGRect r = LAUNCHPAD_SETTINGS_FRAME;
    [[[self navigationController]view] setFrame:r];
    
    [UIView commitAnimations];
}


/**
 * Called when settings dialog has been moved offscreen
 */
- (void) slideSettingsOffscreeEnded:(NSString *)id finished:(BOOL) finished context:(void *) context
{
    [self removeSettingsFromView];
}

/**
 * Remove settings dialog from view
 */
- (void) removeSettingsFromView
{
    // remove settings from view
    [[self view] removeFromSuperview];
    // remove navigation controller from superview
    [[[self navigationController] view] removeFromSuperview];
    // pop off view controler so settings resume from root settings view next time they are selected
    [[self navigationController] popViewControllerAnimated:YES];
}



#pragma mark - Table view delegate

/**
 * Handle when user selects a row in the table
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Did the user select one of the settings?
    switch (indexPath.section)
    {
        case SERVICE_SETTING_LOGIN_ASSISTANT_SETTINGS:
            // Don't allow toggle if login assistant not allowed
            switch (indexPath.row) {
                case     SERVICE_SETTING_LOGIN_ASSISTANT_ENABLED:
                {
                    // check if login assistant is allowed for current service
                    bool bLoginAssistantAllowedForService = [SettingsUtils checkServiceInformationForloginAssistantAllowed:_serviceInformation];
                    
                    // if login assistant is not allowed for service
                    if (!bLoginAssistantAllowedForService)
                    {
                        // display alert that login assistant is disabled
                        [MenuViewController showLoginAssistantDisabledAlert];
                    }
                }
                break;
            }
    }
}

@end
