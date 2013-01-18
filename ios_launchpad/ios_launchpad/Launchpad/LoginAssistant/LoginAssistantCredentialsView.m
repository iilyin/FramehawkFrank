//
//  LoginAssistantCredentialsView.m
//  Launchpad
//
//  View for entering Login Assistant Credentials
//
//  Created by Rich Cowie on 10/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginAssistantCredentialsView.h"
#import "GlobalDefines.h"
#import "MenuCommands.h"
#import "SettingsUtils.h"
#import "ProfileDefines.h"

// User credentials table layout information
static const double kTitleFontSize                          = 18.0;
static const double kDoNotShowAgainTextFontSize             = 14.0;
static const double kDoNotShowAgainCheckHeight              = 20.0;
static const double kDoNotShowAgainCheckSpacing             = 5.0;

static const double kInstructionsFontSize                   = 16.0;
static const double kInstructionsRegionHeight               = 75.0;
static const double kInstructionsTitleVerticalMargin        = 25.0;

static const double kDefaultIndentation                     = 40.0;
static const double kDefaultPadding                         = 10.0f;
static const double kDefaultFontSize                        = 16.0f;

static const double kDefaultButtonWidth                     = 100.0f;
static const double kDefaultButtonHeight                    = 30.0f;
static const double kDefaultButtonYPos                      = 230.0f;
static const double kDefaultButtonRoundedCornerRadius       = 8.0f;

static const double kCredentialsTextfieldXOffset            = 120.0f;
static const double kCredentialsTextfieldYOffset            = 5.0f;
static const double kCredentialsTextfieldWidth              = 250.0f;
static const double kCredentialsTextfieldHeight             = 30.0f;

static const double kDefaultTableWidth                      = 440.0f;
static const double kDefaultTableHeight                     = 40.0f;
static const double kDefaultCredentialsTableHeight          = 100.0f;

static const double kUserCredentialsRowWidth                = 180.0f;
static const double kUserCredentialsRowHeight               = 25.0f;
static const double kUserCredentialsTextHeight              = 22.0f;
static const double kUserCredentialsTableRowHeight          = 35.0f;
static const double kSpacingBetweenCredentialsAndButtons    = 5.0f;

static const int    kNumberOfSectionsInUserCredentialsTable = 1;

// Colors for Login Assistant Credentials
#define LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR        [UIColor clearColor]
#define LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR              [UIColor whiteColor]


// Indices for user credential table cells
typedef enum
{
    kCellName = 0,
    kCellPassword,
    kNumberOfRowsInUserCredentialsTable
}
kCellNumber;

// Tags for Login Assistant UI elements
typedef enum {
    kDoNotShowAgainButtonTag       = 9090,
}LoginAssistantAlertDialogs;


// login assistant strings
static NSString *const sSetupLoginAssistantTitle            = @"Setup Login Assistant for %@";
static NSString *const sUserCredentialsInstructions         = @"Before logging in for the first time, please enter your User Id and (optional) Password.";
static NSString *const sCredentialsUserNameTitle            = @"User name:";
static NSString *const sCredentialsEnterUserName            = @"Enter user name";
static NSString *const sCredentialsPasswordTitle            = @"Password:";
static NSString *const sCredentialsEnterPassword            = @"Enter password";
static NSString *const sCredentialsSubmitButtonText         = @"OK";
static NSString *const sCredentialsCancelButtonText         = @"No Thanks";
static NSString *const sCredentialsInvalid                  = @"Invalid Credentials!";
static NSString *const sCredentialsEnterUserNamePassword    = @"Please Enter User Name";
static NSString *const sCredentiaDoNotShowThisAgain         = @"Do not show this again";
static NSString *const sCredentiaDoNotShowThisAgainChecked  = @"X";

static NSString *const sCredentialsInvalidDialogOKButtonText= @"Ok";


@implementation LoginAssistantCredentialsView

@synthesize delegate;
@synthesize colorForBackground;
@synthesize instructionLabel;
@synthesize tableForCredentials;
@synthesize textFieldForName;
@synthesize textFieldForPassword;
@synthesize doNotShowCheck;
@synthesize OKButton;
@synthesize cancelButton;


/**
 * Initialize Login Assistant Credentials View
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code

        // Set background color for login assistant dialog to clear
        self.backgroundColor = LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR;
        // Set background image for login assistant dialog
        backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_dialog_bg"]];
        [backgroundView sizeToFit];
        // add login assistant dialog background to view
        [self addSubview:backgroundView];
        
        // set frame size to background image
        self.frame = backgroundView.bounds;

        // set y start position to default indentation
        CGFloat y = kDefaultIndentation;

        // Set up instructions title
        title = [[UILabel alloc] initWithFrame:CGRectMake(kDefaultIndentation, kInstructionsTitleVerticalMargin, kDefaultTableWidth, kDefaultTableHeight)];
        [title setTextAlignment:UITextAlignmentCenter];
        [title setTextColor:LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR];
        [self setupTitleForCurrentSession];
        title.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
        title.backgroundColor = LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR;
        [self addSubview:title];

        // Set up instructions label
        y+= title.bounds.size.height + kDefaultPadding;
        instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDefaultIndentation, kInstructionsRegionHeight, kDefaultTableWidth, kDefaultTableHeight)];
        [instructionLabel setText:sUserCredentialsInstructions];
        [instructionLabel setNumberOfLines:0];
        instructionLabel.font = [UIFont systemFontOfSize:kInstructionsFontSize];
        [instructionLabel setLineBreakMode:UILineBreakModeWordWrap];
        [instructionLabel setTextColor:LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR];
        [instructionLabel setBackgroundColor:LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR];
        [instructionLabel setTextAlignment:UITextAlignmentCenter];
        [self addSubview:instructionLabel];
        
        y+= self.instructionLabel.bounds.size.height;
        
        // Set up table for credentials
        tableForCredentials = [[UITableView alloc] initWithFrame:CGRectMake(kDefaultIndentation, 95, kDefaultTableWidth, kDefaultCredentialsTableHeight)
            style:UITableViewStyleGrouped];
        [tableForCredentials setScrollEnabled:NO];
        [tableForCredentials setBackgroundColor:LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR];
        [tableForCredentials setBackgroundView:nil];
        [tableForCredentials setDelegate:(id<UITableViewDelegate>)self];
        [tableForCredentials setDataSource:(id<UITableViewDataSource>)self];
        [self addSubview:tableForCredentials];
        
        // Set up textField for name
        textFieldForName = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, kUserCredentialsRowWidth, kUserCredentialsTextHeight)];
        textFieldForName.placeholder = sCredentialsEnterUserName;
        textFieldForName.textColor = LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR;
        textFieldForName.delegate = (id<UITextFieldDelegate>)self;
        textFieldForName.autocorrectionType = UITextAutocorrectionTypeNo;
        textFieldForName.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        // Set up textField for password
        textFieldForPassword = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, kUserCredentialsRowWidth, kUserCredentialsTextHeight)];
        textFieldForPassword.placeholder = sCredentialsEnterPassword;
        textFieldForPassword.textColor = LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR;
        textFieldForPassword.delegate = (id<UITextFieldDelegate>)self;
        textFieldForPassword.autocorrectionType = UITextAutocorrectionTypeNo;
        textFieldForPassword.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textFieldForPassword.secureTextEntry = YES; // password is secure entry
        
        // set y position to bottom of credentials
        y+= self.tableForCredentials.bounds.size.height;

        double xOK = (self.frame.size.width - (kDefaultButtonWidth * 2 + kDefaultPadding)) / 2.0;
        double xCancel = xOK + kDefaultButtonWidth + kDefaultPadding;

        // Set up check box for "Do not show again"
        doNotShowCheck = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        doNotShowCheck.frame = CGRectMake(xOK, 205, kDoNotShowAgainCheckHeight, kDoNotShowAgainCheckHeight);
        doNotShowCheck.tag = kDoNotShowAgainButtonTag;
        // clear check (unselected)
        doNotShowCheck.titleLabel.textAlignment = UITextAlignmentCenter;
        // add call when do not show again checkbox is touched
        [doNotShowCheck addTarget:self action:@selector(doNotShowAgainClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        // Set up text for "Do not show again"
        UILabel* doNotShowText = [[UILabel alloc] initWithFrame:CGRectMake(xOK + doNotShowCheck.frame.size.width + kDoNotShowAgainCheckSpacing, 205, 200, kDoNotShowAgainCheckHeight)];
        doNotShowText.text = sCredentiaDoNotShowThisAgain;
        doNotShowText.font = [UIFont systemFontOfSize:kDoNotShowAgainTextFontSize];
        doNotShowText.backgroundColor = LOGIN_ASSISTANT_CREDENTIALS_BACKGROUND_COLOR;
        doNotShowText.textColor = LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR;

        // Add 'Do Not Show This Again' check box and text
        [self addSubview:doNotShowCheck];
        [self addSubview:doNotShowText];

        // adjust y position for credentials row
        //y+= kUserCredentialsRowHeight;

        // adjust y position for spacing between credentials
        //y+= kSpacingBetweenCredentialsAndButtons;

        // Set up OK button
        OKButton = [BlinkingButton buttonWithType:UIButtonTypeCustom];
        [OKButton setTitle:sCredentialsSubmitButtonText
                  forState:UIControlStateNormal];
        [OKButton setTitleColor:LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR
                       forState:UIControlStateNormal];
        [OKButton setFrame:CGRectMake(xOK, kDefaultButtonYPos, kDefaultButtonWidth, kDefaultButtonHeight)];
        [OKButton addTarget:self action:@selector(OKButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [OKButton setRoundedCornersWithRadius:kDefaultButtonRoundedCornerRadius];
        [OKButton setColor:[UIColor colorWithWhite:.1 alpha:.8] forControlState:UIControlStateNormal];
        [OKButton setColor:self.colorForBackground forControlState:UIControlStateHighlighted];
        [OKButton setColorForBorders:[UIColor colorWithWhite:0.3f alpha:.6]];
        [self addSubview:OKButton];
        
        // Set up cancel button
        cancelButton = [BlinkingButton buttonWithType:UIButtonTypeCustom];
        [cancelButton setTitle:sCredentialsCancelButtonText
                      forState:UIControlStateNormal];
        [cancelButton setTitleColor:LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR
                           forState:UIControlStateNormal];
        
        [cancelButton setFrame:CGRectMake(xCancel, kDefaultButtonYPos, kDefaultButtonWidth, kDefaultButtonHeight)];
        [cancelButton addTarget:self action:@selector(CancelButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setRoundedCornersWithRadius:kDefaultButtonRoundedCornerRadius];
        [cancelButton setColor:[UIColor colorWithWhite:.1 alpha:.8] forControlState:UIControlStateNormal];
        [cancelButton setColor:self.colorForBackground forControlState:UIControlStateHighlighted];
        [cancelButton setColorForBorders:[UIColor colorWithWhite:0.3f alpha:.6]];
        [self addSubview:cancelButton];

    }

    return self;
}


/**
 * Set the title for the current session
 */
- (void) setupTitleForCurrentSession
{
    NSString* appName = [[[MenuCommands get] selectedCommand] objectForKey:kProfileServiceLabelKey];
    [title setText: [NSString stringWithFormat:sSetupLoginAssistantTitle, appName]];
}


/**
 * Submit Login Credentials
 *
 * Checks for username and (optional) password entered in login assistant credentials
 * and saves them if there is at least a non-zero username
 * otherwise displays alert asking for username to be entered
 */
-(void) submitLoginCredentials
{
    allowResign = YES;

    // get profile username, profile id & application name (used to store login assistant settings)
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    NSString* aName = [[[MenuCommands get] selectedCommand] objectForKey:kProfileServiceLabelKey];

    // get username & password from textfields
    NSString* txtUser = textFieldForName.text;
    NSString* txtPwd = textFieldForPassword.text;

    // if user has entered a non-zero name then store it
    if(txtUser && (txtUser.length > 0)) {
        // save login assistant username
        [SettingsUtils saveLoginAssistantUsernameSetting:txtUser userId:profileUserId profileId:pid appName:aName];
        
        // set login assistant to enabled since a non-zero name has now been stored
        [SettingsUtils saveLoginAssistantEnabledSetting:TRUE userId:profileUserId profileId:pid appName:aName];
        
        // if user has entered a non-zero password then store it
        if(txtPwd && (txtPwd.length > 0)) {
            [SettingsUtils saveLoginAssistantPasswordSetting:txtPwd userId:profileUserId profileId:pid appName:aName];
        }
        
        // send OK button pressed
        [delegate performSelector:@selector(OKButtonPressedForView:) withObject:self];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:sCredentialsInvalid message:sCredentialsEnterUserNamePassword delegate:nil cancelButtonTitle:sCredentialsInvalidDialogOKButtonText otherButtonTitles:nil, nil];
        [alert show];
    }
}


/**
 * OK button touched on Login Assistant Credentials dialog
 *
 * Handles OK button being pressed on credentials dialog,
 * submitting the login credentials
 */
- (IBAction) OKButtonTouched:(id)sender
{
    [self submitLoginCredentials];
}

/**
 * Check if do not show again check box is selected
 * Returns TRUE
 */
- (BOOL) isDoNotShowAgainEnabled
{
    // if doNotShowCheck dialog has a non-zero title (check mark 'X') then it is selected
    return (doNotShowCheck.currentTitle.length > 0);
}


/**
 * Do not show again check box clicked
 * Toggle x selection on check box
 */
- (void) doNotShowAgainClicked: (UIButton*) control
{
    // If checkbox title length is non-zero (currently selected)
    if ([self isDoNotShowAgainEnabled]) {
        // clear check (unselected)
        [doNotShowCheck setTitle:@"" forState:UIControlStateNormal];
    }
    else {
        // set check title (selected)
        [doNotShowCheck setTitle:sCredentiaDoNotShowThisAgainChecked forState:UIControlStateNormal];
    }
}


/**
 * Check for disable Login Assistant based on 'Do not show this again' checkbox
 */
- (void)checkDisableLoginAssistant
{
    // if do not show again check...
    if ([self isDoNotShowAgainEnabled])
    {
        // get profile username, profile id & application name (used to store login assistant settings)
        NSString* profileUserId = [SettingsUtils getCurrentUserID];
        NSDictionary* pInfo = [[[MenuCommands get] launchpadProfile] objectForKey:kProfileInfoKey];
        NSString* pid = [pInfo objectForKey:kProfileIdKey];
        NSString* aName = [[[MenuCommands get] selectedCommand] objectForKey:kProfileServiceLabelKey];
        
        // ...then turn off login assistant for this service
        [SettingsUtils saveLoginAssistantEnabledSetting:FALSE userId:profileUserId profileId:pid appName:aName];
    }
}


/**
 * Cancel button touched on Login Assistant dialog
 */
- (IBAction) CancelButtonTouched:(id)sender
{
    allowResign = YES;
    
    UIButton* b = (UIButton*)[self viewWithTag:kDoNotShowAgainButtonTag];
    BOOL hideLoginView =  (b.titleLabel.text.length > 0);
    
    // if delegate responds to cancel button then call method to cancel
    if([delegate respondsToSelector:@selector(CancelButtonPressedForView:withOption:)]){
        [delegate CancelButtonPressedForView:self withOption:hideLoginView];
    }
    
    // check if login assistant disabled
    [self checkDisableLoginAssistant];
}

/**
 * Handle return entered on keyboard while entering
 * user credentials text field - username or password
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // if return pressed when focus is on username textfield
    if (textField==textFieldForName)
    {
        // set focus on password field
        [textFieldForPassword becomeFirstResponder];
    }
    else if (textField==textFieldForPassword)
    {   // if return pressed when focus is on password textfield

        // dismiss keyboard
        [textField resignFirstResponder];

        // attempt to submit credentials
        [self submitLoginCredentials];
    }
    
    return NO;
}


#pragma mark UITableViewDelegate methods
/**
 * Did select table view row at index path
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

#pragma mark UITableViewDataSource methods
/**
 * Return number of rows in user credentials table section
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfRowsInUserCredentialsTable;
}

/**
 * Return number of sections in user credentials table section
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSectionsInUserCredentialsTable;
}

/**
 * Return height of sections in user credentials table row
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kUserCredentialsTableRowHeight;
}


/**
 * Get cell for table view
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellForCredentials = @"CredentialsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellForCredentials];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellForCredentials];
    }
    
    // set cell style & background color
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:self.backgroundColor];
    
    switch ([indexPath row])
    {
        case kCellName:
        {   // set up credentials user name cell
            cell.textLabel.text = sCredentialsUserNameTitle;
            cell.textLabel.textColor = LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR;
            self.textFieldForName.frame = CGRectMake(
                kCredentialsTextfieldXOffset,kCredentialsTextfieldYOffset,
                kCredentialsTextfieldWidth,kCredentialsTextfieldHeight);
            self.textFieldForName.text = @"";
            [cell.contentView addSubview:self.textFieldForName];
            break;
        }
            
        case kCellPassword:
        {   // set up credentials password cell
            cell.textLabel.text = sCredentialsPasswordTitle;
            [cell.textLabel sizeToFit];
            cell.textLabel.textColor = LOGIN_ASSISTANT_CREDENTIALS_TEXT_COLOR;
            self.textFieldForPassword.frame = CGRectMake(
                kCredentialsTextfieldXOffset,kCredentialsTextfieldYOffset,
                kCredentialsTextfieldWidth,kCredentialsTextfieldHeight);
            self.textFieldForPassword.text = @"";
            [cell.contentView addSubview:self.textFieldForPassword];
        }
            
        default:
            break;
    }
    
    return cell;
    
}

@end
