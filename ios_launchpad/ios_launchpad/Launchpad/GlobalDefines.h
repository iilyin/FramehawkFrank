/**
 * @file
 * GlobalDefines.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 *
 * Global defines for Launchpad
 *
 * @brief Global Defines for Launchpad.
 */

#ifndef __GLOBAL_DEFINES_H
#define __GLOBAL_DEFINES_H

// key for accessing application has launched once flag in NSUserDefaults
#define kApplicationHasLaunchedPreviouslyDefaultKey     @"HasLaunchedOnce"
// key for accessing default profile Id
#define kDefaultProfileIdKey                            @"defaultProfileId"
// key for accessing currently selected profile Id
#define kSelectedProfileIdKey                           @"selectedProfileId"
// key for accessing Studio URL override in NSUserDefaults
#define kStudioUrlKey                                   @"StudioURL"
// key for accessing last referenced Studio URL in NSUserDefaults
#define kLastStudioUrlKey                               @"lastUrl"
// key for quit on exit (closes services on background) setting in NSUserDefaults
#define kQuitOnExitKey                                  @"quitonexitapp"
// key for user has accepted EULA in NSUserDefaults
#define kHasAcceptedEULAKey                             @"HasAcceptedEULA"

// key for storing settings dictionary in keychain
#define kFramehawkSettingsKey                   @"FramehawkSettings101"

// empty string used to clear settings values
#define sSettingsClearValue                     @""

// key for storing boolean values as strings
#define sSettingsBoolTrue                       @"1"
#define sSettingsBoolFalse                      @"0"

// key for storing proxy username in settings
#define kSettingsProxyUserNameKey               @"proxyusername"
// key for storing proxy password in settings
#define kSettingsProxyPasswordKey               @"proxypassword"

// Profile service login assistant data storage strings
// Service login assistant user Id
#define sProfileServiceAppUserId                @"_%@_%@_login_assistant_userId"
// Service login assistant user password
#define sProfileServiceAppUserPwd               @"_%@_%@_login_assistant_userPwd"
// Service menu login enabled
#define sProfileServiceMenuItemLoginEnabled     @"_%@_%@_login_assistant_enabled"

// PIN identifier
#define sPINIdentifierFormatKey                 @"%@_pin"

// Launchpad current user id key
#define kLaunchpadCurrentUsernameKey            @"LaunchpadUserId"
// Launchpad current user password key
#define kLaunchpadCurrentUserPasswordKey        @"LaunchpadUserPassword"

// Launchpad settings layout
#define LAUNCHPAD_SETTINGS_WIDTH            400
#define LAUNCHPAD_SETTINGS_HEIGHT           600
#define LAUNCHPAD_SETTINGS_ANIMATE_TIME     0.4
#define LAUNCHPAD_SETTINGS_FRAME CGRectMake(340,100,LAUNCHPAD_SETTINGS_WIDTH,LAUNCHPAD_SETTINGS_HEIGHT);

#endif