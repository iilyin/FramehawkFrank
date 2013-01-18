//
//  MenuViewController.h
//  Framehawk
//
//  Created by Hursh Prasad on 4/16/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "LaunchPadMenuTable.h"
#import "MenuDataSource.h"
#import "ProfileSettingsViewController.h"

@protocol MenuViewControllerDelegate;
@interface MenuViewController : UIViewController <UIPopoverControllerDelegate, ProfileSettingsViewControllerDelegate>

// Menu layout
#define MARGIN                      20
#define MENU_TAB_Y_OFFSET           68

@property (nonatomic, strong) UIImageView* backgroundPanel;
@property (nonatomic, strong) UIImageView* backgroundColorLayer;
@property (nonatomic, strong) UIButton *menuTab;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) LaunchPadMenuTable *menuTable;
@property (nonatomic, strong) UIPopoverController *popcon;
@property (nonatomic, strong) id<MenuViewControllerDelegate> delegate;

-(void)closeClicked: (UIControl*) control;
-(void)closeMenu;
-(void)openMenu;
-(void)openCloseMenu;
-(void)profilesTapped;
-(void)dismissProfileSettings;
-(void)removeProfileSelection;
-(void)enableLoginAssistantButton;
-(void)disableLoginAssistantButton;
/**
 * Show Alert advising user that Login Assistant is disabled for this service
 */
+ (void)showLoginAssistantDisabledAlert;
/**
 * Dismiss any Login Assistant disabled alert
 */
+ (void)dismissLoginAssistantDisabledAlert;
/**
 * Set frame size
 */
-(void)updateFrame;
/**
 * Display status bar if settings are currently active
 */
- (void) displayStatusBarIfSettingsActive;
/**
 * Set login assistant button status
 * Disables login assistant button if no sessions are open
 */
- (void)setLoginAssistantButtonStatus;

@end


@protocol MenuViewControllerDelegate <NSObject>
@optional
- (void) didSelectPinResetFromSettings;
@end