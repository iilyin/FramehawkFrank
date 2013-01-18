/*
 *  ProfileSelectionViewController.h
 *  Framehawk Launchpad
 *
 *  Profile Selection controller used for selecting profile on initial launch
 *  or changing profile from settings.
 *
 *  Created by Eric Johnson on 6/4/12.
 *  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
 */


#import <UIKit/UIKit.h>

// Mode that profile selection is called from
typedef enum {
    // initial profile chooser seen in the root view controller
    kProfileSelectionInitialSelectionMode   = 0,
    // from menu profiles icon click
    kProfileSelectionFromMenuProfilesMode   = 1,
} ProfileSelection_Mode;


@class RootViewController;
@protocol ProfileSelectionViewControllerDelegate;


@interface ProfileSelectionViewController : UIViewController
 <UITableViewDataSource,
  UITableViewDelegate, UITabBarDelegate>

@property (strong, nonatomic) id<ProfileSelectionViewControllerDelegate> delegate;
@property  (assign) NSInteger mode; 

- (id) initWithFrame:(CGRect) frame withMode: (NSInteger) aMode;
-(void)clearTable;
@end



@protocol ProfileSelectionViewControllerDelegate <NSObject>

- (void) didSelectProfile: (id) profile fromController:(ProfileSelectionViewController*) control; 
- (void) didCancelProfileSelection:(ProfileSelectionViewController *)control;
- (void) showLoadingSpinner;
@end