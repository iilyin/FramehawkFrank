//
//  LaunchpadViewController.h
//  Launchpad
//
//  Launchpad view controller
//  Created by Rich Cowie on 5/15/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceScrollView.h"
#import "MenuViewController.h"
#import "ProfileLoginViewController.h"
#import "ProfileSelectionViewController.h"
#import "PINViewController.h"

@interface RootViewController : UIViewController<PINViewRootControllerDelegate, ProfileSelectionViewControllerDelegate, MenuViewControllerDelegate>{
    UIView *backgroundSkinColor;            // background skin color
    UIImageView *backgroundImage;           // background image
    UIImageView *backgroundLogo;            // background logo
    
    BOOL showLoading; 
    BOOL bUserAuthenticatedFailed;          // set if user authentication failed
    BOOL bErrorDownloadingProfiles;
}

@property (strong, nonatomic) UIImage* backgroundImagePng;
@property (readonly, nonatomic) NSInteger currentSessionIndex;
@property (strong, nonatomic) ServiceScrollView *scrollView;
@property (strong, nonatomic) ProfileSelectionViewController* profileSelectionViewController;
@property (strong, nonatomic) MenuViewController *menuViewController;
@property (strong, nonatomic) PINViewController *pinScreen;
@property (strong, nonatomic) ProfileLoginViewController *loginViewController; 
@property (nonatomic) BOOL bDisplayingPINScreen;
@property (nonatomic) BOOL bforceLoginScreen;

-(void) loginUserToStudio:(NSString*)username pass:(NSString*)password;
-(void) removeProfileSelectionFromView;
-(void) showPageControl;
-(void) showPinView: (NSInteger) num;
-(void) removePinView;
-(void) updateMenuViewController;
-(void) removeMenuViewController;
-(void) showLoginView;
-(void) refreshBackground;
-(void) updateBackgroundFrame;
-(void) reloadProfilesList:(BOOL)attemptFileLoad;
@end