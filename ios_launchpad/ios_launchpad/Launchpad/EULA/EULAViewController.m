//
//  EULAViewController.m
//  Launchpad
//
//  Created by Rich Cowie on 8/31/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "EULAViewController.h"
#import "AppDelegate.h"

@implementation EULAViewController

@synthesize appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}


- (IBAction) okButtonClicked:(id)sender
{
    // dismiss EULA
	[appDelegate acceptedEULA:sender];
}

@end
