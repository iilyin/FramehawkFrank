//
//  CommandCenter.h
//  Framehawk
//
//  Created by Hursh Prasad on 4/16/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>


typedef enum {
    CC_IDLE,
    CC_PARSING_XML,
    CC_BUILDING_MENU,
    CC_SETUP_MENU_SERVICES,
    CC_MENU_COMPLETE,
    CC_CREATING_FH_SESSION,
    CC_PROFILE_INVALID,
    CC_GENERATED_PROFILE_LIST,
    DS_ERROR,
} Command_Center_State;


@interface CommandCenter : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSMutableDictionary* installedProfiles;

@property (strong, nonatomic) NSMutableDictionary* uninstalledProfiles;

@property (strong, nonatomic) NSString* sessionId;

@property (strong, nonatomic) FHLoginResponse loginResponse;

@property (strong, nonatomic) FHGetProfilesListResponse getProfilesListResponse;

@property (strong, nonatomic) FHGetProfileResponse getProfileResponse;

@property (assign) Command_Center_State state;

@property (strong, nonatomic) NSArray* templates;


+ (CommandCenter*)get;
+ (CommandCenter*) getFresh;

/*
 * Parse profiles list data
 */
- (void)parseProfilesListData:(NSData*)data;

/*
 * Build Launchpad menu
 */
- (void)buildLaunchPadMenu;

/*
 * Login to studio with username & password
 */
- (void)loginUsername:(NSString*)username password:(NSString*)password response:(FHLoginResponse)response;

/*
 * Get current profile from studio
 */
- (void)getCurrentProfile:(FHGetProfileResponse)response;

/*
 * Get profile list from studio
 */
- (void)getProfilesList:(FHGetProfilesListResponse)response;

/*
 * Load installed profiles.
 */
- (void)loadInstalledProfiles;

/*
 * Load saved profiles.
 */
- (void)loadSavedProfiles:(NSString *)username;

/*
 * Load profiles list.
 */
-(BOOL)loadSavedProfileList:(NSString *)username;

/*
 * Deletes the dictionary of installed profiles from the keychain.
 */
- (void) deleteInstalledProfiles;
/*
 * Deletes the dictionary of uninstalled profiles from the keychain.
 */
- (void) deleteUnInstalledProfiles;

/*
 * Saves the dictionary of installed profiles to the keychain.
 */
- (void) saveInstalledProfiles;

/*
 * Load installed profiles.
 */
-(NSMutableDictionary*)getCurrentProfile;

/*
 * Check if network is available
 * Currently used to check if the application is in a state that it can not get out of
 * TODO: remove when we have a network class
 */
+ (BOOL)networkIsAvailable;

@end

