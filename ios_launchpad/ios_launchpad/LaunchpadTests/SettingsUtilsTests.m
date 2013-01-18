//
//  SettingsUtilsTests.m
//  Launchpad
//
//  Created by Rich Cowie on 11/26/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SettingsUtilsTests.h"
#import "SettingsUtils.h"

@implementation SettingsUtilsTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

/*
 * Test SettingsUtils User Id
 */
static NSString *kUserIdTestString      = @"TestUserID";

/*
 * Check save/load user name using SettingsUtils methods
 */
- (void)testSettingsUtilsSaveLoadUserId
{
    // check that saved user id is same when reloaded
    [SettingsUtils saveCurrentUserID:kUserIdTestString];
    NSString* userIdString = [SettingsUtils getCurrentUserID];
    if (![userIdString isEqualToString:kUserIdTestString])
        STFail(@"SettingsUtils saveCurrentUserID failed");
    
    // check clearing user id
    [SettingsUtils clearCurrentUserID];
    userIdString = [SettingsUtils getCurrentUserID];
    if ([userIdString length]!=0)
        STFail(@"SettingsUtils clearDefaultProfileId failed");
}

/*
 * Test SettingsUtils User Password
 */
static NSString *kPasswordTestString    = @"TestPassword";

/*
 * Check save/load user name using SettingsUtils methods
 */
- (void)testSettingsUtilsSaveLoadUserPassword
{
    // check that saved user password is same when reloaded
    [SettingsUtils saveCurrentUserPassword:kPasswordTestString];
    NSString* userPasswordString = [SettingsUtils getCurrentUserPassword];
    if (![userPasswordString isEqualToString:kPasswordTestString])
        STFail(@"SettingsUtils saveCurrentUserPassword failed");
    
    // check clearing user password
    [SettingsUtils clearCurrentUserPassword];
    userPasswordString = [SettingsUtils getCurrentUserPassword];
    if ([userPasswordString length]!=0)
        STFail(@"SettingsUtils clearCurrentUserPassword failed");
    
}

/*
 * Test SettingsUtils User PIN
 */
static NSString *kPINTestString         = @"1243";

/*
 * Check save/load PIN using SettingsUtils methods
 */
- (void)testSettingsUtilsSaveLoadPIN
{
    // check that saved user PIN is same when reloaded
    [SettingsUtils saveCurrentUserPIN:kPINTestString];
    NSString* userPINString = [SettingsUtils getCurrentUserPIN];
    if (![userPINString isEqualToString:kPINTestString])
        STFail(@"SettingsUtils saveCurrentUserPIN failed");
    
    // check clearing user PIN
    [SettingsUtils clearCurrentUserPIN];
    userPINString = [SettingsUtils getCurrentUserPIN];
    if ([userPINString length]!=0)
        STFail(@"SettingsUtils clearCurrentUserPIN failed");
}

@end
