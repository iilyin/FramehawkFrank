//
//  StartupController.m
//  Launchpad
//
//  Callback methods upon initial connection in SessionConnection
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import "FHServiceLaunchDelegate.h"
#import "UIUtils.h"

@interface FHServiceLaunchDelegate(PrivateMethods)

- (void)showStartupFailureMessage:(NSString*)message delegate:(id)alertDelegate;

@end

@implementation FHServiceLaunchDelegate

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    DLog(@"didReceiveMemoryWarning **** FHServiceLaunchDelegate\n");
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [UIUtils isOrientationAllowed:interfaceOrientation];
}

+ (void)performStartup:(UIViewController<StartupControllerDelegate>*)delegate
{
    [delegate startupCompleted:nil user:@"user" password:@"pass"];
}

@end
