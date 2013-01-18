//
//  SettingsUtils.h
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

#import <Foundation/Foundation.h>

@interface SettingsUtils : NSObject

/**
 * Returns true if application has launched previously
 * Flag is stored in NSUserDefaults, so it is cleared if
 * the application is deleted - so use this to know to clear
 * settings stored in keychain on fresh launch
 */
+ (BOOL)applicationHasLaunchedPreviously;

/**
 * Set boolean value to signifiy application has launched previously
 */
+ (void)setApplicationHasLaunchedPreviously:(BOOL)theBoolean;

/**
 * Set default profile Id
 */
+ (void)setDefaultProfileId:(NSString*)theProfileId;

/**
 * Get default profile Id
 */
+ (NSString*)getDefaultProfileId;

/**
 * Clear default profile Id
 */
+ (void)clearDefaultProfileId;

/**
 * Set selected profile Id
 */
+ (void)setSelectedProfileId:(NSString*)theProfileId;

/**
 * Get selected profile Id
 */
+ (NSString*)getSelectedProfileId;

/**
 * Clear selected profile Id
 */
+ (void)clearSelectedProfileId;

/**
 * Delete Settings
 * Deletes the settings dictionary stored in the keychain
 */
+ (void)deleteSettings;

/**
 * Generic method to clear a setting for specified key
 */
+ (void)clearSettingWithKey:(NSString*)theSettingKeyString;

/**
 * Generic method to load a string setting for specified user, profile & app
 * NOTE: string is loaded from keychain for security
 */
+ (NSString *)loadStringSettingWithKey:(NSString*)theSettingKeyString;

/**
 * Generic method to save a string setting for specified user, profile & app
 * NOTE: string is saved to keychain for security
 */
+ (void)saveStringSetting:(NSString *)theSetting withKey:(NSString*)theSettingKeyString;

/**
 * Generic method to load a boolean setting for specified user, profile & app
 */
+ (BOOL)loadBooleanSettingWithSettingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Generic method to save a boolean setting for specified user, profile & app
 */
+ (void)saveBooleanSetting:(BOOL)theSetting settingKeyFormatString:(NSString*)theSettingKeyFormatString userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Load login assistant enabled setting for specified user, profile and app
 */
+ (BOOL)loadLoginAssistantEnabledSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Save login assistant enabled setting for specified user, profile and app
 */
+ (void)saveLoginAssistantEnabledSetting:(BOOL)bIsLoginAssistantEnabled userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Load login assistant Username setting for specified user, profile and app
 */
+ (NSString *)loadLoginAssistantUsernameSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Save login assistant Username setting for specified user, profile and app
 */
+ (void)saveLoginAssistantUsernameSetting:(NSString *)theUserNameSetting userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Load login assistant password setting for specified user, profile and app
 */
+ (NSString *)loadLoginAssistantPasswordSettingForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Save login assistant password setting for specified user, profile and app
 */
+ (void)saveLoginAssistantPasswordSetting:(NSString *)theUserPasswordSetting userId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Clear login assistant credentials for specified user, profile and app
 */
+ (void)clearLoginAssistantCredentialsForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Toggle login assistant off for specified user, profile and app
 */
+ (void)toggleLoginAssistantOffForUserId:(NSString *)theUserId profileId:(NSString *)theProfileId appName:(NSString *)theAppName;

/**
 * Get stored username for current user
 */
+ (NSString*)getCurrentUserID;

/**
 * Save username for current user
 */
+ (void)saveCurrentUserID:(NSString*)theUserId;

/**
 * Clear username for current user
 */
+ (void)clearCurrentUserID;

/**
 * Get stored password for current user
 */
+ (NSString*)getCurrentUserPassword;

/**
 * Save password for current user
 */
+ (void)saveCurrentUserPassword:(NSString*)theUserId;

/**
 * Clear password for current user
 */
+ (void)clearCurrentUserPassword;

/**
 * Get stored PIN for current user
 */
+ (NSString*)getCurrentUserPIN;

/**
 * Save PIN for current user
 */
+ (void)saveCurrentUserPIN:(NSString*)thePIN;

/**
 * Clear PIN for current user
 */
+ (void)clearCurrentUserPIN;

/**
 * Checks specified service information for login assistant allowed setting
 *
 * @return (BOOL) - TRUE if setting is true or setting is not found (so default is ON)
 */
+(BOOL) checkServiceInformationForloginAssistantAllowed:(NSDictionary *)serviceInfo;


@end
