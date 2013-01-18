/**
 * @file
 * FHConnection.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.1.2.12317  Built: Wed Nov 21 09:06:10 PST 2012
 *
 * Interface for creating and managing a session (i.e. connection to a service).
 * A service is an application provided by a remote server.
 *
 * @brief Connection file.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CGGeometry.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif
#include <CommonCrypto/CommonCryptor.h>

#import "FHDefines.h"
#import "FHConnectionDelegate.h"
#import "FHStatistics.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#ifdef __cplusplus
class FHIosConnection;
namespace FHCKernel
{
class FHKConnectionParameters;
}
class FHRelayController;
#define FHKConnectionParams FHCKernel::FHKConnectionParameters
#else
#define FHIosConnection void*
#define FHKConnectionParams void*
#define FHRelayController void*
#endif

@class FHView;
@protocol FHConnectionOptions;
@protocol FHStatistics;

/**
 * @class FHConnectionOptions
 * Connection Options allows the client to control specific connection options.
 *
 * @brief Connection Options class.
 *
 * FHConnectionOptions allows the client to control
 * how a connection to a server can be completed. 
 *
 * acceptUnknownCA specifies whether a secure connection can be made with an unrecognized security certificate.
 * proxyUsername and password represent the credentials that will be sent to any secure proxy that 
 * is needed to create a connection.
 *
 */

@interface FHConnectionOptions : NSObject
{
    BOOL acceptUnknownCA;
    NSString *proxyUsername, *proxyPassword;
}

@property BOOL acceptUnknownCA;
@property (retain) NSString *proxyUsername;
@property (retain) NSString *proxyPassword;

@end

/**
 * @class FHConnectionParameters
 *
 * @brief Connection Parameters class.
 *
 * FHConnectionParameters represents the meta information needed to request a service. 
 * The fields should be filled out according to the information specified by the service
 * provider.
 *
 */

enum { UDC_Stream, UDC_Message  } FHUserDataChannelModes;


typedef int FHUserDataChannelMode;


@interface FHConnectionParameters : NSObject 
{
@private
    FHKConnectionParams* params;
@public
}

- (NSString*) getRegion;
- (void) setRegion:(NSString*)r;
- (NSString*) getServiceId;
- (void) setServiceId:(NSString*) s;
- (NSString*) getIdentity;
- (void) setIdentity:(NSString*)i;
- (NSString*) getUser;
- (void) setUser:(NSString*)u;
- (NSString*) getPass;
- (void) setPass:(NSString*)p;
- (NSString*) getServiceParameters;
- (void) setServiceParameters:(NSString*)s;
- (NSString*) getDynamicSetupScript;
- (void) setDynamicSetupScript:(NSString*)s;
- (int)  getServiceHeight;
- (void) setServiceHeight:(int)i;
- (int)  getServiceWidth;
- (void) setServiceWidth:(int)i;
- (NSDictionary*) getCustomHeaders;
- (void) setCustomHeaders: (NSDictionary*) customHeaders;
- (void) setUserDataChannelMode:(FHUserDataChannelMode)mode;
- (FHUserDataChannelMode) getUserDataChannelMode;
@end


/**
 * @class FHMessageSender
 *
 * @brief Message Sender protocol.
 *
 * An protocol implemented by all components to which user messages can be sent.
 * Implemented by the connection and the view.
 *
 */

@protocol FHMessageSender<NSObject>

- (void) sendKeyPressedMessage:(int)keyId modifier:(int) keyMod;
- (void) sendKeyUpMessage:(int)keyId modifier:(int) keyMod;
- (void) sendKeyDownMessage:(int)keyId modifier:(int) keyMod;
- (void) sendMousePositionMessage:(int)xPos yPos:(int)yPos;
- (void) sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos;
- (void) sendMouseClickMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;
- (void) sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;
- (void) sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;
- (void) sendMouseScrollMessage:(int)xPos yPos:(int)yPos delta:(int)delta;
- (void) startScrollEvent:(int)x yPos:(int) y delta:(double)d velocity:(double)a;
- (void) generateScrollEvent:(int)x yPos:(int) y delta:(double)d velocity:(double)a;
- (void) endScrollEvent:(int) x yPos:(int) y;

@end



@protocol FHRendererContext <FHMessageSender>
@end

@protocol FHConnectionDelegate;


/**
 * @class FHConnection
 *
 * @brief Connection class.
 *
 * This class represents the connection from the client to the Framehawk encoder.
 * All data between the client and the server is carried through this object.
 * It maintains the state of the image data, and is responsible for sending all user
 * events (mouse, keyboard, user data) to the server.
 *
 * The target view for the image data to be rendered on is specified by the view variable.
 * Without this, the connection will continue to run, but without image data being drawn.
 */

@interface FHConnection : NSThread <FHRendererContext>
{
    /** Connection. */
    FHIosConnection *connection;

    /** Connection parameters. */
    FHConnectionParameters *parameters;

    /** View that the connection will be displayed in. */
	FHView *view;

    /** Connection Statistics. */
	id<FHStatistics> statistics;
    
    /** String containing any potentially encountered connection error. */
    NSString *connectionError;

    /** Connection Options. */
    FHConnectionOptions *options;

    /** Service URL to connect to. */
    NSURL *url;
    
    /** Requested buffer size for connection view. */
	CGRect requestedBuffer;

    /** Actual buffer size of connection view. */
	CGRect actualBuffer;
	
    /** String containing server version information. */
    NSString *serverVersion;

    /** String containing client version information. */
    NSString *clientVersion;

    /** String containing information about the last encountered error **/
    NSString* error;
    
    /** Flag to signify that the connection is still running **/
	BOOL running;

    /** Flag to signify that the connection is established **/
	BOOL isConnected;
    
    /** Connection Feature Flags. */
	int connectionFeatureFlags;
		
    /** Connection Delegate. */
	id<FHConnectionDelegate> delegate;
    
    CGColorSpaceRef colorSpaceRef;
    
    void *meta;
    bool initialized;
    
    /** initial connection background color */
    int initialBGColor;
    /** initial connection phase background color */
    int phaseBGColor;
    
}

@property (retain) FHConnectionOptions*  options;
@property (assign) id<FHConnectionDelegate> delegate;
@property (nonatomic, assign) FHView *view;
@property (readonly) FHConnectionParameters *parameters;
@property (assign) NSString* serverVersion;
@property (readonly) NSString* clientVersion;
@property (readonly) BOOL running;
@property (readonly) BOOL isPaused;
@property (readonly) BOOL isConnected;
@property (readonly) id<FHStatistics> statistics;
@property CGRect requestedBuffer;
@property (readonly) CGRect actualBuffer;
@property int initialBGColor;
@property int phaseBGColor;

@property BOOL debugRectangles;
@property (readonly) NSString* error;

/**
 * Initialize a connection.
 */
- (id) initWithURL:(NSURL*)url andFeatureFlags:(int)featureFlags andParameters:(FHConnectionParameters*)parameters;

/**
 * Initialize a connection with additional connection options.
 */
- (id) initWithURL:(NSURL*)url andFeatureFlags:(int)featureFlags andParameters:(FHConnectionParameters*)parameters andConnectionOptions:(id<FHConnectionOptions>)opts;

/**
 * Initialize a connection from a Relay Controller.
 */

-(id) initWithRelayController:(FHRelayController*)rc;

/**
 * Send key pressed message to the connection.
 */
- (void) sendKeyPressedMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send key released up message to the connection.
 */
- (void) sendKeyUpMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send key pressed down message to the connection.
 */
- (void) sendKeyDownMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send key pressed messages to the connection for a string of characters.
 */
- (void) sendKeyPressedMessages:(NSString*)keys modifier:(int) keyMod;

/**
 * Send mouse position message to the connection.
 * Will actually only send an actual mouse position message every x times this is called
 * to prevent flooding the connection with mouse position messages.
 */
- (void) sendMousePositionMessage:(int)xPos yPos:(int)yPos;

/**
 * Send mouse position message always (every time this method is called).
 */
- (void) sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos;

/**
 * Send a mouse button click message to the connection.
 */
- (void) sendMouseClickMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Send a mouse button up message to the connection.
 */
- (void) sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Send a mouse button down message to the connection.
 */
- (void) sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Send a mouse scroll message to the connection.
 */
- (void) sendMouseScrollMessage:(int)xPos yPos:(int)yPos delta:(int)delta;

/**
 * Send a mouse scroll message to the connection.
 */
- (void) sendMouseScrollEndMessage:(int)xPos yPos:(int)yPos;


// Scrolling v2
- (void) startScrollEvent:(int)x yPos:(int) y velocity:(double) velocity;
- (void) generateScrollEvent:(int)x yPos:(int) y delta:(double) delta velocity:(double) velocity;
- (void) endScrollEvent:(int) x yPos:(int) y;

/**
 * Start (or restart when paused) connection to service.
 */
- (BOOL) startConnection;

/**
 * Pause connection to service.
 */
- (void) pauseConnection;

/**
 * Stop connection to service.
 */
- (void) stopConnection;


// asynchronous stop
-(void) cancelConnection;

/**
 * Set initial background color.
 */
- (void) assignInitialBkColor:(int)theColor;

/**
 * Set initial phase background color.
 */
- (void) assignPhaseBkColor:(int)theColor;


/**
 * Send some Data Channel Data to the service.
 */
- (void) sendDataChannelData:(NSData*)d;

/**
 * Flush Data Channel indictaes that a complete data channel message has been sent
 * (after having called sendDataChannelData one or more times).
 */
- (void) flushDataChannel;

/**
 * Get Client version.
 */
- (NSString*) getClientVersion;

/**
 * Get Server version.
 */
- (NSString*) getServerVersion;

/**
 * Get Data Buffer.
 */
- (unsigned char*) getDataBuffer;

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

/**
 * Set initial background color.
 */
- (void) setInitialBkColor:(int)theColor;

/**
 * Set initial phase background color.
 */
- (void) setPhaseBkColor:(int)theColor;


@end
