//
//  PINViewController.m
//  Launchpad
//
//  Created by Ellie Shin on 7/6/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "PINViewController.h"
#import "RootViewController.h"
#import "CommandCenter.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"
@implementation PINViewController
@synthesize delegate, backgroundImg, reset, helpView;

- (id) init {
    self = [super init];
    
    UIImage* bvpng = nil;
    if([self.delegate respondsToSelector:@selector(backgroundImagePng)]){
        bvpng = [(RootViewController*)self.delegate backgroundImagePng];
    }
    
    if(!bvpng){
        bvpng = [UIImage imageNamed:@"launchpad_splash"];
    }
    
    self.backgroundImg = [[UIImageView alloc] initWithImage:bvpng];
    self.backgroundImg.tag = 9999;
    [self.view addSubview:self.backgroundImg];    
    
    PINPadView* pv = [[PINPadView alloc] init];
    CGRect fr = pv.frame;
    fr.origin.x = 512-fr.size.width/2.;
    fr.origin.y = 384-fr.size.height/2.;
    pv.frame = fr; 
    pv.delegate = self;
    pv.reset = self.reset;
    [self.view addSubview:pv];    
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
}

#ifdef POPON
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popcon = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    
    return YES;
}

- (void) closeClicked: (UIControl*) control 
{
    [self.popcon dismissPopoverAnimated:YES];
    self.popcon = nil;   
}
#endif

- (void) didClickHelp:(PINPadView *)pinView {
    
#ifdef POPON
    // popover 
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:self]; 
    popover.delegate = self;
    self.popcon = popover;
    
    UIViewController* vc = [[UIViewController alloc] init];
    vc.view.frame = CGRectMake(0, 0, 300, 200);
    vc.view.backgroundColor = [UIColor whiteColor];    
    
    UILabel* helpTitle = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,40)]; 
    helpTitle.text = @"   Framehawk Canvas PIN";
    helpTitle.font = [UIFont boldSystemFontOfSize:24];
    //    helpTitle.textAlignment = UITextAlignmentCenter;
    helpTitle.textColor = [UIColor whiteColor];
    helpTitle.backgroundColor = [UIColor colorWithWhite:.2 alpha:.9];
    helpTitle.font = [UIFont fontWithName:@"TeXGyreAdventor-Bold" size:18];
    UIButton* close = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    close.frame = CGRectMake(250, 5, 50, 30);
    [close addTarget:self action:@selector(closeClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* helpTxt1 = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, 5, 280, 180)];
    helpTxt1.lineBreakMode = UILineBreakModeWordWrap;
    helpTxt1.numberOfLines = 0;
    helpTxt1.backgroundColor = [UIColor clearColor];
    helpTxt1.font = [UIFont fontWithName:@"TeXGyreAdventor-Regular" size:16];
    helpTxt1.text = @"Set up or enter a pin to access Framehawk Canvas";
    
    [vc.view addSubview:helpTitle];
    [vc.view addSubview:close]; 
    [vc.view addSubview:helpTxt1];
    
    popover.contentViewController = vc;
    popover.popoverContentSize = vc.view.frame.size;
    
    CGRect f = CGRectMake(350, 500, 50, 50);
    [popover presentPopoverFromRect:f
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionRight 
                           animated:YES];
#else
    
    if(!self.helpView){
        UIView* v = [[UIView alloc] initWithFrame:CGRectMake(80, 370, 300, 170)];
        v.backgroundColor = [UIColor colorWithWhite:0.8 alpha:.9];

        UILabel* helpTitle = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,40)]; 
        helpTitle.text = @"   Framehawk Canvas PIN";
        helpTitle.font = [UIFont boldSystemFontOfSize:24];
        //    helpTitle.textAlignment = UITextAlignmentCenter;
        helpTitle.textColor = [UIColor whiteColor];
        helpTitle.backgroundColor = [UIColor colorWithWhite:.2 alpha:.9];
        helpTitle.font = [UIFont fontWithName:@"TeXGyreAdventor-Bold" size:18];
        UIButton* close = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [close setTitle:@"Close" forState:UIControlStateNormal];
        close.frame = CGRectMake(240, 5, 50, 30);
        [close addTarget:self action:@selector(closeHelp:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel* helpTxt1 = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, 5, 280, 150)];
        helpTxt1.lineBreakMode = UILineBreakModeWordWrap;
        helpTxt1.numberOfLines = 0;
        helpTxt1.backgroundColor = [UIColor clearColor];
        helpTxt1.font = [UIFont fontWithName:@"TeXGyreAdventor-Regular" size:16];
        helpTxt1.text = @"Set up or enter a PIN to access Framehawk Canvas"; 
        
        [v addSubview:helpTitle];
        [v addSubview:close]; 
        [v addSubview:helpTxt1];
        self.helpView = v;
        [self.view addSubview:v];    
    }
    else {
        [self.helpView removeFromSuperview];
        self.helpView = nil;
    }
    
#endif
    
}

- (void) closeHelp:(UIButton*) control {
    [self.helpView removeFromSuperview];
    self.helpView = nil;
}

- (void) didCancelPin:(PINPadView *)pinView {
    if([self.delegate respondsToSelector:@selector(shouldDismissPinView:)]) 
    {
        [pinView removeFromSuperview];
        [self.backgroundImg removeFromSuperview];
        
        [self.view setNeedsLayout];
        
        [self.delegate shouldDismissPinView:self];
        
    }
}


- (void) didEnterPin:(PINPadView*) pinView {

    // see if we want to dismiss the PIN view after PIN entered
    if([self.delegate respondsToSelector:@selector(shouldDismissPinView:)])
    {
        // save PIN
        [SettingsUtils saveCurrentUserPIN:pinView.pinstr];
        
        // remove PIN entry view
        [pinView removeFromSuperview];
        [self.backgroundImg removeFromSuperview];
        
        [self.view setNeedsLayout];
        
        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        // Need here for when user changes goes to background and comes back
        if (username) {
            [[CommandCenter get] loadSavedProfiles:username];
            [[CommandCenter get] loadSavedProfileList:username];
        }
        
        [self.delegate shouldDismissPinView:self];
    }
}

- (void) dealloc {
    self.delegate = nil;
}

@end
