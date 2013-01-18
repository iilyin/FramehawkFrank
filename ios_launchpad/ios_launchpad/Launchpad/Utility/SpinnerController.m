//
//  SpinnerViewController.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/22/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SpinnerController.h"
#import "ImageAnimatorViewController.h"
#import "MenuCommands.h"
#import <QuartzCore/QuartzCore.h>
@interface SpinnerController ()
@property (nonatomic) ImageAnimatorViewController *imageAnimViewController;
@end
#define SpinnerViewTag 1
#define ButtonLabel 2
#define PageViewTag 3

@implementation SpinnerController
@synthesize imageAnimViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setCommand:(NSString *)command{
    [(UIButton *)[self.view viewWithTag:ButtonLabel] setTitle:command forState:UIControlStateNormal];
    CGRect frame = [self.view viewWithTag:ButtonLabel].frame;
    CGPoint center = [self.view viewWithTag:ButtonLabel].center;
    
    if ([command length]>10) {
            frame.size.width = [command length] * 12;
    }else {
            frame.size.width = [command length] * 14;
    }

    [self.view viewWithTag:ButtonLabel].frame = frame;
    [self.view viewWithTag:ButtonLabel].center = center;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //SET UP BUTTON
    [[[self.view viewWithTag:ButtonLabel] layer] setCornerRadius:8.0f];
    [[[self.view viewWithTag:ButtonLabel] layer] setMasksToBounds:YES];
    [[[self.view viewWithTag:ButtonLabel] layer] setBorderWidth:1.0f];
    [((UIButton *)[self.view viewWithTag:ButtonLabel]) setUserInteractionEnabled:NO];
    
    
    [((UIPageControl *)[self.view viewWithTag:PageViewTag]) setNumberOfPages:[MenuCommands getNumberOfOpenCommands]];
    [((UIPageControl *)[self.view viewWithTag:PageViewTag]) setCurrentPage:2];
    [[[self.view viewWithTag:PageViewTag] layer] setCornerRadius:8.0f];
    [[[self.view viewWithTag:PageViewTag] layer] setMasksToBounds:YES];
    [[[self.view viewWithTag:PageViewTag] layer] setBorderWidth:1.0f];
    
    self.imageAnimViewController = [ImageAnimatorViewController imageAnimatorViewController];
    
    NSString *seqPattern = @"bubblesSpinnyBlue64_";
    
    NSArray *names = [ImageAnimatorViewController arrayWithNumberedNames:seqPattern
                                                              rangeStart:1
                                                                rangeEnd:8
                                                            suffixFormat:@"%i.png"];
    
    NSArray *URLs = [ImageAnimatorViewController arrayWithResourcePrefixedURLs:names];
    
    imageAnimViewController.animationFrameDuration = ImageAnimator15FPS;
    imageAnimViewController.animationURLs = URLs;
    imageAnimViewController.animationRepeatCount = 5000;
    
    imageAnimViewController.superFrame = CGRectMake(0, 0, 64, 64);
    
    [[self.view viewWithTag:SpinnerViewTag] addSubview:imageAnimViewController.view];
    
    [imageAnimViewController startAnimating];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [imageAnimViewController stopAnimating];
    UIView *v;
    v = [self.view viewWithTag:SpinnerViewTag];
    v = nil;
    v = [self.view viewWithTag:ButtonLabel];
    v = nil;
    v = [self.view viewWithTag:PageViewTag];
    v = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
