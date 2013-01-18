//
//  PINView.m
//  Launchpad
//
//  Created by Ellie Shin on 7/6/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "PINPadView.h"
#import "PINViewController.h"
#import "GlobalDefines.h"
#import "SettingsUtils.h"

#define PIN_BUTTON_WIDTH 85
#define PIN_BUTTON_HEIGHT 45
#define PIN_BUTTON_MARGIN 60

// PIN entry dialog text strings
static NSString *const kEnterPINTitle       = @"Enter PIN";
static NSString *const kReEnterPINTitle     = @"Re-enter PIN";
static NSString *const kEnterOldPINTitle    = @"Enter Old PIN";
static NSString *const kSetupPINTitle       = @"Setup PIN";
static NSString *const kWrongPINTitle       = @"Wrong PIN. Try again!";
static NSString *const kMismatchPINTitle    = @"PIN Mismatch. Try again!";
static NSString *const kCancelPINTitle      = @"Cancel";

@implementation PINPadView

@synthesize delegate, pinstr, reset;

-(id) init {
    
    self = [super init];
    if(self){
        
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin_view_bg"]];
        [iv sizeToFit];
        self.frame = iv.frame;
        [self addSubview:iv];
        
        UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(60, 80, iv.bounds.size.width-120, 50)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.text = kEnterPINTitle;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont boldSystemFontOfSize:22];
        lbl.textAlignment = UITextAlignmentCenter;
        viewTitle = lbl;
        
        UIImageView* ev = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin_view_error_bg"]];
        [ev sizeToFit];
        CGRect efr = ev.frame;
        efr.origin.x = 30;
        efr.origin.y = 60;
        ev.frame = efr; 
        ev.hidden = YES;
        errorView = ev;
        [self addSubview:errorView];
        [self addSubview:lbl];
        
        UILabel* p1 = [[UILabel alloc] initWithFrame:CGRectMake(60, 160, 60, 44)];
        UILabel* p2 = [[UILabel alloc] initWithFrame:CGRectMake(130, 160, 60, 44)];
        UILabel* p3 = [[UILabel alloc] initWithFrame:CGRectMake(200, 160, 60, 44)];
        UILabel* p4 = [[UILabel alloc] initWithFrame:CGRectMake(270, 160, 60, 44)];
        pin = [[NSArray alloc] initWithObjects:p1,p2,p3,p4, nil];
        [self addSubview:p1];    
        [self addSubview:p2];    
        [self addSubview:p3];    
        [self addSubview:p4];    
        
        int bx = 60, by = 225;
        
        for(int i=0; i<10;i++){
            
            UIButton* b1 = [UIButton buttonWithType:UIButtonTypeCustom];
            
            b1.frame = CGRectMake(bx, by, 85, 45);
            b1.backgroundColor = [UIColor clearColor];
            
            [b1 setTitle:[NSString stringWithFormat:@"%d", (i+1)%10] forState:UIControlStateNormal];
            [b1 addTarget:self action:@selector(numClicked:) forControlEvents:UIControlEventTouchUpInside];
            b1.titleLabel.font = [UIFont boldSystemFontOfSize:28];
            [self addSubview:b1];
            
            bx += b1.bounds.origin.x + b1.bounds.size.width +10;
            
            if(i%3 == 2){
                bx = 60;
                by += b1.bounds.origin.y + b1.bounds.size.height + 10;
            }
            
            if(i==8){
                bx += b1.bounds.origin.x + b1.bounds.size.width +10;
            }
        }
        
        UIButton* back = [UIButton buttonWithType:UIButtonTypeCustom];
        back.backgroundColor = [UIColor clearColor];
        
        [back setBackgroundImage:[UIImage imageNamed:@"pin_back_button"] forState:UIControlStateNormal];
        [back setBackgroundImage:[UIImage imageNamed:@"pin_back_button_selected"] forState:UIControlStateHighlighted];
        [back addTarget:self action:@selector(backClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [back sizeToFit];
        CGRect fr = back.frame;
        fr.origin.x = bx+25;
        fr.origin.y = by+8;
        back.frame = fr;
        [self addSubview:back];
        
        cancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancel setTitle:@"?" forState:UIControlStateNormal];
        cancel.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        cancel.backgroundColor = [UIColor clearColor];
        cancel.titleLabel.textColor = [UIColor whiteColor];
        fr = cancel.frame;
        fr.origin.x = 60;
        fr.origin.y = by;
        fr.size.width = 85;
        fr.size.height = 45;
        cancel.frame = fr; 
        //        cancel.hidden = YES; 
        [cancel addTarget:self action:@selector(cancelPin:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancel];   
    }
    return self;
}

- (BOOL) hasPin {
    NSString* p = [self existingPin];
    return (p != nil && p.length == 4); 
}

- (NSString*) existingPin {
    // get current PIN from settings
    return [SettingsUtils getCurrentUserPIN];
}

- (BOOL) needReset {
    return [(PINViewController*)self.delegate reset];
}

- (void)layoutSubviews {
    
    [cancel setTitle:@"?" forState:UIControlStateNormal]; 
    
    if([self hasPin]){
        if([self needReset]){
            viewTitle.text = kEnterOldPINTitle;
            [cancel setTitle:kCancelPINTitle forState:UIControlStateNormal];
        }
        else {
            viewTitle.text = kEnterPINTitle;
        }
    }
    else {
        viewTitle.text = (enterCount > 1) ? kReEnterPINTitle :  kSetupPINTitle;
    }
}

- (void) cancelPin: (UIButton*) control {
    
    if([control.titleLabel.text isEqualToString:kCancelPINTitle]){
        
        if([self.delegate respondsToSelector:@selector(didCancelPin:)])
        {
            [self.delegate didCancelPin:self]; 
        }
    }
    else {  // title == "?"
        if([self.delegate respondsToSelector:@selector(didClickHelp:)])
        {
            [self.delegate didClickHelp:self]; 
        }
        
    }
}


- (void) numClicked: (UIButton*) bt
{    
    if(!self.pinstr)
        self.pinstr = @"";
    
    self.pinstr = [self.pinstr stringByAppendingString:bt.titleLabel.text];
    
    [self updateLabel];
    
    if(self.pinstr.length > 0 && (self.pinstr.length %4 == 0)) 
    {
        // delay is so that passcode label is given enough time to be updated with "-" 
        [self performSelector:@selector(didUpdateLabel) withObject:nil afterDelay:.1];  
    }     
}


- (void) resetLabel 
{
    for (UILabel* el in pin)
    {
        el.text = @""; 
    }
}

- (void) updateLabel 
{
    
    UILabel* el = [pin objectAtIndex:(self.pinstr.length-1)%4];
    
    el.text = @"-";
    el.font = [UIFont boldSystemFontOfSize:48];
    el.textAlignment = UITextAlignmentCenter;
}


- (void) didUpdateLabel 
{
    enterCount++;   
    
    if([self hasPin]) 
    {
        NSString* upin = [self existingPin];
        if([self.pinstr isEqualToString: upin])
        {
            if([self needReset])
            {
                viewTitle.text = kSetupPINTitle;
                //cancel.hidden = YES;
                [cancel setTitle:@"?" forState:UIControlStateNormal];
                
                errorView.hidden = YES;
                self.userInteractionEnabled = YES;
                enterCount = 0;
                self.pinstr = @"";
                [self resetLabel];
                
                // clear PIN from settings
                [SettingsUtils clearCurrentUserPIN];
            }
            else {
                if([self.delegate respondsToSelector:@selector(didEnterPin:)])
                {
                    [self.delegate didEnterPin:self]; 
                }
            }
        }
        else
        {
            // make sure number's entered  
            if(upin.length > 0) 
            {
                [self wrongPIN];    
                enterCount = 0;
                self.pinstr = @"";
                [self resetLabel];    
            }
        }
    }
    else 
    {
        if(enterCount == 1){
            viewTitle.text = kReEnterPINTitle;
            [self resetLabel];
        }
        else // entercount == 2
        {
            // compare 
            NSString* second = [self.pinstr substringFromIndex:4];
            self.pinstr = [self.pinstr substringToIndex:4];
            
            if([self.pinstr isEqualToString: second]) 
            {
                if([self.delegate respondsToSelector:@selector(didEnterPin:)])
                {
                    [self.delegate didEnterPin:self]; 
                }
            }
            else {
                
                if(second.length > 0 ){
                    [self mismatchPIN];                         
                    enterCount = 0;
                    self.pinstr = @"";
                    [self resetLabel];
                }
            }
        }
    }
}


- (void) wrongPIN 
{
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options: UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         viewTitle.text = kWrongPINTitle;
                         errorView.hidden = NO;
                         self.userInteractionEnabled = NO;
                     } 
                     completion:^(BOOL finished){
                         
                         double delayInSeconds = 1.0;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             viewTitle.text =  [self needReset] ? kEnterOldPINTitle :  kEnterPINTitle;
                             errorView.hidden = YES;
                             self.userInteractionEnabled = YES;
                         });
                     }];
}

-(void) mismatchPIN 
{    
    [UIView animateWithDuration:1
                          delay:0
                        options: UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         viewTitle.text = kMismatchPINTitle;
                         errorView.hidden = NO;
                         self.userInteractionEnabled = NO;
                     } 
                     completion:^(BOOL finished){
                         
                         double delayInSeconds = 1.0;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             viewTitle.text = kSetupPINTitle;
                             errorView.hidden = YES;
                             self.userInteractionEnabled = YES;
                         });
                     }];
    
}

- (void) backClicked: (UIButton*) bt
{
    if(!self.pinstr || self.pinstr.length%4 == 0)
        return;
    
    int idx = self.pinstr.length - 1;
    UILabel* el = [pin objectAtIndex:idx%4];
    el.text = @""; 
    self.pinstr = [self.pinstr substringToIndex:idx];
}

@end
