//
//  KeychainDefaults.h
//  GoogleNews
//
//  Created by Ivan Ilyin on 21.02.12.
//  Copyright (c) 2012 Exadel, Inc. All rights reserved.
//

#ifndef GoogleNews_KeychainDefaults_h
#define GoogleNews_KeychainDefaults_h

/*
 keychain identifiers
*/

//access group id
#ifdef DEBUG
#define kFramehawkGroup         @"58ABUY26L6.com.framehawk"
#else
#define kFramehawkGroup         @"JP83T22LXS.com.framehawk"
#endif
//license accept key
#define kFramehawkLicenseID     @"accepteula"
//user id key
#define kFramehawkUserID        @"serviceuser"
//user password key
#define kFramehawkUserPassword  @"servicepassword"
//service parameters key
#define kFramehawkServiceParameters    @"serviceparameters"

#define kFHServiceURL           @"FramehawkMDS"
#define kFHServiceID            @"FramehawkServiceID"
#define kFHServiceRegion        @"FramehawkRegion"

#endif
