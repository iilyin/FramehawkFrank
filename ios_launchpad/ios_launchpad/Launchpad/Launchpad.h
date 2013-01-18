/*
 *  Launchpad.h
 *  Launchpad
 *
 *  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
 */


#ifndef Launchpad_Launchpad_h
#define Launchpad_Launchpad_h


typedef void (^FHLoginResponse)(NSDictionary*, NSError*);
typedef void (^FHGetProfilesListResponse)(NSData*, NSError*);
typedef void (^FHGetProfileResponse)(NSData*, NSError*);

#if PRODUCTION
    #define LAUNCHPAD_SERVICE_URL @"https://studio.framehawk.com"
#elif DEVELOPMENT
    #define LAUNCHPAD_SERVICE_URL @"https://studio-staging.framehawk.com"
#endif
extern NSString* launchpadServiceUrl;

#endif