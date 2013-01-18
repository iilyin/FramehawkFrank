//
//  FHBroker.h
//
//  Copyright 2011 Framehawk, Inc. All rights reserved.
//
#ifndef __FH_BROKER_H
#define __FH_BROKER_H

#import <Foundation/Foundation.h>
#include "FHDefines.h"
#import "FHBrokerOptions.h"
#import "FHServiceAuth.h"

#define COMPAT_15_MODE

@protocol FHConnection;
@class FHBrokerReader;
@class FHServiceAuth;
@class FHRCReader;

#define connectionAttributes connectionFeatureFlags


typedef enum serviceAuthenticationOptions
{kNoAuthenticationOptions = 0x00, kAuthUsernameRequired = 0x01, kAuthPasswordRequired = 0x02, kAuthExtTokenRequired = 0x04, kAuthTokenResync=0x08} serviceAuthenticationOptions;

//@protocol FHConnectionDelegate;
@class FHUIView;
@class UIImage;
@protocol FHBrokerOptions;
@protocol FHStatistics;

@protocol FHConnection;

@protocol FHConnectionDelegate <NSObject>

@optional
// signals the completion of the first frame
-(void)firstRenderReceived:(id<FHConnection>)connection;

// called for any change in click response status
-(void)clickResponseStatusChange:(id<FHConnection>)connection withClickResponse:(int)clickResponse;

// called when a connection challenge is received
-(void)connectionAuthenticationChallenge:(id<FHConnection>)connection withTypes:(serviceAuthenticationOptions)authOptions;

// called to confirm the connection supports the required attributes
-(BOOL)confirmConnectionAttributes:(id<FHConnection>)connection withAttributes:(connectionAttributes)attributes;

// called for any change in connection status
-(void)connectionStatusChange:(id<FHConnection>)connection toState:(connectionStates)state withMessage:(NSString*)message;

// callback when data channel data is received
-(void)receivedDataChannelMessage:(id<FHConnection>)connection withData:(NSData*)data;

// callback when data channel is flushed
-(void)dataChannelFlushed:(id<FHConnection>)connection;

@end



@protocol FHConnection <NSObject>

@property (nonatomic, assign) FHUIView* view;
@property BOOL killOnExit;
@property (readonly) NSString* clientVersion;
@property (readonly) NSString* serverVersion;
@property (readonly) NSString* serverAddress;
@property (assign) id<FHConnectionDelegate> delegate;
@property (assign) CGRect requestedBuffer;
@property (readonly) CGRect actualBuffer;
@property BOOL debugRectangles;
@property (assign) UIImage* splashImage;
@property (assign) NSString* cbCookie;
@property (readonly) BOOL running;
@property (readonly) BOOL bkMode;
@property (assign) id<FHBrokerOptions> options;
@property (assign) NSDictionary* customHeaders;


- (id<FHStatistics>)statistics;

/*
 Init, start, stop, pause and restart methods.
 
 Call init before start to perform the handshake and initialize the connection before starting.
 Alternatively will be called at start by default.
 */
- (BOOL) initConnection;
//  start the connection. Call after a succesful init, or after pause to restart the connection.
- (BOOL) startConnection;
// stop and disconnect
- (void) stopConnection;
// stop rendering, but maintain the network connection
- (void) pauseConnection;

/*
 Mouse and keyboard messages
 */
// key press = send a key down followed by a key up message
- (void) sendKeyPressedMessage:(int)keyId modifier:(int) keyMod;
- (void) sendKeyUpMessage:(int)keyId modifier:(int) keyMod;
- (void) sendKeyDownMessage:(int)keyId modifier:(int) keyMod;

// mouse position = move the mouse cursor
- (void) sendMousePositionMessage:(int)xPos yPos:(int)yPos;
- (void) sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos;

//mouse click = mouse down followed by a mouse up
- (void) sendMouseClickMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;
- (void) sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;
- (void) sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

// mouse scroll wheel message
- (void) sendMouseScrollMessage:(int)xPos yPos:(int)yPos delta:(int)delta;

// Data channel messages
- (void) sendDataChannelData:(NSData*)data;
- (void) flushDataChannel;

//Read the value of a pixel at a given point
-(int)getPixelAtPoint:(int)x y:(int)y;

/**
 * Used to grab a screen snapshot.
 */
#ifdef __APPLE__
- (CGImageRef) copyCGImage;
#if !TARGET_OS_IPHONE
-(NSImage*)copyNSImage;
#endif
#endif

#if TARGET_OS_IPHONE
- (UIImage*) copyImage;
#endif

#if TARGET_OS_IPHONE
- (UIImage*) captureImage;
#endif
@end

/*
 Access to a server through a broker service.
 
 Authenticate to a broker, which returns a list of available servers. Servers are referenced
 by the index of the server entry in the returned list.
 */
@interface FHBroker : NSObject <FHBrokerOptions, FHServiceAuth>
{
    FHBrokerReader* br;
    FHRCReader *rcr;
    BOOL acceptUnknownCA;
    NSString *proxyUsername, *proxyPassword;
    NSArray* entries;
    NSString *address, *username, *password, *authtoken;
    BOOL isRelayController;
    BOOL resync;
    NSDictionary* XAuthResyncData;
}

@property BOOL acceptUnknownCA;
@property (retain) NSString *proxyUsername;
@property (retain) NSString *proxyPassword;

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *authToken;
@property (retain) NSDictionary* XAuthResyncData;
@property BOOL resync;


// Create a broker object at the server given in address with specified credentials 
- (id) initWithServer:(NSString*)address andUser:(NSString*)username andPass:(NSString*)pass andHeaders:(NSDictionary*)customHeaders;

// Create a broker object with the relay controller given in address with specified credentials 
- (id) initWithRelayController:(NSString*)address  andUser:(NSString*)username andPass:(NSString*)pass andHeaders:(NSDictionary*)customHeaders;

// return a list of servers to which the user has access
- (NSArray*) getServerList;

// as above, but optionally returns an error
- (NSArray*) getServerList:(NSError**)error;

// connect to a server - entry is the index of the server in the list returned above.
// attributes contains server features requested (eg audio).
// secure = use relay controller
- (id<FHConnection>) connectToServerEntry:(unsigned int)entry withAttributes:(connectionFeatureFlags)attributes andAuth:(id<FHServiceAuth>)auth securely:(BOOL)sec;
- (id<FHConnection>) connectToServerEntry:(unsigned int)entry withAttributes:(connectionFeatureFlags)attributes andAuth:(id<FHServiceAuth>)auth securely:(BOOL)sec andHeaders:(NSDictionary*) headers;
- (id<FHConnection>) connectToServerEntry:(unsigned int)entry withAttributes:(connectionFeatureFlags)attributes;


@end

#endif //__FH_BROKER_H


