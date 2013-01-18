//
//  ProfileStorageManagement.h
//  Launchpad
//
//  Created by Hursh Prasad on 8/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//  

#import <Foundation/Foundation.h>
#import "File.h"

@interface ProfileStorageManagement
+(void)storeProfile:(NSNumber *)profileId;
+(void)deleteProfile:(NSString *)profileId;
@end