//
//  EULAViewController.h
//  Launchpad
//
//  Created by Rich Cowie on 8/31/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppDelegate;

@interface EULAViewController : UIViewController  {

    AppDelegate* appDelegate;
    
}

@property (strong, nonatomic) AppDelegate* appDelegate;

- (IBAction) okButtonClicked:(id)sender;

@end
