//
//  ServiceLoginSettingsViewController.h
//  Launchpad
//
//  Displays Service Login Assistant Settings & Connection Information
//  for a single service.
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceLoginSettingsViewController : UITableViewController <UITableViewDelegate, UITextFieldDelegate>
{
    NSMutableDictionary *_serviceInformation;
    BOOL            bIsNativeBrowserService;
}

- (void) setServiceInformation:(NSDictionary*)serviceInfo;
- (void) resetLoginAssistantCredentials;
- (void) toggleLoginAssistantPressed:(UIControl *)sender;
@property (nonatomic, strong) NSString* appName;
@property (nonatomic, strong) UITextField* userField;
@property (nonatomic, strong) UITextField* pwdField;
@end
