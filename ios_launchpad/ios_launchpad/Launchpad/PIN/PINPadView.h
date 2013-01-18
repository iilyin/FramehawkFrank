//
//  PINView.h
//  Launchpad
//
//  Created by Ellie Shin on 7/6/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol PINViewControllerDelegate;

@interface PINPadView : UIView
{
    NSArray* pin;
    UILabel* viewTitle;
    int enterCount;
    UIButton* cancel;
    UIImageView* errorView;
}

@property (assign) BOOL reset; 
@property (nonatomic, strong) NSString* pinstr;
@property (nonatomic, strong) id<PINViewControllerDelegate> delegate; 

@end

@protocol PINViewControllerDelegate <NSObject>
@required
- (void) didEnterPin:(PINPadView*) pinView;
- (void) didCancelPin:(PINPadView*) pinView;
- (void) didClickHelp:(PINPadView*) pinView;
@end
