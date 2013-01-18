//
//  BlinkingButton.h
//  Launchpad
//
//  Created on 09.05.12.
//  Copyright (c) 2012 Framehawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlinkingButton : UIButton
{
    UIColor *colorForControlStateNormal;
    UIColor *colorForControlStateHighlighted;
    UIColor *colorForControlStateDisabled;
}

- (void) setColor: (UIColor *) color forControlState: (UIControlState) controlState;
- (void) setRoundedCornersWithRadius: (float) radius;
- (void) setColorForBorders: (UIColor *) color;

@end
