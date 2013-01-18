//
//  MenuDataSource.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/17/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "AppDelegate.h"
#import "CloseSessionButton.h"
#import "File.h"
#import "MenuCommands.h"
#import "MenuDataSource.h"
#import "MenuSelectionCell.h"
#import "SettingsUtils.h"
#import "ProfileDefines.h"

#define NUMBER_OF_ALLOWED_COMMANDS 3

@implementation MenuDataSource


-(id)initWithLaunchpadProfile:(NSDictionary*)launchpadProfile {
    self = [super init];
    _dataArray =  [NSArray arrayWithObjects:
                        [NSArray arrayWithObjects: @"Intranet", @"Yammer", @"Email", @"Browser", nil], 
                        [NSArray arrayWithObjects: @"Market News", @"Market Data", @"Sales Presentation", @"Salesforce", nil], 
                        nil];
    
    // set menu button names from current profile
    [self setMenuDataFromProfile];
    [[MenuCommands get] clearCommandsWhenSwitchingProfile];
    
    return self;
}

- (id) init 
{
    self = [super init];
    _dataArray =  [NSArray arrayWithObjects:
                   [NSArray arrayWithObjects: @"Intranet", @"Yammer", @"Email", @"Browser", nil], 
                   [NSArray arrayWithObjects: @"Market News", @"Market Data", @"Sales Presentation", @"Salesforce", nil], 
                   nil];

    // set menu button names from current profile
    [self setMenuDataFromProfile];
    
    return self;
}

/*
 * Set up menu button data names from current profile
 *
 */
- (void) setMenuDataFromProfile
{
    // get button groups from current profile information
    NSDictionary* p = [MenuCommands get].launchpadProfile;
    
    //Necessary for profile asset storage when profile is already installed...
    NSString    *defaultProfileId = [SettingsUtils getDefaultProfileId];
    
    if (defaultProfileId == nil) {
        if (p) {
            [SettingsUtils setDefaultProfileId:[[p objectForKey:kProfileInfoKey] objectForKey:kProfileIdKey]];
        }
    }
    
    
    NSArray *buttonGroups = [p objectForKey:kProfileButtonGroupsKey];
    
    // get total button groups
    int totalButtonGroups = [buttonGroups count];
    NSMutableArray* buttonGroupsArray = [[NSMutableArray alloc] initWithCapacity:totalButtonGroups];
    
    // get list of buttons for each button group
    for (int groupIndex=0; groupIndex<totalButtonGroups; groupIndex++)
    {
        // get button information from current button group
        NSMutableDictionary* buttonGroup = [buttonGroups objectAtIndex:groupIndex];
        NSArray *buttons = [buttonGroup objectForKey:kProfileButtonsKey];

        // get total buttons in this group
        int totalButtonsInGroup = [buttons count];
        NSMutableArray* buttonArray = [[NSMutableArray alloc] initWithCapacity:totalButtonsInGroup];

        // generate array of button label names for this group
        for (int buttonIndex=0; buttonIndex<totalButtonsInGroup; buttonIndex++)
        {
            // get current button label
            NSMutableDictionary* button = [buttons objectAtIndex:buttonIndex];
            NSString* buttonStr = [button objectForKey:kProfileServiceLabelKey];
            // insert button label text into list
            
            if(buttonStr){
                [buttonArray insertObject:buttonStr atIndex:buttonIndex];
            }
        }
        // store array of button label names for this group
        [buttonGroupsArray insertObject:buttonArray atIndex:groupIndex];
    }

    // store data array of button groups & names from current profile
    _dataArray = buttonGroupsArray;
}


#pragma mark -
#pragma mark UITableViewDataSource Implementation


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // get number of button groups from current profile information
    NSDictionary* p = [MenuCommands get].launchpadProfile;
    NSArray *buttonGroups = [p objectForKey:kProfileButtonGroupsKey];
    
        return [buttonGroups count];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {

    NSArray *buttons = [_dataArray objectAtIndex:indexPath.section] ;
    NSString *button = [buttons objectAtIndex:indexPath.row];
    
    NSString* cellReuseId = button;
    MenuSelectionCell *c = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
   
    if (!c)
    {
        c = [[MenuSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseId];
        c.connectionIsClosed = YES;
    }

    [c setSelectionCommand:button];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return c;
}


- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 51;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 41;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {

    NSArray *buttons = [_dataArray objectAtIndex:section];

    return [buttons count];
}


- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    NSDictionary* p = [MenuCommands get].launchpadProfile;

    // Set up header label for services section
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 295, 51)];
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];

    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [MenuCommands get].menuGroupTextColor;
    headerLabel.center = headerView.center;
    headerLabel.font = [UIFont fontWithName:@"TeXGyreAdventor-Bold" size:18];
    headerLabel.frame = CGRectMake(10, 0, 250, 51);
    headerLabel.textAlignment = UITextAlignmentLeft;
    
    // set button group header from profile profile information
    NSArray *buttonGroups = [p objectForKey:kProfileButtonGroupsKey];
    NSDictionary *buttonGroup = [buttonGroups objectAtIndex:section];
    headerLabel.text = [buttonGroup objectForKey:kProfileButtonLabelKey];

    // get profile skin
    NSMutableDictionary *skin = [p objectForKey:kProfileSkinKey];
    
    // Set up menu section top divider
    NSString* menuTopDividerImagePath = [skin objectForKey:kProfileMenuSectionTopDividerKey];
    UIImage* tDivImage;
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuTopDividerImagePath] path]]]) {
        tDivImage = [UIImage imageWithContentsOfFile:
                     [File getProfileImagePath:[[NSURL URLWithString:menuTopDividerImagePath] path]]];
        
    }else{
        NSURL* menuTopDividerImageURL = [NSURL URLWithString:menuTopDividerImagePath];
        tDivImage  = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuTopDividerImageURL]];
    }
        
    UIImageView* topDivider = [[UIImageView alloc] initWithImage:tDivImage];

    // Set up menu section bottom divider
    NSString* menuBottomDividerImagePath = [skin objectForKey:kProfileMenuSectionBottomDividerKey];
    UIImage* bDivImage;
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:menuBottomDividerImagePath] path]]]){
         bDivImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:menuBottomDividerImagePath] path]]];
    }else{
        NSURL* menuBottomDividerImageURL = [NSURL URLWithString:menuBottomDividerImagePath];
        bDivImage  = [UIImage imageWithData: [NSData dataWithContentsOfURL:menuBottomDividerImageURL]];
    }
    
    UIImageView* bottomDivider = [[UIImageView alloc] initWithImage:bDivImage];
    
    CGRect fr;

    // set up top divider frame
    fr = topDivider.frame;
    fr.origin.y = -2.2;
    topDivider.frame = fr;
    
    // set up bottom divider frame
    fr = bottomDivider.frame;
    fr.origin.y = headerView.frame.size.height-11;
    bottomDivider.frame = fr;

    // create section header view
    [headerView addSubview:topDivider];
    [headerView addSubview:headerLabel];
    [headerView addSubview:bottomDivider];
    return headerView;
}


#pragma mark -
#pragma mark UITableViewDelegate Implementation


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {

    // If the content for this row is closed...
    if ([MenuCommands getNumberOfOpenCommands] >= NUMBER_OF_ALLOWED_COMMANDS) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"To open this service, please close another active service first." message:@"If you would like to run more services at a time, please contact your administrator about obtaining Framehawk Premium" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    //If there are open sessions and the latest one has not finished openGl calls
    //NOTE: This check no longer needed since the kernel will now allow a paused session to receive it's first render to occur before the pause activates
/*    if([MenuCommands getNumberOfOpenCommands] > 0 && !((FHServiceViewController *)[[MenuCommands get] getCurrentSession]).firstAppearCompleted){
        DLog(@"*** First Appear Not Completed!!!");
//        return;
    }
*/
    
    MenuSelectionCell* c = (MenuSelectionCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (c.connectionIsClosed) {
        // ...Open this row's content
        if ( [[MenuCommands get] openApplication:c.command withOption:nil])
        {
            c.selected = YES;
            c.connectionIsClosed = NO;
        }
    }
}


@end