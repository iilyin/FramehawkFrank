//
//  ProfileUtils.h
//  Launchpad
//
//  Utility methods for accessing information from a profile.
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import "ProfileUtils.h"
#import "ProfileDefines.h"
#import "SettingsUtils.h"
#import "GlobalDefines.h"

@implementation ProfileUtils

/*
 * Get total number of services in a given profile
 */
+ (int)getTotalServicesInProfile:(NSMutableDictionary*)theProfile
{
    // set total services to 0
    int totalServicesInProfile = 0;
    
    // if profile exists then obtain total services within profile
    if (nil!=theProfile)
    {
        // get total groups in profile
        int totalGroupsInProfile = [self getGroupsCountForProfile:theProfile];
        
        // parse profile groups for services
        for (int group=0; group<totalGroupsInProfile; group++)
        {
            // get total application services in this group
            int applicationsInGroup = [self getApplicationCountForProfile:theProfile inSection:group];
            // add number of application services to total services
            totalServicesInProfile += applicationsInGroup;
        }
        
    }
    
    // return total services in the given profile
    return totalServicesInProfile;
}


/*
 * Get number of applications from current profile in specified group section
 */
+(NSInteger) getApplicationCountForProfile:(NSMutableDictionary*)theProfile inSection:(NSInteger) section
{
    NSArray* bgroups = [theProfile objectForKey:kProfileButtonGroupsKey];
    NSDictionary* d = [bgroups objectAtIndex:section];
    NSArray* bs = [d objectForKey:kProfileButtonsKey];
    return  [bs count];
}


/*
 * Get number of application groups for specified profile
 */
+(NSInteger) getGroupsCountForProfile:(NSMutableDictionary*)theProfile
{
    NSArray* bgroups = [theProfile objectForKey:kProfileButtonGroupsKey];
    return  [bgroups count];
}

/*
 * Get application information for profile at given index in specified group
 */
+(NSDictionary*) getApplicationInformationForProfile:(NSMutableDictionary*)theProfile inGroup:(NSInteger) groupIndex atIndex:(NSInteger) serviceIndex
{
    NSArray* bgroups = [theProfile objectForKey:kProfileButtonGroupsKey];
    NSDictionary* d = [bgroups objectAtIndex:groupIndex];
    NSArray* bs = [d objectForKey:kProfileButtonsKey];
    NSMutableDictionary* applicationInfo = [bs objectAtIndex:serviceIndex];

    // get user id
    NSString* profileUserId = [SettingsUtils getCurrentUserID];
    // get profile info
    NSDictionary* pInfo = [theProfile objectForKey:kProfileInfoKey];
    // get profile identifier
    NSString* pid = [pInfo objectForKey:kProfileIdKey];
    // get application name information
    NSString *aName = [applicationInfo objectForKey:kProfileServiceLabelKey];
    // get Login Assistant setting for this application from settings
    BOOL bLoginAssistantEnabled = [SettingsUtils loadLoginAssistantEnabledSettingForUserId:profileUserId profileId:pid appName:aName];
  
    // set login assistant enabled setting for service application information
    [applicationInfo setObject:(bLoginAssistantEnabled ? sSettingsBoolTrue : sSettingsBoolFalse) forKey:kProfileServiceLoginAssistantToggleKey];
    
    // return service application information
    return applicationInfo;
}

/*
 * Get application information at specified index for given profile 
 */
+(NSDictionary*) getApplicationInformationForProfile:(NSMutableDictionary*)theProfile withIndex:(NSInteger) index
{
    int currentGroup = 0;
    
    // extract application name at specified index
    while (index>=[self getApplicationCountForProfile:theProfile inSection:currentGroup])
    {
        index -= [self getApplicationCountForProfile:theProfile inSection:currentGroup];
        // move on to next group
        currentGroup++;
    }
    
    // get application information at current index in current group
    return [self getApplicationInformationForProfile:theProfile inGroup:currentGroup atIndex:index];
}


/*
 * Get application name for profile at given index in specified group
 */
+(NSString*) getApplicationNameForProfile:(NSMutableDictionary*)theProfile inGroup:(NSInteger) groupIndex atIndex:(NSInteger) serviceIndex
{
    // get application information for specified service at index in group
    return [[self getApplicationInformationForProfile:theProfile inGroup:groupIndex atIndex:serviceIndex] objectForKey:kProfileServiceLabelKey];
}


/*
 * Get application name given profile at specified index
 */
+(NSString*) getApplicationNameForProfile:(NSMutableDictionary*)theProfile withIndex:(NSInteger) index
{
    NSString* applicationNameString;
    
    // get application name string for service at specified index in profile
    applicationNameString = [[self getApplicationInformationForProfile:theProfile withIndex:index] objectForKey:kProfileServiceLabelKey];
    
    return  applicationNameString;
}


@end
