//
//  AppDelegate.h
//  Launchpad
//
//  Launchpad App Delegate
//
//  Created by Rich Cowie on 5/15/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "RootViewController.h"
#import "FHServiceViewController.h"

@class EULAViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
	IBOutlet EULAViewController* eulaController;
    
}


+ (UIColor*)colorWithHtmlColor:(NSString*)htmlColor;

@property (strong, nonatomic) IBOutlet EULAViewController* eulaController; 
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RootViewController *viewController;
@property (strong, nonatomic) FHServiceViewController *mainController;

- (IBAction) acceptedEULA:(id)sender;

-(void)resumeActiveConnection;
-(void)saveSession;
-(BOOL)validSession;
-(void)deleteSession;
@end