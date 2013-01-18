//
//  LoginViewController.m
//  Launchpad
//
//  Verifies user creditials on intial launch of application
//
//  Created by Rich Cowie on 5/23/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "CommandCenter.h"
#import "ProfileLoginViewController.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"


#define LOGIN_DIALOG_WIDTH              520
#define LOGIN_DIALOG_HEIGHT             320
#define LOGIN_DIALOG_VERTICAL_OFFSET    98
#define LOGIN_DIALOG_MARGIN             50
#define LOGIN_TITLE_HEIGHT              30
#define LOGIN_TITLE_FONT_HEIGHT         25
#define LOGIN_TITLE_SPACING             8
#define LOGIN_ENTRY_WIDTH               (LOGIN_DIALOG_WIDTH-LOGIN_DIALOG_MARGIN*2)
#define LOGIN_BUTTON_WIDTH              70
#define LOGIN_BUTTON_HEIGHT             30

// Login Colors & Opacity
#define LOGIN_DIALOG_OPACITY                0.8
#define LOGIN_BACKGROUND_COLOR              [UIColor grayColor]
#define LOGIN_TEXT_COLOR                    [UIColor whiteColor]
#define LOGIN_SUBTITLE_BACKGROUND_COLOR     [UIColor clearColor]
#define LOGIN_TITLE_BACKGROUND_COLOR        [UIColor darkGrayColor]
#define LOGIN_TITLE_COLOR                   [UIColor whiteColor]

typedef enum {
    LoginButtonTag,
    CancelButtonTag,
    UsernameTag,
    PasswordTag
}LoginMenu_Buttons;


@interface ProfileLoginViewController ()

@end

@implementation ProfileLoginViewController

@synthesize loginButton, cancelButton;
@synthesize passwordField;
@synthesize userIdField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Reference geometry
        CGRect bounds = [[UIScreen mainScreen] applicationFrame];

        // Self
        CGFloat x = bounds.size.height/2.0 - LOGIN_DIALOG_WIDTH/2.0;
        CGFloat y = bounds.size.width/2.0 - LOGIN_DIALOG_HEIGHT/2.0 - LOGIN_DIALOG_VERTICAL_OFFSET;
        
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_dialog_bg"]];
        [iv sizeToFit];
        [[iv layer] setOpacity:LOGIN_DIALOG_OPACITY];
        [self.view addSubview:iv];

        CGRect fr = iv.frame;
        fr.origin.x = x;
        fr.origin.y = y;
        self.view.frame = fr;
        

        y = LOGIN_TITLE_HEIGHT;
        // add Launchpad title
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, iv.bounds.size.width, LOGIN_TITLE_HEIGHT)];
            y += (LOGIN_TITLE_HEIGHT+LOGIN_TITLE_SPACING);
            [label setTextAlignment:UITextAlignmentCenter];
            [label setText:@"Welcome to Framehawk"];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextColor:LOGIN_TITLE_COLOR];
            [label setFont:[UIFont systemFontOfSize:LOGIN_TITLE_FONT_HEIGHT]];
            [self.view addSubview:label];
        }


        // add enter user ID title
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_MARGIN, y, LOGIN_ENTRY_WIDTH, LOGIN_TITLE_HEIGHT)];
            y += (LOGIN_TITLE_HEIGHT+LOGIN_TITLE_SPACING);
            [label setTextAlignment:UITextAlignmentLeft];
            [label setText:@"Account:"];
            [label setTextColor:LOGIN_TEXT_COLOR];
            [label setBackgroundColor:[UIColor clearColor]];
            [self.view addSubview:label];
        }


        // add user ID textfield
        {
            userIdField = [[UITextField alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_MARGIN, y, LOGIN_ENTRY_WIDTH, LOGIN_TITLE_HEIGHT)];
            y += (LOGIN_TITLE_HEIGHT+LOGIN_TITLE_SPACING);
            [userIdField setBorderStyle:UITextBorderStyleRoundedRect];
            [userIdField setPlaceholder:@"Enter user ID"];
            // if user email has already been entered then display it
            if (0)
            {
                [userIdField setText:@"your.email@web.com"];    // display email
                [userIdField setEnabled:FALSE];                 // don't allow user to change email
            }
            [userIdField setFont:[UIFont systemFontOfSize:19]];
            [userIdField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [userIdField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            userIdField.tag = UsernameTag;
            [userIdField setDelegate:self];
            [self.view addSubview:userIdField];
        }


        // add enter password title
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_MARGIN, y, LOGIN_ENTRY_WIDTH, LOGIN_TITLE_HEIGHT)];
            y += (LOGIN_TITLE_HEIGHT+LOGIN_TITLE_SPACING);
            [label setTextAlignment:UITextAlignmentLeft];
            [label setText:@"Password:"];
            [label setTextColor:LOGIN_TEXT_COLOR];
            [label setBackgroundColor:LOGIN_SUBTITLE_BACKGROUND_COLOR];
            [self.view addSubview:label];
        }

        // add password textfield
        {
            passwordField = [[UITextField alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_MARGIN, y, LOGIN_ENTRY_WIDTH, LOGIN_TITLE_HEIGHT)];
            [passwordField setBorderStyle:UITextBorderStyleRoundedRect];
            [passwordField setPlaceholder:@"Enter password"];
            [passwordField setSecureTextEntry:YES];
            [passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [passwordField setFont:[UIFont systemFontOfSize:19]];
            [passwordField setDelegate:self];
            passwordField.tag = PasswordTag;
            [self.view addSubview:passwordField];
        }

        // Add login button
        {
            loginButton = [[UIButton alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_WIDTH-LOGIN_DIALOG_MARGIN-LOGIN_TITLE_SPACING-2*LOGIN_BUTTON_WIDTH, 
                                                                     LOGIN_DIALOG_HEIGHT-LOGIN_BUTTON_HEIGHT-LOGIN_DIALOG_MARGIN-1.5*LOGIN_TITLE_SPACING, 
                                                                     LOGIN_BUTTON_WIDTH, 
                                                                     LOGIN_BUTTON_HEIGHT)];
            loginButton.showsTouchWhenHighlighted = YES;
            [loginButton setTitle:@"OK" forState:UIControlStateNormal];
            [loginButton setBackgroundColor:[UIColor colorWithRed:.23 green:.23 blue:.23 alpha:1]];
            [loginButton setTitleColor:[UIColor colorWithRed:0 green:0 blue:.3 alpha:.9] forState:UIControlStateSelected];
                                      
            loginButton.tag = LoginButtonTag;
            [[loginButton layer] setCornerRadius:3.0f];
            [[loginButton layer] setMasksToBounds:YES];
            [[loginButton layer] setBorderWidth:1.0f];

            [self.view addSubview:loginButton];
        }
        
        
        // Add cancel button
        {
            cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(LOGIN_DIALOG_WIDTH-LOGIN_DIALOG_MARGIN-LOGIN_BUTTON_WIDTH, 
                                                                      LOGIN_DIALOG_HEIGHT-LOGIN_BUTTON_HEIGHT-LOGIN_DIALOG_MARGIN-1.5*LOGIN_TITLE_SPACING, 
                                                                      LOGIN_BUTTON_WIDTH, 
                                                                      LOGIN_BUTTON_HEIGHT)];
            cancelButton.showsTouchWhenHighlighted = YES;
            [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
            [cancelButton setBackgroundColor:[UIColor colorWithRed:.23 green:.23 blue:.23 alpha:1]];
            [cancelButton setTitleColor:[UIColor colorWithRed:0 green:0 blue:.3 alpha:.9] forState:UIControlStateSelected];
            
            cancelButton.tag = CancelButtonTag;
            [[cancelButton layer] setCornerRadius:3.0f];
            [[cancelButton layer] setMasksToBounds:YES];
            [[cancelButton layer] setBorderWidth:1.0f];
            [cancelButton addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:cancelButton];
        }


    }
    return self;
}

- (void) cancelClicked 
{
    //Make Sure they login again
    // TODO: confirm we want to use has launched flag - clearing this will clear stored data
    if ([SettingsUtils applicationHasLaunchedPreviously]){
        // clear application has launched previously flag
        [SettingsUtils setApplicationHasLaunchedPreviously:NO];
    }
    
    exit(0); 
}
 
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // hide keyboard when return is pressed on keyboard
    [textField resignFirstResponder];

    if (textField == passwordField)
    {   // on password return on keyboard simulate touched login button
         [loginButton sendActionsForControlEvents: UIControlEventTouchUpInside];         
    }
    return YES;
}


//- (void)textFieldDidEndEditing:(UITextField *)textField {
//    
//    [textField resignFirstResponder];     
//}
//
//
//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    [textField becomeFirstResponder];     
//}
-(void)viewDidAppear:(BOOL)animated{
    [((UITextField *)[self.view viewWithTag:UsernameTag]) setText:nil];
    [((UITextField *)[self.view viewWithTag:PasswordTag]) setText:nil];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // only support landscape orientation
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


@end