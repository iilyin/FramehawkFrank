//
//  FunctionKeysViewController.m
//  Launchpad
//
//  Created by Rich Cowie on 6/13/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "FunctionKeysController.h"
#import "CustomKeyButton.h"
#import "UIUtils.h"
#import "FHDefines.h"

#define FUNCTION_KEY_BUTTON_WIDTH           20
#define FUNCTION_KEY_BUTTON_HEIGHT          25
#define FUNCTION_KEY_SPACING                8

#define TOTAL_FUNCTION_KEYS                 12


@interface FunctionKeysController ()

@end

@implementation FunctionKeysController

@synthesize toolbar;
@synthesize functionKeys;
@synthesize functionKeyDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view = [self createFunctionsKeysToolbarView];
        self.view.frame = CGRectMake(0, 0,FUNCTION_KEY_BUTTON_WIDTH * TOTAL_FUNCTION_KEYS + FUNCTION_KEY_SPACING*TOTAL_FUNCTION_KEYS+315, FUNCTION_KEY_BUTTON_HEIGHT+25);
        self.view.userInteractionEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


/*
 * Creates Function Key Toolbar view
 */
- (UIView*)createFunctionsKeysToolbarView
{
    UIView* toolbarview = [[UIView alloc] init];
    
    toolbar = [[UIToolbar alloc] init];
    [UIUtils layoutKeyboardToolbar:toolbar];

    functionKeys = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    flexible.width = FUNCTION_KEY_SPACING;
    
    CGSize buttonSize = CGSizeMake(FUNCTION_KEY_BUTTON_WIDTH, FUNCTION_KEY_BUTTON_HEIGHT);
    
    // add function keys f1-f12
    for (int i = 1; i <= TOTAL_FUNCTION_KEYS; i++)
    {
        CustomKeyButton *keyButton = [CustomKeyButton createWithTitle:[NSString stringWithFormat:@"F%d", i] size:buttonSize delegate:self action:@selector(customKeyAction:) keys:[self keysForFunctionKeyTag:i] tag:i];
        
        [functionKeys addObject:keyButton];
        if (i != TOTAL_FUNCTION_KEYS)
            [functionKeys addObject:flexible];
    }
    
    toolbar.items = functionKeys;
    
    [toolbarview addSubview:toolbar];
    
    return toolbarview;
}

/*
 * Handles custom key button
 * By default, does nothing
 * To customize behavior, override in descendant class. 
 * Key id can be obtained from button parameter (button.keys)
 */
- (void)customKeyAction:(CustomKeyButton*)button
{
    [functionKeyDelegate customKeyAction:button];
}


/*
 * Returns FHLib defined key id for corresponding F key tag
 */
- (int)keysForFunctionKeyTag:(NSInteger)tag
{
    switch (tag) {
        case 1:
            return kKbF1;
            break;
        case 2:
            return kKbF2;
            break;
        case 3:
            return kKbF3;
            break;
        case 4:
            return kKbF4;
            break;
        case 5:
            return kKbF5;
            break;
        case 6:
            return kKbF6;
            break;
        case 7:
            return kKbF7;
            break;
        case 8:
            return kKbF8;
            break;
        case 9:
            return kKbF9;
            break;
        case 10:
            return kKbF10;
            break;
        case 11:
            return kKbF11;
            break;
        case 12:
            return kKbF12;
            break;
        default:
            return 0;
            break;
    }
}

@end
