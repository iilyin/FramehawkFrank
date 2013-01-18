//
//  CommandCenter.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/16/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved


#import "CommandCenter.h"
#import "File.h"
#import "MenuCommands.h"
#import "ProfileDefines.h"
#import "SettingsUtils.h"
#import "GlobalDefines.h"

#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>


// studio data keys
#define kStudioMessageTypeKey               @"messageType"
#define kStudioMessagePayloadKey            @"messagePayload"
#define kStudioMessagePayloadSuccessKey     @"success"
#define kStudioMessageStringKey             @"message"
#define kStudioMessagePayloadResultCodeKey  @"resultCode"
#define kStudioSessionIdKey                 @"sessionId"
#define kStudioUserIdKey                    @"userId"
#define kStudioPasswordKey                  @"password"
#define kStudioBuildVersionKey              @"launchpadBuildVersion"
// studio requests
#define kStudioLoginRequest                 @"LoginRequest"
#define kStudioLoginResponse                @"LoginResponse"
#define kStudioGetProfilesListRequest       @"GetProfilesListRequest"
#define kStudioGetProfilesListResponse      @"GetProfilesListResponse"
#define kStudioGetProfileRequest            @"GetProfileRequest"
#define kStudioGetProfileResponse           @"GetProfileResponse"

//save installed profiles
#define kInstalledProfiles                  @"installed.dat"
#define kUnInstalledProfiles                @"profilelibrary.dat"

static CommandCenter* cCenter;

@interface CommandCenter ()


- (void) loadInstalledProfiles;   

- (CFDictionaryRef)prepareKeychainQueryForDeleteProfiles;

- (CFDictionaryRef)prepareKeychainQueryForLoadProfiles;

- (CFDictionaryRef)prepareKeychainQueryForStoreProfiles;


@end


@implementation CommandCenter


@synthesize installedProfiles, uninstalledProfiles, sessionId, loginResponse, getProfilesListResponse, getProfileResponse, state, templates;


#pragma mark -
#pragma mark CommandCenter Class Methods

/*
 * Get command center
 */
+ (CommandCenter*) get {
    
    if (!cCenter) {
        cCenter = [[CommandCenter alloc] init];
        cCenter.state = CC_IDLE;

        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        //In case there are previous logins
        if (username) {
            [cCenter loadSavedProfiles:username];
            [cCenter loadSavedProfileList:username];
        }

    }
    return cCenter;
}

/*
 * Get fresh command center (no load of installed profiles)
 */
+ (CommandCenter*) getFresh {
    
    if (!cCenter) {
        cCenter = [[CommandCenter alloc] init];
        cCenter.state = CC_IDLE;
    }
    return cCenter;
}


#pragma mark -
#pragma mark CommandCenter Implementation

/*
 * Parse profiles list data
 */
- (void)parseProfilesListData:(NSData*)data {
//    NSData* data = [NSData dataWithContentsOfURL:u];
    if (data)// && [NSJSONSerialization isValidJSONObject:data]) 
    {
        templates = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] objectForKey:@"profiles"];
        // - Add the base URL of the profile manager to the profile for reference
        [templates setValue:launchpadServiceUrl forKey:kProfileLaunchpadServiceUrlKey];
        
        // TODO: update to check version number & possibly remove obsolete profiles
/*        int removeIndex;
        do {
            // set remove index to -1 (signifies nothing to remove)
            removeIndex = -1;
            NSArray* profiles = [CommandCenter get].templates;
            
            // parse list of profiles
            for (NSUInteger i = 0, l = [profiles count]; (i < l) & (removeIndex<0) ; i++)
            {
                NSDictionary* template = [profiles objectAtIndex:i];
                if ([template objectForKey:kProfileVersionKey]!=nil) {
                    // set remove index for this object
                    //removeIndex = i;
                }
            }
            
            // do we want to remove a profile?
            if (removeIndex>=0)
            {
                // duplicate current list of profiles
                NSMutableArray *reducedProfilesListArray = [NSMutableArray arrayWithArray:templates];
                // remove specified profile
                [reducedProfilesListArray removeObjectAtIndex:removeIndex];
                // store modified profiles list
                [CommandCenter get].templates = [NSArray arrayWithArray: reducedProfilesListArray];
            }
        } while (removeIndex>=0);
*/        
        // Generate list of uninstalled profiles
        [self generateUninstalledProfilesDictionary];
    }
}

/*
 * Build Launchpad menu
 */
- (void)buildLaunchPadMenu {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // Fire the parsing event
        cCenter.state = CC_PARSING_XML;

        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];
        
        // Add the applied profile to the list of downloaded profiles
        if (!installedProfiles){
            //Attempt to get the old installed profiles
            
            installedProfiles = [[NSMutableDictionary alloc] initWithDictionary:[File readFile:
                                                                                 [NSString stringWithFormat:@"%@.%@",username,kInstalledProfiles]]];
            // create an empty profile if no saved file existed
            if (!installedProfiles)
                installedProfiles = [NSMutableDictionary dictionary];
        }else{
            //If there is no profile check, in case user has logged in
            if ([installedProfiles count] < 1) {
                installedProfiles = [[NSMutableDictionary alloc] initWithDictionary:[File readFile:
                                                                                     [NSString stringWithFormat:@"%@.%@",username,kInstalledProfiles]]];
            }
            
            // create an empty profile if no saved file existed - is this needed??
            
            installedProfiles = [NSMutableDictionary dictionaryWithDictionary:installedProfiles];
        }
        
        // Declare the selected Launchpad profile
        NSMutableDictionary* profile = [self getCurrentProfile];
        
        // If no profile is available, do nothing
        if (!profile)
            return;
        
        // if profile is invalid then warn user
        NSMutableDictionary *messagePayload = [profile objectForKey:kStudioMessagePayloadKey];
        if (messagePayload)
        {
            NSNumber *messageSuccess = [messagePayload objectForKey:kStudioMessagePayloadSuccessKey];
            // is this a response to user login via studio
            if ([messageSuccess isEqualToNumber:[NSNumber numberWithInt:0]])
            {
                // failed to load profile
                //NSString *messageString = [messagePayload objectForKey:kStudioMessageStringKey];
                
                // Fire the profile invalid event
                cCenter.state = CC_PROFILE_INVALID;

            }
            return;
        }
        
        // Add the base URL of the profile manager to the profile for reference 
        [profile setValue:launchpadServiceUrl forKey:kProfileLaunchpadServiceUrlKey];
        
        // Fire the building event
        cCenter.state = CC_BUILDING_MENU;
        
        // Apply the profile
        [MenuCommands get].launchpadProfile = profile;
        
        // get profile Info $HURSH$ Maybe able to take this code out....
        NSMutableDictionary *profileInfo = [profile objectForKey:kProfileInfoKey];
        // get profile Id
        NSString* profileIdStr = [profileInfo objectForKey:kProfileIdKey];
        
        if(profileIdStr){
            [installedProfiles setObject:profile forKey:profileIdStr];
        }

        /*
         // TODO: Sort profiles by name
         NSMutableDictionary* installedProfiles2 = [NSMutableDictionary dictionaryWithDictionary:installedProfiles];
         [[installedProfiles2 allKeys] sortedArrayUsingSelector:;
         NSArray *sortedArray = [installedProfiles2 sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
         */
        
        [self generateUninstalledProfilesDictionary];
        
        // Fire the complete event
        cCenter.state = CC_MENU_COMPLETE;
        
    });
}
-(BOOL)loadSavedProfileList:(NSString *)username{
    
    if (![File checkFileExists:[File getFilePath:[NSString stringWithFormat:@"%@.%@",username,kUnInstalledProfiles]]]) {
        return NO;
    }
    
    uninstalledProfiles = [[NSMutableDictionary alloc] initWithDictionary:[File readFile:
                                                                           [NSString stringWithFormat:@"%@.%@",username,kUnInstalledProfiles]]];
    //Will always return instantiated Object-even if empty which is possible
    return YES;
}
- (void) loadSavedProfiles:(NSString *)username{
    installedProfiles = [[NSMutableDictionary alloc] initWithDictionary:[File readFile:
                                                                         [NSString stringWithFormat:@"%@.%@",username,kInstalledProfiles]]];

}

/*
 * Login - authenticates user through profile manager
 */
- (void)loginUsername:(NSString*)username password:(NSString*)password response:(FHLoginResponse)response {
    
    // Login Authentication with new Framehawk Studio
    NSURL* u = [NSURL URLWithString:[NSString stringWithFormat:@"%@/authenticate", launchpadServiceUrl]];
    
    // get version from settings
    NSString* versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    // authentication login information
    NSDictionary *loginInfo = [[NSDictionary alloc] initWithObjectsAndKeys:kStudioLoginRequest, kStudioMessageTypeKey,
                               username, kStudioUserIdKey,
                               password, kStudioPasswordKey,
                               versionString, kStudioBuildVersionKey,
                               nil];
    // convert login info to JSON data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:loginInfo
                                                       options:NSJSONWritingPrettyPrinted error:nil];
    // create login info JSON string
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // set up login authentication request parameters
    NSMutableURLRequest* r = [[NSMutableURLRequest alloc] initWithURL:u];
    [r setHTTPMethod:@"POST"];
    [r setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    NSString* jString = [NSString stringWithFormat:@"%@", jsonString];
    [r setHTTPBody:[jString dataUsingEncoding:NSUTF8StringEncoding]];
    
    self.loginResponse = response;
    
    // connect for authentication
    NSURLConnection* c;
    c = [[NSURLConnection alloc] initWithRequest:r delegate:self startImmediately:YES];
    c = c; /* This prevents the 'unused' warning from the compiler, which is unneeded here */
    
}

/*
 * Get current profile
 */
-(NSMutableDictionary*)getCurrentProfile
{
    NSMutableDictionary* profile = nil;
    
    // Check user preferences
    NSString* defaultProfileId = [SettingsUtils getDefaultProfileId];
    NSString* selectedProfileId = [SettingsUtils getSelectedProfileId];
    
    
    // If the default profile matches the user's current selection...
    if (defaultProfileId && selectedProfileId && [defaultProfileId integerValue] == [selectedProfileId integerValue])
        // ...Check for the default profile
        profile = [installedProfiles objectForKey:defaultProfileId];
    
    
    // If a default profile was not found and a profile is selected...
    if (!profile && selectedProfileId) {
        // ...Check downloaded profiles for the selected profile identifier
        profile = [installedProfiles objectForKey:selectedProfileId];
        
        // Otherwise since the profile has not previously been downloaded...
        if (!profile) {
            // ...Download the selected profile from the remote service
            NSURL* u = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", launchpadServiceUrl, [NSString stringWithFormat:kFramehawkGetProfile, selectedProfileId]]];
            
            NSData* jsonProfile = [NSData dataWithContentsOfURL:u];
            
            if(jsonProfile)// && [NSJSONSerialization isValidJSONObject:jsonProfile])
            {
                profile = [NSJSONSerialization JSONObjectWithData:jsonProfile options:NSJSONReadingMutableContainers error:nil];
                // Save round trip on async calls to getCurrentProfile
                //if (installedProfiles && ![installedProfiles objectForKey:selectedProfileId]) {
                //    [installedProfiles setObject:profile forKey:selectedProfileId];
                //}
            }
        }
    }
    return profile;
}

/*
 * Get Current Profile - gets current profile
 */
- (void)getCurrentProfile:(FHGetProfileResponse)response {
/* TODO:
    
    // Get Profile from the Framehawk Studio
    NSURL* u = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", launchpadServiceUrl, kFramehawkGetProfile]];
    
    // get profile
    NSDictionary *getProfileInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                     kStudioGetProfileRequest, kStudioMessageTypeKey,
                                     kStudioGetProfileId, kProfileIdKey,
                                     sessionId, kStudioSessionIdKey,
                                     nil];
    
    // convert get profile to JSON data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:getProfileInfo
                                                       options:NSJSONReadingMutableContainers error:nil];
    // create get profile request into JSON string
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // set up login authentication request parameters
    NSMutableURLRequest* r = [[NSMutableURLRequest alloc] initWithURL:u];
    [r setHTTPMethod:@"POST"];
    [r setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    [r setHTTPBody:[[NSString stringWithFormat:jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // set up response
    self.getProfilesListResponse = response;
    
    // connect for authentication
    NSURLConnection* c;
    c = [[NSURLConnection alloc] initWithRequest:r delegate:self startImmediately:YES];
    
    c = c; // This prevents the 'unused' warning from the compiler, which is unneeded here
*/
}


/*
 * Get Profiles List - gets users list of profiles through profile manager
 */
- (void)getProfilesList:(FHGetProfilesListResponse)response {
    
    // Get Profiles list from the Framehawk Studio
    NSURL* u = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", launchpadServiceUrl, kFramehawkGetProfilesList]];

    // get profiles list information
    NSDictionary *getProfilesListInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 kStudioGetProfilesListRequest, kStudioMessageTypeKey,
                                 nil];

    // convert get profiles list to JSON data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:getProfilesListInfo 
                                               options:NSJSONReadingMutableContainers error:nil];
    // create get profiles list JSON string
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    // set up get profiles request parameters
    NSMutableURLRequest* r = [[NSMutableURLRequest alloc] initWithURL:u];
    [r setHTTPMethod:@"POST"];
    [r setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    NSString* jString = [NSString stringWithFormat:@"%@", jsonString];
    [r setHTTPBody:[jString dataUsingEncoding:NSUTF8StringEncoding]];

    // set up get profiles list response
    self.getProfilesListResponse = response;
    
    // connect for getting profiles list
    NSURLConnection* c;
    c = [[NSURLConnection alloc] initWithRequest:r delegate:self startImmediately:YES];

    c = c; /* This prevents the 'unused' warning from the compiler, which is unneeded here */

}

/*
 * Clean up installed profiles
 * removing any old profiles that are obsolete
 */
-(void)cleanupInstalledProfiles
{
    NSEnumerator *keyEnumerator = [installedProfiles keyEnumerator];
    id key;
    NSMutableArray* keysToRemove = [[NSMutableArray alloc] init];    
    
    // Clean up any obsolete profiles
    while ((key = [keyEnumerator nextObject])) {
        /* code that uses the returned key */
        // get button groups from current profile information
        NSDictionary* profile = [installedProfiles objectForKey:key];
        
        // is this profile an old profile?
        if ([profile objectForKey:kProfileInfoKey]==nil)
        {
            // get profile Name
            DLog(@"++++++ Remove Profile:%@\n", [profile objectForKey:kProfileNameKey]);
            [keysToRemove addObject:key];
        }
    }
    // remove any incompatible profiles
    [installedProfiles removeObjectsForKeys:keysToRemove];
    
}

/*
 * Delete installed profiles
 */
-(void)deleteInstalledProfiles {
    // Delete existing set of downloaded profiles from Keychain if applicable
    /*CFDictionaryRef query = [self prepareKeychainQueryForDeleteProfiles];
    SecItemDelete(query);
    CFRelease(CFRetain(query));
     */
    [installedProfiles removeAllObjects];
}

/*
 * Delete uninstalled profiles
 */
-(void)deleteUnInstalledProfiles {
    // Delete existing set of downloaded profiles from Keychain if applicable
    /*CFDictionaryRef query = [self prepareKeychainQueryForDeleteProfiles];
     SecItemDelete(query);
     CFRelease(CFRetain(query));
     */
    [uninstalledProfiles removeAllObjects];
}

/*
 * Save installed profiles
 */
-(void)saveInstalledProfiles {
    
    // there may be instances where installed profiles are zero if a profile was deleted - so still save
//    if ([installedProfiles count]>0)
    {
        // load username from settings
        NSString* username = [SettingsUtils getCurrentUserID];

        if (username){
            [File writeFile:installedProfiles fileName:[NSString stringWithFormat:@"%@.%@",username,kInstalledProfiles]];
            
            //[File writeFile:uninstalledProfiles fileName:[NSString stringWithFormat:@"%@.%@",username,kUnInstalledProfiles]];
            //New requirement don't save library list of profiles
        }
    }
    
    // Delete existing set of downloaded profiles from Keychain if applicable
    //    [self deleteInstalledProfiles];
    
    
    /*
    CFDictionaryRef query = [self prepareKeychainQueryForDeleteProfiles];
    SecItemDelete(query);
    CFRelease(CFRetain(query));
    
    // Store the set of downloaded profiles to the keychain
    //    CFDictionaryRef 
    query = CFRetain([self prepareKeychainQueryForStoreProfiles]);
    CFTypeRef results = NULL;
    SecItemAdd(query, &results);
    
    CFRelease(query);
    */
    [self generateUninstalledProfilesDictionary];
}


/*
 * Generate dictionary of uninstalled profiles
 */
-(void)generateUninstalledProfilesDictionary
{
    
    // Create list of uninstalled profiles
    if (uninstalledProfiles) {
        [uninstalledProfiles removeAllObjects];
    }else{
        uninstalledProfiles = [[NSMutableDictionary alloc] init];
    }
    
    // Declare the selected Launchpad profile
    NSDictionary* profile;
    
    // If displaying library profiles...
    for (int index=0; index<[templates count]; index++)
    {
        //get profile at current index
        profile = [templates objectAtIndex:index];
        NSString* pidStr = nil;
        pidStr = [profile objectForKey:kProfileIdKey];
        if (![installedProfiles objectForKey:pidStr])
        {  
            // add profile to list of uninstalled profiles
            [uninstalledProfiles setObject:profile forKey:pidStr];
        }
    }
    cCenter.state = CC_GENERATED_PROFILE_LIST;
}


#pragma mark -
#pragma mark NSURLConnectionDelegate Implementation


- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    if (self.loginResponse) {
        self.loginResponse(nil, error);
        self.loginResponse = nil;
    }
    
    if (self.getProfilesListResponse) {
        self.getProfilesListResponse(nil, error);
        self.getProfilesListResponse = nil;
    }
}



#pragma mark -
#pragma mark NSURLConnectionDataDelegate Implementation
#if 1
/*
 * canAuthenticateAgainstProtectionSpace
 *
 * This allows the delegate to analyze properties of the server, including its protocol and authentication method, before attempting to authenticate against it.
 *
 * return TRUE triggers connection:didReceiveAuthenticationChallenge call
 */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

/*
 * didReceiveAuthenticationChallenge
 *
 * Handles Authentication Challenge:
 *
 * Can either:
 * - Provide authentication credentials
 * - Attempt to continue without credentials
 * - Cancel the authentication challenge
 *
 */
- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
#ifdef DEBUG_AC
	NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
#endif
	
	NSURLCredential* c = nil;
	if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust] /*&&(acceptUnknownCA)*/)
	{   // trust unknown certificate
		c = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
	}
	if (c == nil && [challenge previousFailureCount] < 2) 
	{
        // authenticate with user credentials
        //c = [NSURLCredential credentialWithUser:proxyUsername password:proxyPassword persistence:NSURLCredentialPersistenceNone];
	}
	if (c != nil) 
	{
		[[challenge sender] useCredential:c forAuthenticationChallenge:challenge];
	}
	else 
	{
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}
#endif

/*
 * Handle connection receiving data response
 */
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    DLog(@"++++++ connection didReceiveData");
    
    if(data)// && [NSJSONSerialization isValidJSONObject:data])
    {
        NSError *errorJSON;
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorJSON];
        DLog(@"JSON didReceiveData Error%@ : Reason:%@", [errorJSON localizedDescription], [errorJSON localizedFailureReason]);
        
        DLog(@"Response:");
        for( NSString *aKey in [response allKeys] )
        {
            // do something like a log:
            DLog(@"%@ = %@", aKey, [response objectForKey:aKey]);
        }
        
        NSString *messageType = [response objectForKey:kStudioMessageTypeKey];
        if (messageType)
        {
            // is this a response to user login via studio
            if ([messageType compare:kStudioLoginResponse]==NSOrderedSame)
            {
                DLog(@"++++++ Login Response!\n");
                // get session id
                sessionId = [response valueForKey:kStudioSessionIdKey];
                // respond to login
                if (nil!=self.loginResponse)
                {
                    // respond to login
                    self.loginResponse(response, nil);
                    self.loginResponse = nil;
                }
            }
            else if ([messageType compare:kStudioGetProfilesListResponse]==NSOrderedSame)
            {   // is this a resonse to get list of profiles
                // respond to profiles
                DLog(@"++++++ Get Profiles List Response!\n");
                if (nil!=self.getProfilesListResponse)
                {
                    // respond to get profiles list
                    self.getProfilesListResponse(data, nil);
                    self.getProfilesListResponse = nil;
                }
            }
            else
            {
                DLog(@"++++++ Unknown Message Type!\n");
                // handle any invalid responses
                [self handleInvalidResponse:data withError:nil];
            }
        }
        else
        {
            DLog(@"++++++ Message TypeDLOG NOT FOUND! %@\n",[errorJSON description]);
            // handle any invalid responses
            [self handleInvalidResponse:data withError:nil];
        }
    }
}


/*
 * Handle invalid repsonse from general connection
 */
- (void)handleInvalidResponse:(NSData*)data withError:(NSError*)error {

    // is there a login response waiting?
    if (nil!=self.loginResponse)
    {
        self.loginResponse(nil, error);
        self.loginResponse = nil;
    }
    else if (nil!=self.getProfilesListResponse) // is there a get profiles response waiting?
    {
        self.getProfilesListResponse(nil, error);
        self.getProfilesListResponse = nil;
    }
}


#pragma mark -
#pragma mark CommandCenter () Implementation


/*
 * Load installed profiles
 */
- (void) loadInstalledProfiles {
// TODO: No longer used
/*    CFDictionaryRef query = [self prepareKeychainQueryForLoadProfiles];
    CFTypeRef results = NULL;
    OSStatus result = SecItemCopyMatching(query, &results);
    
    if (result == errSecSuccess) {
        CFArrayRef resultsArray = (CFArrayRef)results;
        CFDictionaryRef attributes =  CFArrayGetValueAtIndex(resultsArray, 0);
        NSString* profilesJson = (__bridge_transfer NSString*)CFDictionaryGetValue(attributes, kSecAttrGeneric);
        NSData* profilesJsonData = [profilesJson dataUsingEncoding:NSUTF8StringEncoding];
        
        if(profilesJsonData)// && [NSJSONSerialization isValidJSONObject:profilesJsonData])
        {
            installedProfiles = [NSJSONSerialization JSONObjectWithData:profilesJsonData options:NSJSONReadingMutableContainers error:nil];
        }
        // clean up installed profiles
        //[self cleanupInstalledProfiles];
        
        // generate uninstalled profiles list
        [self generateUninstalledProfilesDictionary];
    
        //CFRelease(results);
    }

     */
}


- (CFDictionaryRef)prepareKeychainQueryForDeleteProfiles {
    // Prepare keychain 'delete' query
    CFMutableDictionaryRef result = (__bridge CFMutableDictionaryRef)[NSMutableDictionary dictionary];
    // - KEYCHAIN ITEM CLASS: Generic password
    CFDictionarySetValue(result, kSecClass, kSecClassGenericPassword);
    // - KEYCHAIN ITEM 'ACCOUNT' ATTRIBUTE
    CFDictionarySetValue(result, kSecAttrAccount, @"FramehawkLaunchpadProfiles");
    // - KEYCHAIN SEARCH RESULT OPTIONS: Return attributes as dictionary
    CFDictionarySetValue(result, kSecReturnAttributes, kCFBooleanTrue);
    
    return result;
}


- (CFDictionaryRef)prepareKeychainQueryForLoadProfiles {
    // Prepare keychain 'search' query
    CFMutableDictionaryRef result = (__bridge CFMutableDictionaryRef)[NSMutableDictionary dictionary];
    // - KEYCHAIN ITEM CLASS: Generic password
    CFDictionarySetValue(result, kSecClass, kSecClassGenericPassword);
    // - KEYCHAIN ITEM 'ACCOUNT' ATTRIBUTE
    CFDictionarySetValue(result, kSecAttrAccount, @"FramehawkLaunchpadProfiles");
    // - KEYCHAIN SEARCH RESULT OPTIONS: Return 'all' results
    CFDictionarySetValue(result, kSecMatchLimit, kSecMatchLimitAll);
    // - KEYCHAIN SEARCH RESULT OPTIONS: Return attributes as dictionary
    CFDictionarySetValue(result, kSecReturnAttributes, kCFBooleanTrue);
    
    return result;
}


-(void) parseDictionary:(NSDictionary *)dict
{
    for (id key in dict) {
        NSObject* object = [dict objectForKey:key];
        BOOL bIsDictionary = [object isKindOfClass:[NSDictionary class]];
        BOOL bIsArray = [object isKindOfClass:[NSArray class]];
        if (bIsDictionary)
        {
            DLog(@"Dictionary key: %@", key);
            [self parseDictionary:(NSDictionary*)object];
        }
        else if (bIsArray)
        {
            DLog(@"Array key: %@", key);
            for (NSUInteger i = 0, l = [(NSArray *)object count]; (i < l) ; i++)
            {
                NSObject* arrayObj = [(NSArray *)object objectAtIndex:i];
                BOOL bArrayObjIsDictionary = [arrayObj isKindOfClass:[NSDictionary class]];
                if (bArrayObjIsDictionary)
                {
                    [self parseDictionary:(NSDictionary*)arrayObj];
                }
                else
                {
                    DLog(@"Array obj: %d", i);
                }
            }
        }
        else
            DLog(@"key: %@, value: %@", key, [dict objectForKey:key]);
    }
}

- (CFDictionaryRef)prepareKeychainQueryForStoreProfiles {
    // Prepare keychain 'add' query
    CFMutableDictionaryRef result = (__bridge CFMutableDictionaryRef)[NSMutableDictionary dictionary];
    // - KEYCHAIN ITEM CLASS: Generic password
    CFDictionarySetValue(result, kSecClass, kSecClassGenericPassword);
    // - KEYCHAIN ITEM 'ACCOUNT' ATTRIBUTE
    CFDictionarySetValue(result, kSecAttrAccount, @"FramehawkLaunchpadProfiles");
    // - KEYCHAIN ITEM 'GENERIC' ATTRIBUTE
    
    // Test code to check validity of JSON object
    if (0)
    {   
        //assert([NSJSONSerialization isValidJSONObject:installedProfiles]);
        DLog(@"\n\n>>>>>>>>>>>>>>>>\n\n");
        NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:installedProfiles];
        [self parseDictionary:dict];
        //assert([NSJSONSerialization isValidJSONObject:dict]);
    }
    
    if(installedProfiles && [NSJSONSerialization isValidJSONObject:installedProfiles])
    {
        NSData* profilesJsonData =[NSJSONSerialization dataWithJSONObject:installedProfiles options:NSJSONWritingPrettyPrinted error:nil];
        NSString* profilesJson = [[NSString alloc] initWithData:profilesJsonData encoding:NSUTF8StringEncoding];
        CFDictionarySetValue(result, kSecAttrGeneric, (__bridge CFStringRef)profilesJson);
        // - KEYCHAIN SEARCH RESULT OPTIONS: Return attributes as dictionary
        CFDictionarySetValue(result, kSecReturnAttributes, kCFBooleanTrue);
    }
    
    return result;
}
+ (BOOL)networkIsAvailable
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr*)(&zeroAddress));
    BOOL internetIsReachable = NO;
    if (reachability)
    {
        SCNetworkReachabilityFlags flags = 0;
        if (SCNetworkReachabilityGetFlags(reachability, &flags))
        {
            //if reachability flag is 0, connection is not reachable
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
                internetIsReachable = NO;
            else
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
                    internetIsReachable = YES;
                
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                     (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
                    // ... and no [user] intervention is needed
                    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                        internetIsReachable = YES;
                
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
                    internetIsReachable = YES;
            }
        }
        CFRelease(reachability);
    }
    
    return internetIsReachable;
}

@end