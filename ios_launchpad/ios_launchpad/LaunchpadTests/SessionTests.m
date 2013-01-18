//
//  SessionTests.m
//  Tests for Session Management
//
//  Launchpad
//
//  Created by Rich Cowie on 11/26/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SessionTests.h"
#import "SessionManager.h"
#import "Session.h"

@implementation SessionTests

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


// String for name of test session
static NSString *kTestSessionNameString      = @"Test Session 1";
// Number of default sessions to set session manager to initialize space for
static const int kDefaultSessionCount = 20;

/**
 * Check create new session
 */
- (void)testCreateNewSession
{
    // Create session
    SessionKey newSessionKey = [SessionManager createSessionNamed:kTestSessionNameString withParameters:nil viewDelegate:self connectionDelegate:self sessionCount:kDefaultSessionCount];
    
    // Check that a valid session key was returned to access the session
    if (newSessionKey==nil)
        STFail(@"SessionTests createSessionNamed method failed!");
    
    // Get session name string for new session
    NSString* sessionNameStr = [SessionManager getSessionNameForSessionWithKey:newSessionKey];
    
    // Check that newly created session name matches specified session name
    if (![sessionNameStr isEqualToString:kTestSessionNameString])
        STFail(@"SessionTests getSessionNameForSessionWithKey method failed!");
    
    
}


@end
