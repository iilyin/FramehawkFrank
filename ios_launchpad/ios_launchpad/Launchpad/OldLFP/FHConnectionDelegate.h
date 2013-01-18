/**
 * @file
 * FHConnectionDelegate.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.0.0.11799  Built: Thu Nov  1 08:36:16 PDT 2012
 *
 * This class handles notification callbacks from the connection. 
 *
 * @brief Framehawk Connection Delegate.
 */

#ifndef __FH_CONNECTION_DELEGATE_H
#define __FH_CONNECTION_DELEGATE_H

#import "FHDefines.h"

#ifndef COMPAT_15_MODE

@class FHConnection;

/**
 * Framehawk Connection Delegate.
 */
@protocol FHConnectionDelegate <NSObject>


@optional
/**
 * Signals the receipt of the first full frame of image data from the service.
 */
-(void)firstRenderReceived:(FHConnection*)connection;

/**
 * Called to confirm the connection supports the required feature flags (see FHDefines.h).
 * This must return TRUE for a connection to complete.
 */
-(BOOL)confirmConnectionFeatureFlags:(FHConnection*)connection withFeatureFlags:(connectionFeatureFlags)featureFlags;

/**
 * Called when there is any change in connection status.
 */
-(void)connectionStatusChange:(FHConnection*)connection toState:(connectionStates)state withMessage:(NSString*)message;

/**
 * Called when user data channel messages are received.
 */
-(void)receivedDataChannelMessage:(FHConnection*)connection withData:(NSData*)data;

/**
 * Called when a complete user data channel message has been received.
 */
-(void)dataChannelFlushed:(FHConnection*)connection;

// Keyboard pop - experimental
-(void)showKeyboard:(FHConnection*)connection;
-(void)hideKeyboard:(FHConnection*)connection;

@end

#endif //COMPAT_15_MODE

#endif //__FH_CONNECTION_DELEGATE_H




