//
//  StartupController.h
//  Launchpad
//
//  Callback methods upon initial connection in SessionConnection
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StartupControllerDelegate;

@interface FHServiceLaunchDelegate : UIViewController/*TODO:< UIAlertViewDelegate>*/ {
}

@property (nonatomic, weak) UIViewController<StartupControllerDelegate> *delegate;

+ (void)performStartup:(UIViewController<StartupControllerDelegate>*)delegate;

@end

@protocol StartupControllerDelegate
- (void)startupCompleted:(FHServiceLaunchDelegate*)startupController user:(NSString*)user password:(NSString*)password;
- (void)startupFailed:(FHServiceLaunchDelegate*)startupController;
@end
