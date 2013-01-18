//
//  PINViewController.m
//  Launchpad
//
//  Created by Ellie Shin on 7/6/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "PINViewController.h"
#import "PINPadView.h"

@protocol PINViewRootControllerDelegate;

@interface PINViewController : UIViewController <PINViewControllerDelegate>//, UIPopoverControllerDelegate>
{
}

@property (nonatomic, strong) UIImageView* backgroundImg;
@property (nonatomic, strong) UIView* helpView; 
@property (assign) BOOL reset; 
@property (nonatomic, strong) id<PINViewRootControllerDelegate> delegate; 
@end


@protocol PINViewRootControllerDelegate <NSObject>
@required
-(void) shouldDismissPinView: (PINViewController*) control;
@end
