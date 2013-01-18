//
//  MenuSelectionCell.m
//  Framehawk
//
//  Cell for sessions menu
//
//  Created by Hursh Prasad on 4/17/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "AppDelegate.h"
#import "CloseSessionButton.h"
#import "CommandCenter.h"
#import "File.h"
#import "BrowserServiceViewController.h"
#import "MenuCommands.h"
#import "FHServiceViewController.h"
#import "MenuSelectionCell.h"
#import "MenuViewController.h"
#import "ProfileDefines.h"

@interface MenuSelectionCell () {
    
    // Images
    UIImage* _closeButtonImage;
    UIImage* _iconImage;
    UIImage* _backgroundImage;
    UIImage* _rowDividerImage;
    
    // UI Components
    UIImageView* _rowDivider;
    UIImageView* _background;
    UIImageView* _icon;
    UILabel* _label;
    CloseSessionButton* _closeButton;
}


@end

// Service Icon layout
#define SERVICE_ICON_X_OFFSET           12
#define SERVICE_ICON_Y_OFFSET           5      //TODO: vertical center icons

@implementation MenuSelectionCell
@synthesize command;
@synthesize connectionIsClosed;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Images
        _closeButtonImage = [UIImage imageNamed:@"menu_close_icon"];
        
        // Background Image
        _background = [[UIImageView alloc] init];
        
        // Icon Image
        _icon = [[UIImageView alloc] init];
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        _icon.frame = CGRectMake(SERVICE_ICON_X_OFFSET, SERVICE_ICON_Y_OFFSET, 0, 0);
        
        // Label
        _label = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, 200, 41)];
        _label.backgroundColor = [UIColor clearColor];
        UIFont* f = [UIFont fontWithName:@"TeX Gyre Adventor" size:18];
        _label.font = f;
        _label.textAlignment = UITextAlignmentLeft;
        _label.textColor = [UIColor whiteColor];
        
        
        // Assemble views
        [self.contentView addSubview:_background];
        [self.contentView addSubview:_label];
        [self.contentView addSubview:_icon];
        _rowDivider = [[UIImageView alloc] initWithImage:[MenuCommands get].menuRowDividerImage];
//        _rowDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_row_divider"]];
        CGRect fr = _rowDivider.frame;
        fr.origin.y = self.contentView.frame.size.height-[MenuCommands get].menuRowDividerImage.size.height;
        _rowDivider.frame = fr; 
        [self.contentView addSubview:_rowDivider];
        
        
        [[MenuCommands get] addObserver:self forKeyPath:@"state" options:0 context:nil];
    }
    return self;
}


- (void) dealloc {
    MenuCommands* c = [MenuCommands get];
    [c removeObserver:self forKeyPath:@"state"];
}


- (void)setSelectionCommand:(NSString*)selectionCommand {
    
    // Obtain the latest profile
    MenuCommands* m = [MenuCommands get];
    NSDictionary* c = [m getCommandWithName:selectionCommand];
    
    // Refresh cell from command
    // - Label
    _label.text = selectionCommand;
    self.command = selectionCommand;
    self.accessibilityLabel = selectionCommand;
    // - Icon
    // If selected...
    if (self.selected) {
        _label.textColor = [MenuCommands get].menuSelectedTextColor;

        // - Selected icon graphic
        NSString* s = [c objectForKey:kProfileSelectedButtonIconKey];
        
         if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
             DLog(@"%@",s);
             _iconImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
             
         }else{
        
             _iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
         }
        // set icon image
        _icon.image = _iconImage;
        // set size & position of icon
        _icon.frame = CGRectMake(SERVICE_ICON_X_OFFSET, SERVICE_ICON_Y_OFFSET, _iconImage.size.width, _iconImage.size.height);

        
        // - Selected session background graphic
        s = [c objectForKey:kProfileMenuItemSelectedBackgroundKey];
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
            DLog(@"%@",s);
            _backgroundImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
            
        }else{
            
            _backgroundImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
        }
        
        // set up background image and size
        _background.image = _backgroundImage;
        _background.frame = CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height);

        
    }
    // otherwise if unselected...
    else {
        
        _label.textColor = [MenuCommands get].menuUnselectedTextColor;
        
        // - Unselected icon graphic
        NSString* s = [c objectForKey:kProfileButtonIconKey];
        DLog(@"%@",s);
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path]]]) {
            DLog(@"%@",s);
            _iconImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
        }else{
        _iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
        }
        // set icon image
        _icon.image = _iconImage;
        // set size & position of icon
        _icon.frame = CGRectMake(SERVICE_ICON_X_OFFSET, SERVICE_ICON_Y_OFFSET, _iconImage.size.width, _iconImage.size.height);
        
        // - Unselected session background graphic
        s = [c objectForKey:kProfileMenuItemUnselectedBackgroundKey];
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
            DLog(@"%@",s);
            _backgroundImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
            
        }else{
            
            _backgroundImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
        }
        
        // set up background image and size
        _background.image = _backgroundImage;
        _background.frame = CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height);
        
        // set up close service image
        // - Unselected session background graphic
        s = [c objectForKey:kProfileMenuCloseServiceIconKey];
        
        if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
            DLog(@"%@",s);
            _closeButtonImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
            
        }else{
            
            _closeButtonImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
        }
    }
}


-(void)closeApplication:(id)sender {
    
    DLog(@"Closing Session for %@ !!!!", self.command);
    
    // Obtain the latest profile
    NSString* cmd = self.command;
    
    CloseSessionButton * msc = (CloseSessionButton *)sender;
    [msc removeTarget:self action:@selector(closeApplication:) forControlEvents:UIControlEventTouchUpInside];
    [msc removeFromSuperview];
    
    // Obtain the latest profile
    MenuCommands* m = [MenuCommands get];
    NSDictionary* c = [m getCommandWithName:cmd];
    
    // set menu item text color back to unselected
    _label.textColor = [MenuCommands get].menuUnselectedTextColor;
   
    // - Unselected icon graphic
    NSString* s = [c objectForKey:kProfileButtonIconKey];
    
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path]]]) {
        DLog(@"%@",s);
        _iconImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
        
    }else{
    _iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
    }
    
    // set icon image
    _icon.image = _iconImage;
    // set size & position of icon
    _icon.frame = CGRectMake(SERVICE_ICON_X_OFFSET, SERVICE_ICON_Y_OFFSET, _iconImage.size.width, _iconImage.size.height);
    
    // Unselected background graphic
    s = [c objectForKey:kProfileMenuItemUnselectedBackgroundKey];
    
    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
        DLog(@"%@",s);
        _backgroundImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
        
    }else{
        
        _backgroundImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
    }
    
    // set up background image and size
    _background.image = _backgroundImage;
    _background.frame = CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height);

    
    // Close Button
    [_closeButton removeFromSuperview];
    [[self viewWithTag:404] removeFromSuperview];
    [(UIButton *)[self viewWithTag:404] removeTarget:self action:@selector(switchToView:) forControlEvents:UIControlEventTouchUpInside];
    
    self.connectionIsClosed = YES;
    
    [[MenuCommands get] closeApplication:cmd];
}

-(void)switchToView:(id)sender{
    
    NSString* cmd =self.command;
    DLog(@"***** Switching to View.... %@ ******",cmd);
//    if(((FHServiceViewController *)[[MenuCommands get] getCurrentSession]).firstAppearCompleted)
    // Updated kernel should allow session to be opened even if current hasn't completed first render
        [[MenuCommands get] openApplication:cmd withOption:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    NSString* cmd = self.command;
    
    switch ([MenuCommands get].state) {
        case MC_SESSION_READY_TO_OPEN:{
            NSString *openingCommand;
            UIViewController *uvc =  nil;
            int numOpenCommands = [MenuCommands getNumberOfOpenCommands];
            //TODO: handle zero sessions or figure out why there would be zero
            if (numOpenCommands>0)
                uvc = [[MenuCommands get].openSessions objectAtIndex:(numOpenCommands - 1)];
            
            if ([uvc isKindOfClass:[BrowserServiceViewController class]]) {
                openingCommand = ((BrowserServiceViewController *)uvc).command;
            }else {
                openingCommand = ((FHServiceViewController *)uvc).command;
            }
            
            if ([cmd isEqualToString:openingCommand]){
                // if session is closed & view is empty
                
//                if ([MenuCommands checkIfCommandIsOpen:command]) {
                
                
                if (self.connectionIsClosed) {
                    _label.textColor = [MenuCommands get].menuSelectedTextColor;
                    
                    // Obtain the latest profile
                    MenuCommands* m = [MenuCommands get];
                    NSDictionary* c = [m getCommandWithName:cmd];
                    
                    // - Set selected icon graphic
                    NSString* s = [c objectForKey:kProfileSelectedButtonIconKey];
                    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path]]]) {
                        DLog(@"%@",s);
                        _iconImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
                        
                    }else{
                    _iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
                    }
                    
                    // set icon image
                    _icon.image = _iconImage;
                    // set size & position of icon
                    _icon.frame = CGRectMake(SERVICE_ICON_X_OFFSET, SERVICE_ICON_Y_OFFSET, _iconImage.size.width, _iconImage.size.height);
                    
                    // - Selected session background graphic
                    s = [c objectForKey:kProfileMenuItemSelectedBackgroundKey];
                    
                    if ([File checkFileExists:[File getProfileImagePath:[[NSURL URLWithString:s] path] ]]) {
                        DLog(@"%@",s);
                        _backgroundImage = [UIImage imageWithContentsOfFile:[File getProfileImagePath:[[NSURL URLWithString:s] path]]];
                        
                    }else{
                        
                        _backgroundImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:s]]];
                    }

                    // set up background image and size
                    _background.image = _backgroundImage;
                    _background.frame = CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height);

                    
                    
                    UIButton *switchToCurrentView = [UIButton buttonWithType:UIButtonTypeCustom];
                    [switchToCurrentView setTag:404];
                    switchToCurrentView.frame =  _background.frame;
                    [switchToCurrentView addTarget:self action:@selector(switchToView:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self addSubview:switchToCurrentView];
                    
                    // Initialize and add the close button
                    _closeButton = [CloseSessionButton buttonWithType:UIButtonTypeCustom];
                    _closeButton.frame = CGRectMake(self.contentView.frame.size.width - 40, 5.0, 35.0, 35.0);
                    [_closeButton addTarget:self action:@selector(closeApplication:) forControlEvents:UIControlEventTouchUpInside];
                    [_closeButton setImage:_closeButtonImage forState:UIControlStateNormal];
                    [self addSubview:_closeButton];
                    
                    self.connectionIsClosed = NO;
                }
                
            }
        }
            break;
        case MC_SESSION_READY_TO_CLOSE:{
            NSString *closingCommand;
            int closeIndex = [[MenuCommands get].closeIndex intValue];
            
            if (closeIndex != -1) {
                UIViewController *uvc = [[MenuCommands get].openSessions objectAtIndex:closeIndex];
                
                if ([uvc isKindOfClass:[BrowserServiceViewController class]]) {
                    closingCommand = ((BrowserServiceViewController *)uvc).command;
                }else {
                    closingCommand = ((FHServiceViewController *)uvc).command;
                }
                
                if ([cmd isEqualToString:closingCommand]){
                    if (!self.connectionIsClosed) 
                    {
                        [self closeApplication:_closeButton];
                    }
                }
            }
            
        }
            break;
        case MC_SESSION_NEEDS_REVERSE_PROXY:
            //DLog(@"**** NEEDS REVERSE PROXY %@ ******",cmd);
            break;
        case MC_SESSION_CANCEL_REVERSE_PROXY:
            if ([[MenuCommands get] isProxyedServiceCommand:cmd] && self.connectionIsClosed == NO) {
                DLog(@"*** Checking to Close %@",cmd);
                [self closeApplication:_closeButton];
            }

            break;
        default: 
            break;
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


@end