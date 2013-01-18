//
//  ProfileSettingsViewController.h
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

#import <UIKit/UIKit.h>

@protocol ProfileSettingsViewControllerDelegate;

@interface ProfileSettingsViewController : UITableViewController

@property (nonatomic, strong) id<ProfileSettingsViewControllerDelegate> delegate;

@end

@protocol ProfileSettingsViewControllerDelegate <NSObject>
- (void) didSelectPinResetFromSettings;
@end