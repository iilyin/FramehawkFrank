//
//  BlinkingButton.m
//  Launchpad
//
//  Created on 09.05.12.
//  Copyright (c) 2012 Framehawk. All rights reserved.
//

#import "BlinkingButton.h"
#import <QuartzCore/QuartzCore.h>

@interface BlinkingButton()

@property (nonatomic, strong) UIColor *colorForControlStateNormal;
@property (nonatomic, strong) UIColor *colorForControlStateHighlighted;
@property (nonatomic, strong) UIColor *colorForControlStateDisabled;

@end

@implementation BlinkingButton

@synthesize colorForControlStateNormal, colorForControlStateHighlighted, colorForControlStateDisabled;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        colorForControlStateNormal = [UIColor colorWithWhite:1.0
                                                       alpha:1.0];
        colorForControlStateHighlighted = [UIColor blueColor];
        colorForControlStateDisabled = [UIColor redColor];
        
        if(self.enabled)[self.layer setBackgroundColor:[colorForControlStateNormal CGColor]];
        else [self.layer setBackgroundColor:[colorForControlStateDisabled CGColor]];
        [self.layer setBorderColor:[[UIColor colorWithWhite:0.0
                                                     alpha:1.0] CGColor]];
        [self.layer setBorderWidth:1.0];
        [self setTitleColor:[UIColor colorWithWhite:0.15
                                              alpha:1.0]
                   forState:UIControlStateNormal];
        
        [self addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"highlighted"] && self.enabled)
    {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue]) 
        {
            [self.layer setBackgroundColor:[colorForControlStateHighlighted CGColor]];
        }
        else [self.layer setBackgroundColor:[colorForControlStateNormal CGColor]];
    }
    
    else if([keyPath isEqualToString:@"enabled"])
    {
        if (![[change objectForKey:NSKeyValueChangeNewKey] boolValue]) 
        {
            [self.layer setBackgroundColor:[colorForControlStateDisabled CGColor]];
        }
    }
}

- (void)setColor:(UIColor *)color forControlState:(UIControlState)controlState
{
    switch (controlState)
    {
        case UIControlStateNormal:
        {
            self.colorForControlStateNormal = color;
            if(self.state == UIControlStateNormal && self.enabled) 
                [self.layer setBackgroundColor:[colorForControlStateNormal CGColor]];
            break;
        }
            
            
        case UIControlStateHighlighted:
        {
            self.colorForControlStateHighlighted = color;
            break;
        }
            
        case UIControlStateDisabled:
        {
            self.colorForControlStateDisabled = color;
            break;
        }
            
        default:
            break;
    }
}

- (void) setColorForBorders:(UIColor *)color
{
    [self.layer setBorderColor:[color CGColor]];
}

- (void) setRoundedCornersWithRadius: (float) radius
{
    [self.layer setCornerRadius:radius];
    [self.layer setMasksToBounds:YES];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:@"highlighted"];
    [self removeObserver:self forKeyPath:@"enabled"];
}

@end
