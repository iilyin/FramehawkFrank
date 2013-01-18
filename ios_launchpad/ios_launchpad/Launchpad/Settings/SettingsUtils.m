//
//  SettingsUtils.m
//  Launchpad
//
//  Utility methods for accessing settings
//
//  Most settings are stored in a single NSDictionary item (key kFramehawkSettingsKey)
//  in the keychain. This is done to securely store sensitive user information such as
//  passwords & usernames. A single NSDictionary item is used so that it can easily be
//  deleted on a fresh install of the application, since the items in the keychain persist
//  even after uninstalling an application.
//
//  Settings that do not need to be secured
//  (and can be removed on application deletion/upgrade)
//  are stored in NSDefaults e.g. the flags to signify
//  if the application has previously been launched or the EULA has been accepted.
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import "SettingsUtils.h"
#import "GlobalDefines.h"
#import "ProfileDefines.h"
#import "KeychainItemWrapper.h"
#import <Security/Security.h>

@implementation SettingsUtils

/**
 * Returns true if application has launched previously
 * Flag is stored in NSUserDefaults, so it is cleared if
 * the application is deleted - so use this to know to clear
 * settings stored in keychain on fresh launch
 */
+ (BOOL)applicationHasLaunchedPreviously
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kApplicationHasLaunchedPreviouslyDefaultKey];
}

/**
 * Set boolean value to signifiy application has launched previously
 */
+ (void)setApplicationHasLaunchedPreviously:(BOOL)theBoolean
{
    // Set boolean value in user defaults to signify application has been launched
    [[NSUserDefaults standardUserDefaults] setBool:theBoolean forKey:kApplicationHasLaunchedPreviouslyDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

/**
 * Set default profile Id
 */
+ (void)setDefaultProfileId:(NSString*)theProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:theProfileId forKey:kDefaultProfileIdKey];
}

/**
 * Get default profile Id
 */
 + (NSString*)getDefaultProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kDefaultProfileIdKey];
}

/**
 * Clear default profile Id
 */
+ (void)clearDefaultProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kDefaultProfileIdKey];
}

/**
 * Set selected profile Id
 */
+ (void)setSelectedProfileId:(NSString*)theProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:theProfileId forKey:kSelectedProfileIdKey];
}

/**
 * Get selected profile Id
 */
+ (NSString*)getSelectedProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kSelectedProfileIdKey];
}

/**
 * Clear selected profile Id
 */
+ (void)clearSelectedProfileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSelectedProfileIdKey];
}


/**
 * Get settings dictionary from keychain
 */
+ (NSMutableDictionary *)getSettingsDictionary
{
    // get Framehawk settings data from keychain
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kFramehawkSettingsKey accessGroup:nil];
    NSData *data = (id)[wrapper objectForKey:(__bridge id)kSecValueData];
    
    NSMutableDictionary* settingsDictionary = [[NSMutableDictionary alloc] init];
    
    // if there is data for the key
    if ([data length])
    {
        // decode the data
        NSKeyedUnarchiver *unarchivedData = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSDictionary *dict = [unarchivedData decodeObject];
        [unarchivedData finishDecoding];

        // insert existing dictionary settings into dictionary
        [settingsDictionary addEntriesFromDictionary:dict];
    }

    // return settings dictionary
    return settingsDictionary;
}

/**
 * Delete Settings
 * Deletes the settings dictionary stored in the keychain
 */
+ (void)deleteSettings
{
    // Delete settings from keychain
	KeychainItemWrapper *item = [[KeychainItemWrapper alloc] initWithIdentifier:kFramehawkSettingsKey accessGroup:nil];
	[item resetKeychainItem];
}

/**
 * Generic method to clear a setting for specified key
 */
+ (void)clearSettingWithKey:(NSString*)theSettingKeyString
{
    // Reset setting with specified key
    [SettingsUtils saveStringSetting:sSettingsClearValue withKey:theSettingKeyString];
}

/**
 * Generic method to handle loading a string setting for specified key string
 * NOTE: string is loaded from keychain for security
 */
+ (NSString *)loadStringSettingWithKey:(NSString*)theSettingKeyString
{
    // get settings dictionary from keychain
    NSMutableDictionary* settingsDictionary = [SettingsUtils getSettingsDictionary];
    
    // check dictionary for existing value for specified key
    NSString* stringValue = [settingsDictionary objectForKey:theSettingKeyString];

    // return the string setting
    return stringValue;
}

/**
 * Generic method to handle saving a string setting for specified keystring
 * NOTE: string is saved to keychain for security
 */
+ (void)saveStringSetting:(NSString *)theSetting withKey:(NSString*)theSettingKeyString
{
    // get settings dictionary from keychain
    NSMutableDictionary* settingsDictionary = [SettingsUtils getSettingsDictionary];

    // add object to dictionary (if nil then set to empty string)
    [settingsDictionary setObject:(([theSetting length]>0) ? theSetting : sSettingsClearValue ) forKey:theSettingKeyString];
    
    // encode dictionary
    NSMutableData *tmpData = [NSMutableData dataWithCapacity:256];
    NSKeyedArchiver *keyedArchive = [[NSKeyedArchiver alloc] initForWritingWithMutableData:tmpData];
    // encode settings dictionary
    [keyedArchive encodeObject:settingsDictionary];
    [keyedArchive finishEncoding];
    
    // create keychain wrapper for settings dictionary
    KeychainItemWrapper *item = [[KeychainItemWrapper alloc] initWithIdentifier:kFramehawkSettingsKey accessGroup:nil];

    // set settings object in keychain
    [item setObject:kFramehawkSettingsKey forKey:(__bridge id)kSecAttrAccount];
    // save settings dictionary to keychain
    [item setObject:tmpData forKey:(__bridge id)kSecValueData];
}

/**
 * Generic method to load a string setting for specified user, profile & app
 * NOTE: string is loaded from keychain for security
 */
+ (NSString *)loadStringSettingWithSettingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // set service string setting to load
    // obtained using key combining user Id, Profile Id & Service Application Name
    NSString* profileServiceStringSettingkey = [theUserId stringByAppendingFormat:theSettingKeyFormatString, theProfileId, theAppName];
    
    // Use keychain to load string value for specified key
    NSString* stringValueForKey = [self loadStringSettingWithKey:profileServiceStringSettingkey];

    // return string value for specified key
    return stringValueForKey;
}

/**
 * Generic method to save a string setting for specified user, profile & app
 * NOTE: string is saved to keychain for security
 */
+ (void)saveStringSetting:(NSString *)theSetting settingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // set service setting to save
    // storing using key combining user Id, Profile Id & Service Application Name
    NSString* profileServiceSettingkey = [theUserId stringByAppendingFormat:theSettingKeyFormatString, theProfileId, theAppName];
    
    // Use keychain to save string setting
    [self saveStringSetting:theSetting withKey:profileServiceSettingkey];
}

/**
 * Generic method to load a boolean setting for specified user, profile & app
 */
+ (BOOL)loadBooleanSettingWithSettingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // set service boolean setting to load
    // storing using key combining user Id, Profile Id & Service Application Name
    NSString* theServiceSettingKey = [theUserId stringByAppendingFormat:theSettingKeyFormatString, theProfileId, theAppName];
    
    // Use keychain to load string value representing boolean value for specified key
    NSString* stringValueForKey = [self loadStringSettingWithKey:theServiceSettingKey];

    BOOL bBooleanValue = stringValueForKey ? (NSOrderedSame==[stringValueForKey compare:sSettingsBoolTrue]) : FALSE ;
    
    return bBooleanValue;
}

/**
 * Generic method to save a boolean setting for specified user, profile & app
 */
+ (void)saveBooleanSetting:(BOOL)theSetting settingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // set service boolean setting to save
    // storing using key combining user Id, Profile Id & Service Application Name
    NSString* theServiceSettingKey = [theUserId stringByAppendingFormat:theSettingKeyFormatString, theProfileId, theAppName];
    
    // Use keychain to save boolean setting as string
    [self saveStringSetting:(theSetting ? sSettingsBoolTrue : sSettingsBoolFalse ) withKey:theServiceSettingKey];
    
}

/**
 * Load login assistant enabled setting for specified user, profile and app
 */
+ (BOOL)loadLoginAssistantEnabledSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {

    // load login assistant enabled flag
    return [self loadBooleanSettingWithSettingKeyFormatString:sProfileServiceMenuItemLoginEnabled userId:theUserId profileId:theProfileId appName:theAppName];
}

/**
 * Save login assistant enabled setting for specified user, profile and app
 */
+ (void)saveLoginAssistantEnabledSetting:(BOOL)bIsLoginAssistantEnabled userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {
    
    // save login assistant enabled flag
    [self saveBooleanSetting:bIsLoginAssistantEnabled settingKeyFormatString:sProfileServiceMenuItemLoginEnabled userId:theUserId profileId:theProfileId appName:theAppName];
}

/**
 * Load login assistant Username setting for specified user, profile and app
 */
+ (NSString *)loadLoginAssistantUsernameSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {
    
    // return login assistant user id
    return [self loadStringSettingWithSettingKeyFormatString:sProfileServiceAppUserId userId:theUserId profileId:theProfileId appName:theAppName];
    
}

/**
 * Save login assistant Username setting for specified user, profile and app
 */
+ (void)saveLoginAssistantUsernameSetting:(NSString *)theUserNameSetting userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {

    // save login assistant user Id setting string
    [self saveStringSetting:theUserNameSetting settingKeyFormatString:sProfileServiceAppUserId userId:theUserId profileId:theProfileId appName:theAppName];
}

/**
 * Load login assistant password setting for specified user, profile and app
 */
+ (NSString *)loadLoginAssistantPasswordSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // return login assistant user id
    return [self loadStringSettingWithSettingKeyFormatString:sProfileServiceAppUserPwd userId:theUserId profileId:theProfileId appName:theAppName];
}

/**
 * Save login assistant password setting for specified user, profile and app
 */
+ (void)saveLoginAssistantPasswordSetting:(NSString *)theUserPasswordSetting userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName
{
    // save login assistant user password setting string
    [self saveStringSetting:theUserPasswordSetting settingKeyFormatString:sProfileServiceAppUserPwd userId:theUserId profileId:theProfileId appName:theAppName];
}

/**
 * Clear login assistant credentials & password for specified user, profile and app
 */
+ (void)clearLoginAssistantCredentialsForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {
    
    // clear login assistant user ID & password setting strings

    // check if there is a value stored for login assistant username
    if ([SettingsUtils loadLoginAssistantUsernameSettingForUserId:theUserId profileId:theProfileId appName:theAppName]!=nil)
    {
        // clear user id for login assistant
        [SettingsUtils saveLoginAssistantUsernameSetting:sSettingsClearValue userId:theUserId profileId:theProfileId appName:theAppName];
    }

    // check if there is a value stored for login assistant password
    if ([SettingsUtils loadLoginAssistantPasswordSettingForUserId:theUserId profileId:theProfileId appName:theAppName]!=nil)
    {
        // clear password setting for login assistant
        [SettingsUtils saveLoginAssistantPasswordSetting:sSettingsClearValue userId:theUserId profileId:theProfileId appName:theAppName];
    }

}

/**
 * Toggle login assistant off for specified user, profile and app
 */
+ (void)toggleLoginAssistantOffForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName {
    
    // check if login assistant toggle was set to on
    if ([SettingsUtils loadLoginAssistantEnabledSettingForUserId:theUserId profileId:theProfileId appName:theAppName])
    {
        // set login assistant toggle to off
        [SettingsUtils saveLoginAssistantEnabledSetting:FALSE userId:theUserId profileId:theProfileId appName:theAppName];
    }
}


/**
 * Get stored username for current user
 */
+ (NSString*)getCurrentUserID
{
    // gets currently stored user id
    return [SettingsUtils loadStringSettingWithKey:kLaunchpadCurrentUsernameKey];
}

/**
 * Save username for current user
 */
+ (void)saveCurrentUserID:(NSString*)theUserId
{
    // save user id
    [SettingsUtils saveStringSetting:theUserId withKey:kLaunchpadCurrentUsernameKey];
}

/**
 * Clear username for current user
 */
+ (void)clearCurrentUserID
{
    [SettingsUtils clearSettingWithKey:kLaunchpadCurrentUsernameKey];
}

/**
 * Get stored password for current user
 */
+ (NSString*)getCurrentUserPassword
{
    // gets currently stored user id
    return [SettingsUtils loadStringSettingWithKey:kLaunchpadCurrentUserPasswordKey];
}

/**
 * Save password for current user
 */
+ (void)saveCurrentUserPassword:(NSString*)theUserId
{
    // save user id
    [SettingsUtils saveStringSetting:theUserId withKey:kLaunchpadCurrentUserPasswordKey];
}

/**
 * Clear password for current user
 */
+ (void)clearCurrentUserPassword
{
    [SettingsUtils clearSettingWithKey:kLaunchpadCurrentUserPasswordKey];
}

/**
 * Get stored PIN for current user
 */
+ (NSString*)getKeyToAccessCurrentUserPIN
{
    // get current username from settings
    NSString* username = [SettingsUtils getCurrentUserID];
    
    // generate PIN key
    NSString* thePINKey = [NSString stringWithFormat:sPINIdentifierFormatKey, username];
    
    return thePINKey;
}

/**
 * Get stored PIN for current user
 */
+ (NSString*)getCurrentUserPIN
{
    // get PIN key to access PIN setting
    NSString* thePINKey = [SettingsUtils getKeyToAccessCurrentUserPIN];

    // get PIN for current username
    return [SettingsUtils loadStringSettingWithKey:thePINKey];
}

/**
 * Save PIN for current user
 */
+ (void)saveCurrentUserPIN:(NSString*)thePIN
{
    // get PIN key to access PIN setting
    NSString* thePINKey = [SettingsUtils getKeyToAccessCurrentUserPIN];
    
    // save user PIN
    [SettingsUtils saveStringSetting:thePIN withKey:thePINKey];
}

/**
 * Clear PIN for current user
 */
+ (void)clearCurrentUserPIN
{
    // get PIN key to access PIN setting
    NSString* thePINKey = [SettingsUtils getKeyToAccessCurrentUserPIN];
    
    [SettingsUtils clearSettingWithKey:thePINKey];
}

/**
 * Checks specified service information dictionary for login assistant allowed setting
 *
 * @return (BOOL) - TRUE if setting is true or setting is not found (so default is ON)
 */
+(BOOL) checkServiceInformationForloginAssistantAllowed:(NSDictionary *)serviceInfo
{
    // Check Auto-Login allowed from service information
    // if no setting then default to allowing login assistant
    Boolean bLoginAssistantAllowed =
    ([serviceInfo objectForKey:kProfileServiceLoginAssistantAllowedKey]==nil) ?
    TRUE
    : [[serviceInfo valueForKey:kProfileServiceLoginAssistantAllowedKey] boolValue];

    return bLoginAssistantAllowed;
}

@end
