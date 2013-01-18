/*
 *  ProfileSelectionViewController.m
 *  Framehawk Launchpad
 *
 *  Profile Selection controller used for selecting profile on initial launch
 *  or changing profile from settings.
 *
 *  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
 */


#import <QuartzCore/QuartzCore.h>

#import "CommandCenter.h"
#import "ProfileSelectionViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "ProfileDefines.h"
#import "MenuCommands.h"
#import "SettingsUtils.h"
#import "ProfileStorageManagement.h"
/*
 * Profile selection tabs tag defines
 */
enum eProfileSelectionTags
{
    kInstalledProfilesTag   = 0,
    kLibraryProfilesTag     = 1,
};

typedef enum connectionErrorProfileButtons
{
    kConnectionErrorCancelButton    = 0,
    kConnectionErrorRetryButton     = 1
} connectionErrorButtons;

// Profile Selection Colors & Opacity
#define PROFILE_ENTRY_TEXT_COLOR                [UIColor whiteColor]
#define PROFILE_ENTRY_BG_COLOR                  [UIColor clearColor]
#define PROFILE_SELECTION_DIALOG_OPACITY        0.9
#define PROFILE_SELECTION_SEPARATOR_OPACITY     0.2

@interface ProfileSelectionViewController ()
@end
// State
// - 'Installed Profiles' or 'Profiles Library' view
BOOL bShowInstalledProfiles;
BOOL clearRows;
// UI Components
UITableView* profilesTable;
UITabBar* tabBar;

@interface ProfileSelectionViewController () {
    
}
@end
//*/

@implementation ProfileSelectionViewController
@synthesize delegate, mode;

static const CGFloat PROFILE_SELECTOR_TITLE_HEIGHT      = 48.0f;

static const CGFloat PROFILE_CANCEL_BUTTON_HEIGHT       = 32.0f;
static const CGFloat PROFILE_CANCEL_BUTTON_WIDTH        = 60.0f;
static const CGFloat PROFILE_CANCEL_BUTTON_LEFT_MARGIN  = 10.0f;

static const CGFloat PROFILE_SELECTOR_TAB_HEIGHT        = 54.0f;
static const CGFloat PROFILE_SELECTOR_TAB_VERT_MARGIN   = 50.0f;
static const CGFloat PROFILE_DIALOG_ROW_HEIGHT          = 40.0f;
static const CGFloat PROFILE_DIALOG_TOP_MARGIN          = 48.0f;
static const CGFloat PROFILE_DIALOG_LEFT_MARGIN         = 24.0f;
static const CGFloat PROFILE_DIALOG_RIGHT_MARGIN        = 36.0f;
static const CGFloat PROFILE_DIALOG_TITLE_FONT_HEIGHT   = 25.0f;

//Adding Refresh Button
static const CGFloat PROFILE_REFRESH_BUTTON_HEIGHT       = 32.0f;
static const CGFloat PROFILE_REFRESH_BUTTON_WIDTH        = 60.0f;
static const CGFloat PROFILE_REFRESH_BUTTON_LEFT_MARGIN  = 320.0f;

static const int VIEW_TAG_CANCEL = 10;
static const int VIEW_TAG_REFRESH = 11;
static const int VIEW_TAG_TABLE = 12;
static const int VIEW_TAG_SPINNER = 13;

- (id) initWithFrame:(CGRect) frame withMode: (NSInteger) aMode {
    
    self = [super init];
    if(self){
        
        // mode: 
        // kProfileSelectionInitialSelectionMode - this view is seen in the root view controller (initial profile chooser)  
        // kProfileSelectionFromMenuProfilesMode - this view is seen from menu profiles icon click 
        self.mode = aMode; 
        
        self.title = @"Profiles";
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_selection_bg"]];
        [iv sizeToFit];
        [[iv layer] setOpacity:PROFILE_SELECTION_DIALOG_OPACITY];
        [self.view addSubview:iv];
        
        // set frame size to match image background
        [self.view setFrame:CGRectMake(320, 40, iv.frame.size.width, iv.frame.size.height)];
        
        // Default state
        bShowInstalledProfiles = YES;
        clearRows = NO;
        // Register to observe the command center's state
        /* This enables me to update the state of the application based on the current profile state */
        CommandCenter* c = [CommandCenter get];
        [c addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
    }
    
    return [self init];
}



- (void) dealloc {
    CommandCenter* c = [CommandCenter get];
    [c removeObserver:self forKeyPath:@"state"];
}


#pragma mark -
#pragma mark Observers


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    // If the observed object is the CommandCenter...
    if([object isKindOfClass:[CommandCenter class]]) {
        
        // ...And a value was set to the state attribute...
        NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
        if([kind integerValue] == NSKeyValueChangeSetting) {
            
            // ...And the new state is profile load completion...
            NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
            if([value integerValue] == CC_GENERATED_PROFILE_LIST) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [profilesTable reloadData];
                    [(UIActivityIndicatorView *)[self.view viewWithTag:VIEW_TAG_SPINNER] stopAnimating];
                    [[self.view viewWithTag:VIEW_TAG_SPINNER] removeFromSuperview];
                });
            }
            
            // Handle selected profile was invalid (not found)
            if ([value integerValue] == CC_PROFILE_INVALID) {
                DLog(@"Invalid Profile Selected!\n");
            }
            
        }
    }
}


#pragma mark -
#pragma mark UI Handlers

/*
 * Displays Installed Profiles
 */
- (void)displayInstalledProfiles {
    [profilesTable setEditing:NO animated:YES];
    bShowInstalledProfiles = YES;
    [profilesTable reloadData];
    
    [self.view viewWithTag:VIEW_TAG_REFRESH].hidden = YES;
}

/*
 * Displays (uninstalled) Library Profiles
 */
- (void)displayLibraryProfiles {
    [profilesTable setEditing:NO animated:YES];
    bShowInstalledProfiles = NO;
    
    [profilesTable reloadData];
    
    if (self.mode == kProfileSelectionFromMenuProfilesMode){
        [self refreshButtonClicked:nil];
    
    }
    
    [self.view viewWithTag:VIEW_TAG_REFRESH].hidden = NO;
    //self.navigationItem.rightBarButtonItem = nil;
}
/*
 * Clear Table of Profiles
 */
-(void)clearTable{
    clearRows = YES;
    [profilesTable reloadData];
}

/*
 * Done button tapped on profile dialog
 */
- (void)doneTapped:(id)sender {
    [profilesTable setEditing:NO animated:YES];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                           target:self
                                                                                           action:@selector(editTapped:)];
}

/*
 * Edit tapped on profile dialog
 */
- (void)editTapped:(id)sender {
    [profilesTable setEditing:YES animated:YES];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneTapped:)];
}

#pragma mark -
#pragma mark UITableViewDataSource Implementation

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    // only installed profiles are editable
    return bShowInstalledProfiles && !clearRows;
}


/*
 * Commit any changes after editing profiles
 */
- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    
    // If displaying "Installed Profiles...
    if (bShowInstalledProfiles) {
        // ...Lookup the profile and delete it
        CommandCenter* profiles = [CommandCenter get];
        NSMutableDictionary* downloads = profiles.installedProfiles;
        
        NSDictionary* profile = [downloads objectForKey:[[downloads allKeys] objectAtIndex:indexPath.row]];
        
        // get profile Info
        NSMutableDictionary *profileInfo = [profile objectForKey:kProfileInfoKey];
        // get profile Id
        NSString* profileId = [profileInfo objectForKey:kProfileIdKey];

        // Profile Id was not being stored as string - make a NSString containing the profile Id
        NSString *profileIdStr = [NSString stringWithFormat: @"%@", profileId];
        // get the currently active profile id string
        NSString* currentProfileId = [SettingsUtils getSelectedProfileId];

        // if we are deleting the currently active profile
        if ([currentProfileId compare:profileIdStr]==NSOrderedSame)
        {
            DLog(@"****** DELETING ACTIVE PROFILE ******");
            // TODO: handle removal of menu & display of profile selection dialog
            // close any open sessions
            [[MenuCommands get] clearAllSessions];
            // close menu
            [[MenuCommands get] clearCommandsWhenSwitchingProfile];
            //
            [[MenuCommands get] setUpCommandForCurrentProfile];
/*
            // remove menu services drawer
            RootViewController* rvc = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
            [rvc removeMenuViewController];
*/
        }

        // delete selected profile
        [downloads removeObjectForKey:profileId];
        
        
        //Delete here....
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [ProfileStorageManagement deleteProfile:profileId];
        });
        
        [profiles saveInstalledProfiles];
        
        NSArray* paths = [NSArray arrayWithObjects:indexPath, nil];
        [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

/*
 * Return number of rows in specified table section
 */
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Obtain the downloaded profiles list from user preferences
    CommandCenter* profiles = [CommandCenter get];
    int totalProfilesInView = 0;
    
    if (clearRows) {
        clearRows = NO;
        return 0;
    }
    // If showing Installed Profiles...
    if (bShowInstalledProfiles)
    {
        NSMutableDictionary* installedProfiles = profiles.installedProfiles;
        // set to number of installed profiles
        totalProfilesInView = [installedProfiles count];
    }
    else
    {   // otherwise displaying library profiles...
        NSMutableDictionary* uninstalledProfiles = profiles.uninstalledProfiles;
        // set to number of uninstalled profiles
        totalProfilesInView = [uninstalledProfiles count];
    }
    
    return totalProfilesInView;
    
}

/*
 * Return cell for specified location in table
 */
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    // Declare a profile for this cell.
    NSDictionary* profile = nil;
    NSString* profileName = nil;
    BOOL isDownloaded = NO;
    
    // Obtain the list of downloaded profiles
    CommandCenter* profiles = [CommandCenter get];
    NSMutableDictionary* downloads = profiles.installedProfiles;
    NSMutableDictionary* uninstalled = profiles.uninstalledProfiles;

    // uninstalled profiles
//TODO:    NSArray* sortedUninstalledProfiles = [self getUninstalledProfilesSortedByName];//[uninstalled allKeys];
    
    
    // If displaying library profiles...
    if (!bShowInstalledProfiles) {
        // Obtain this row's profiles template
        profile = [uninstalled objectForKey:[[uninstalled allKeys] objectAtIndex:indexPath.row]];
        profileName = [profile objectForKey:kProfileNameKey];
    }
    // Elsewise, for "Installed Profiles"...
    else {
        profile = [downloads objectForKey:[[downloads allKeys] objectAtIndex:indexPath.row]];
        // get profile Info
        NSMutableDictionary *profileInfo = [profile objectForKey:kProfileInfoKey];
        // get profile Name
        profileName = [profileInfo objectForKey:kProfileNameKey];
    }
    
    // Obtain a cell
    UITableViewCell* c = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
    if(!c){
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"profileCell"];
    
        [c setClearsContextBeforeDrawing:YES];
        [c setOpaque:NO];
    }
    
    // Update and return the cell
    if(profileName){
        c.textLabel.text = nil;
        c.textLabel.text = profileName;
        c.accessibilityLabel = profileName;
    }
    
    c.textLabel.textColor = PROFILE_ENTRY_TEXT_COLOR;
    
    // Add separator image for cell
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_divider"]];
    [[separator layer] setOpacity:PROFILE_SELECTION_SEPARATOR_OPACITY];
    [c.contentView addSubview: separator];
    
    if (isDownloaded || bShowInstalledProfiles)
        c.imageView.image = [UIImage imageNamed:@"profile_installed_icon"];
    else
        c.imageView.image = [UIImage imageNamed:@"profile_uninstalled_icon"];
    
    return c;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark UITableViewDelegate Implementation

/*
 * Handle selection of a profile at a particular view
 */
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    // Declare the selected profile.
    NSDictionary* profile = nil;
    NSNumber* profileId = nil;
    
    {
        
        // If displaying library profiles ...
        if (!bShowInstalledProfiles) {
            // ...Select the profile template for this row
            if (![CommandCenter networkIsAvailable]) {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                             message:@"Unable to retrieve profile list – you appear to not have an internet connection. Try again?"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Ok", nil];
                // store connection index - used to associate alert with view, when displaying delayed alerts
                [av show];
                av = nil;
                return;
            }
            
            
            CommandCenter* profiles = [CommandCenter get];
            NSMutableDictionary* uninstalled = profiles.uninstalledProfiles;
            
            profile = [uninstalled objectForKey:[[uninstalled allKeys] objectAtIndex:indexPath.row]];
            profileId = [profile objectForKey:kProfileIdKey];
            
            clearRows = YES;
            [profilesTable reloadData];
            
            
            //Save all assets in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [ProfileStorageManagement storeProfile:profileId];
            });
        }
        // Elsewise, for "My Profiles"...
        else {
            
            
            
            
            // If displaying library profiles ...
            if (!bShowInstalledProfiles) {
                // ...Select the profile template for this row
                CommandCenter* profiles = [CommandCenter get];
                NSMutableDictionary* uninstalled = profiles.uninstalledProfiles;
                
                profile = [uninstalled objectForKey:[[uninstalled allKeys] objectAtIndex:indexPath.row]];
                profileId = [profile objectForKey:kProfileIdKey];
            }
            // Elsewise, for "My Profiles"...
            else {
                
                // ...Select the download profile for this row
                CommandCenter* profiles = [CommandCenter get];
                NSMutableDictionary* downloads = profiles.installedProfiles;
                
                profile = [downloads objectForKey:[[downloads allKeys] objectAtIndex:indexPath.row]];
                
                // get profile Info
                NSMutableDictionary *profileInfo = [profile objectForKey:kProfileInfoKey];
                // get profile Name
                profileId = [profileInfo objectForKey:kProfileIdKey];
                
            }
        }
        
        // Update user preferences
        [SettingsUtils setSelectedProfileId:[profileId stringValue]];
        

        // close menu drawer
        if([self.delegate respondsToSelector:@selector(didSelectProfile:fromController:)]){
            [self.delegate didSelectProfile:profile fromController:self];  // remove self also 
        }
    }   
}



#pragma mark -
#pragma mark UIViewController Implementation


- (void) loadView {
    
    // Obtain my view
    UIView* v = [[UIView alloc] init];
    
    // Assign my view
    self.view = v;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


- (void)viewDidUnload {
    profilesTable = nil;
}

/*
 * View will appear -
 * Sets up profile 
 */
- (void)viewWillAppear:(BOOL)animated {
    
    UIView* v = self.view;
    
    // Profiles List
    profilesTable = [[UITableView alloc] initWithFrame:CGRectZero style: UITableViewStylePlain];
    profilesTable.dataSource = self;
    profilesTable.delegate = self;
    profilesTable.backgroundColor = [UIColor clearColor];
    profilesTable.rowHeight = PROFILE_DIALOG_ROW_HEIGHT;
    profilesTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    profilesTable.tag = VIEW_TAG_TABLE;
    [v addSubview:profilesTable];
    
    
    // get number of installed profiles
    CommandCenter* profiles = [CommandCenter get];
    NSMutableDictionary* installedProfiles = profiles.installedProfiles;
    int installedProfilesCount = [installedProfiles count];
    
    // Profile selection title
    UILabel* title = [[UILabel alloc] init];
    title.backgroundColor = [UIColor clearColor];
    title.text = @"Choose a Profile";
    title.textAlignment = UITextAlignmentCenter;
    title.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont systemFontOfSize:PROFILE_DIALOG_TITLE_FONT_HEIGHT];
    
    
    // Set Installed Profiles Tab
    UITabBarItem *installedProfilesItem = [[UITabBarItem alloc] initWithTitle:@"Installed" image:[UIImage imageNamed:@"installed_profiles_tab_icon"] tag:kInstalledProfilesTag];
    
    // Set Profiles Library Tab
    UITabBarItem *libraryProfilesItem = [[UITabBarItem alloc] initWithTitle:@"Library" image:[UIImage imageNamed:@"library_profiles_tab_icon"] tag:kLibraryProfilesTag];
    
    // Profiles Tab Bar
    tabBar = [[UITabBar alloc] init];
    tabBar.delegate = self;
    tabBar.backgroundColor = [UIColor clearColor];
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:installedProfilesItem, libraryProfilesItem, nil];
    
    // set up toolbar items
    [tabBar setItems:toolBarItems];   
    
    
    // if user already has at least one profile installed...
    if (installedProfilesCount>0)
    {
        // ...set default selection to installed profiles
        [tabBar setSelectedItem:installedProfilesItem];
        // display installed profiles
        [self displayInstalledProfiles];
    }
    else
    {
        // otherwise set default selection to library profiles
        [tabBar setSelectedItem:libraryProfilesItem];
        
        [self clearTable];
        
        // display library profiles
        [self displayLibraryProfiles];
    }
    
    
    // set cancel button
    UIButton* cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    cancel.tag = VIEW_TAG_CANCEL;
    
    UIButton* refresh = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [refresh setTitle:@"Refresh" forState:UIControlStateNormal];
    [refresh addTarget:self action:@selector(refreshButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    refresh.tag = VIEW_TAG_REFRESH;
    
    refresh.hidden = (self.mode == kProfileSelectionFromMenuProfilesMode);
    cancel.hidden = (self.mode == kProfileSelectionInitialSelectionMode); 
    
    [v addSubview:title];
    [v addSubview:tabBar];
    [v addSubview:refresh];
    [v addSubview:cancel];
    
    // Allow editing
    self.editing = YES;
    
    // Populate navigation items
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped:)];
    
    
    // Layout
    // - My view
    CGRect f = self.view.frame;
    // - Title
    f.origin.x  = 0;
    f.origin.y  = PROFILE_DIALOG_TOP_MARGIN;
    f.size.height = PROFILE_SELECTOR_TITLE_HEIGHT;
    title.frame = f;
    
    // cancel button at top left of title bar
    f.origin.x  = PROFILE_DIALOG_LEFT_MARGIN + PROFILE_CANCEL_BUTTON_LEFT_MARGIN;
    f.origin.y  = PROFILE_DIALOG_TOP_MARGIN+(PROFILE_SELECTOR_TITLE_HEIGHT-PROFILE_CANCEL_BUTTON_HEIGHT)/2;
    f.size.height = PROFILE_CANCEL_BUTTON_HEIGHT;
    f.size.width = PROFILE_CANCEL_BUTTON_WIDTH;
    cancel.frame = f;
    
    f.origin.x  = PROFILE_DIALOG_LEFT_MARGIN + PROFILE_REFRESH_BUTTON_LEFT_MARGIN;
    f.origin.y  = PROFILE_DIALOG_TOP_MARGIN+(PROFILE_SELECTOR_TITLE_HEIGHT-PROFILE_REFRESH_BUTTON_HEIGHT)/2;
    f.size.height = PROFILE_REFRESH_BUTTON_HEIGHT;
    f.size.width = PROFILE_REFRESH_BUTTON_WIDTH;
    refresh.frame = f;
    
    // Tab Bar at bottom of profile selector
    f.size.width    = self.view.frame.size.width - (PROFILE_DIALOG_LEFT_MARGIN + PROFILE_DIALOG_RIGHT_MARGIN);
    f.size.height   = PROFILE_SELECTOR_TAB_HEIGHT;
    f.origin.x      = PROFILE_DIALOG_LEFT_MARGIN;
    f.origin.y      = self.view.frame.size.height - PROFILE_SELECTOR_TAB_HEIGHT -  PROFILE_SELECTOR_TAB_VERT_MARGIN;
    tabBar.frame = f;
    
    // - 'Profiles' table
    f = self.view.frame;
    f.origin.x = PROFILE_DIALOG_LEFT_MARGIN;
    f.origin.y = PROFILE_DIALOG_TOP_MARGIN+PROFILE_SELECTOR_TITLE_HEIGHT;
    f.size.height = self.view.frame.size.height - (PROFILE_DIALOG_TOP_MARGIN + PROFILE_SELECTOR_TITLE_HEIGHT) - (PROFILE_SELECTOR_TAB_HEIGHT + PROFILE_SELECTOR_TAB_VERT_MARGIN);
    f.size.width = self.view.frame.size.width - (PROFILE_DIALOG_LEFT_MARGIN + PROFILE_DIALOG_RIGHT_MARGIN);
    profilesTable.frame = f;

    
    // If the user has a currently selected profile, select it in the profiles table
    NSString* p = [SettingsUtils getSelectedProfileId];
    if (p) {
        NSArray* templates = [CommandCenter get].templates;
        for (NSUInteger i = 0, l = [templates count]; i < l; i++) {
            NSDictionary* template = [[CommandCenter get].templates objectAtIndex:i];
            if ([[template objectForKey:kProfileIdKey] integerValue] == [p integerValue]) {
                //                NSUInteger x[] = {0, i};
                //                NSIndexPath* p = [[NSIndexPath alloc] initWithIndexes:x  length:2];
                //                [profilesTable selectRowAtIndexPath:p animated:UITableViewRowAnimationFade scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

/*
 * User clicked cancel button on profile selection dialog
 */
- (void) cancelButtonClicked: (UIButton*) button
{
    // dismiss profile selection dialog
    DLog(@"cancelButtonClicked!");
    
    // cancel profile selection (will close menu drawer)
    if([self.delegate respondsToSelector:@selector(didCancelProfileSelection:)]){
        [self.delegate didCancelProfileSelection:self];
    }
}
-(void)refreshButtonClicked: (UIButton *)button{
    DLog(@"refreshButtonClicked");
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // Get the command center
        CommandCenter* c = [CommandCenter get];
        // get list of profiles
        FHGetProfilesListResponse getProfilesListResponse = ^(NSData* response, NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                // If the get profiles list attempt was successful...
                if ((!error) && (response!=nil)) {
                    CommandCenter* c = [CommandCenter get];
                    [c parseProfilesListData:response];
                }else{
                    
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                 message:@"Unable to retrieve profile list, Try again?"
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                       otherButtonTitles:@"Ok", nil];
                    // store connection index - used to associate alert with view, when displaying delayed alerts
                    [av show];
                    av = nil;
                }
                
                    [(UIActivityIndicatorView *)[self.view viewWithTag:VIEW_TAG_SPINNER] stopAnimating];
                    [[self.view viewWithTag:VIEW_TAG_SPINNER] removeFromSuperview];
                
                
            });
        };
        
        UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.center = [self.view viewWithTag:VIEW_TAG_TABLE].center;
        spinner.tag = VIEW_TAG_SPINNER;
        [self.view addSubview:spinner];
        [spinner startAnimating];
        // Attempt get profiles list
        [c getProfilesList:getProfilesListResponse];
    });
    
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kConnectionErrorRetryButton) {
        NSIndexPath*    selection = [profilesTable indexPathForSelectedRow];
        CommandCenter* profiles = [CommandCenter get];
        if (selection) {
            [profilesTable deselectRowAtIndexPath:selection animated:YES];
        }
        
        if (![CommandCenter networkIsAvailable]){
            [profiles deleteUnInstalledProfiles];
            [profilesTable reloadData];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                         message:@"Unable to retrieve profile list – you appear to not have an internet connection. Try again?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Ok", nil];
            // store connection index - used to associate alert with view, when displaying delayed alerts
            [av show];
            av = nil;
            
            return;
        }
        

        
        [profiles saveInstalledProfiles];
        [self refreshButtonClicked:nil];
        return;
    }
    
    if (buttonIndex == kConnectionErrorCancelButton) {
        //Cancel no longer goes to login screen CSP-43
       /* RootViewController * r = ((RootViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).viewController);
        
        if ([[[r menuViewController] view] superview]) {
            [(UIActivityIndicatorView *)[self.view viewWithTag:VIEW_TAG_SPINNER] stopAnimating];
            [[self.view viewWithTag:VIEW_TAG_SPINNER] removeFromSuperview];
            return;
        }
        
        r.bforceLoginScreen = YES;
        
        [[self view] removeFromSuperview];
        [r showLoginView];
        */
        NSIndexPath*    selection = [profilesTable indexPathForSelectedRow];
        if (selection) {
            [profilesTable deselectRowAtIndexPath:selection animated:YES];
        }
    }
}
/*
 * tabBar didSelectItem
 * Handles selection of tab item
 */
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (item.tag)
    {
        case kInstalledProfilesTag:
            // display installed profiles
            [self displayInstalledProfiles];
            break;
        case kLibraryProfilesTag:
            // display (uninstalled) library profiles
            [self displayLibraryProfiles];
            break;
    }
}


/**
 * Get array of keys of uninstalled profiles sorted by profile name
 */
-(NSArray*)getUninstalledProfilesSortedByName
{
    // Obtain the list of downloaded profiles
    CommandCenter* profiles = [CommandCenter get];
    NSMutableDictionary* uninstalled = profiles.uninstalledProfiles;
    
    // uninstalled profiles
    NSArray* sortedUninstalledProfiles = [uninstalled allKeys];
    
    //[uninstalled keysSortedByValueUsingSelector:];
    // sort uninstalled profiles by profile name
    // kProfileNameKey
    
    // return uninstalled profiles sorted by profile name
    return sortedUninstalledProfiles;
}




@end