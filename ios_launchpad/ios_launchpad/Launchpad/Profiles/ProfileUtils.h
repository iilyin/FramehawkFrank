//
//  ProfileUtils.h
//  Launchpad
//
//  Utility methods for accessing information from a profile.
//
//  Copyright (c) 2012 Framehawk Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProfileUtils : NSObject

/*
 * Get total number of services in a given profile
 */
+ (int)getTotalServicesInProfile:(NSMutableDictionary*)theProfile;

/*
 * Get number of applications from current profile in specified group section
 */
+ (NSInteger) getApplicationCountForProfile:(NSMutableDictionary*)theProfile inSection:(NSInteger) section;

/*
 * Get number of application groups for specified profile
 */
+ (NSInteger) getGroupsCountForProfile:(NSMutableDictionary*)theProfile;

/*
 * Get application information for profile at given index in specified group
 */
+(NSDictionary*) getApplicationInformationForProfile:(NSMutableDictionary*)theProfile inGroup:(NSInteger) groupIndex atIndex:(NSInteger) serviceIndex;

/*
 * Get application information at specified index for given profile
 */
+(NSDictionary*) getApplicationInformationForProfile:(NSMutableDictionary*)theProfile withIndex:(NSInteger) index;

/*
 * Get application name for profile at given index in specified group
 */
+ (NSString*) getApplicationNameForProfile:(NSMutableDictionary*)theProfile withIndex:(NSInteger) index;

/*
 * Get application name given profile at specified index
 */
+(NSString*) getApplicationNameForProfile:(NSMutableDictionary*)theProfile withIndex:(NSInteger) index;

@end
