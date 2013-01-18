//
//  SessionConnection.h
//  Launchpad
//
//  SessionConnection class used to connect to a Framehawk session
//  Manages a single session connection
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "FHConnection.h"
#import "FHConnectionDelegate.h"

/**
 * Session Connection states
 */
typedef enum {
    kSessionConnectionInactive,
    kSessionConnectionOpening,
    kSessionConnectionOpen,
    kSessionConnectionPaused,
    kSessionConnectionClosing,
    kSessionConnectionClosed,
    kSessionConnectionError,
} SessionConnectionState;

@protocol SessionConnection
@end

@class SessionConnection;

/**
 * Session Connection Delegate protocol
 */
@protocol SessionConnectionDelegate <NSObject>

@optional

/**
 * First render received
 * Called when the first render frame has been received for a connection.
 *
 * @param (SessionConnection *)theConnection - Framehawk session connection that has received the first render.
 */
-(void)firstRenderReceived:(SessionConnection*)connection;

/**
 * Connection status change
 * Called when there is any change in connection status.
 *
 * @param (FHConnection *)theConnection - connection whose status has changed.
 * @param (connectionStates)theState - the state that the connection has changed to.
 * @param (NSString *)theMessage - the message about the connection state change.
 */
-(void)connectionStatusChange:(SessionConnection*)connection toState:(connectionStates)state withMessage:(NSString*)message;
@end

/**
 * Session Connection class
 */
@interface SessionConnection : NSObject <FHConnectionDelegate>
{
    FHConnection* connection;                   // Framehawk connection
    SessionConnectionState currentState;        // Session connection state
    id<SessionConnectionDelegate> delegate;     // Session connection delegates
}


@property SessionConnectionState currentState;  // Session connection state

/**
 * Set delegate (Session) for SessionConnection
 *
 * @param (id)theDelegate - delegate for session connection
 */
-(void)setDelegate:(id)theDelegate;

/**
 * Set requested buffer
 *
 * @param (CGRect)theBufferRect - rectangular buffer
 */
-(void)setRequestedBuffer:(CGRect)theBufferRect;

/**
 * Is connection running
 *
 * @return (BOOL) - TRUE if session connection is running
 */
-(BOOL)isRunning;

/**
 * Is connection paused
 *
 * @return (BOOL) - TRUE if session connection is paused
 */
-(BOOL)isPaused;

/**
 * Returns last connection error
 *
 * @return (NSString*) - last connection error string
 */
-(NSString*)lastError;

/**
 * Start connection
 *
 * @return (BOOL) - true if connection was started successfully
 */
- (BOOL)startConnection;

/**
 * Pause connection
 */
- (void)pauseConnection;

/**
 * Stop connection
 */
- (void)stopConnection;

/**
 * Set View for connection
 *
 * @parmam (FHView *)v - view to set for session connection to render into
 */
-(void)setView:(FHView *)v;

/**
 * Initialize a connection.
 *
 * @param (NSURL*)url - url of service to connect to
 * @param (int)featureFlags - feature flags requested from service
 * @param (FHConnectionParameters*)parameters - connection parameters
 *
 * @return (id) SessionConnection that was created
 */
- (id) initWithURL:(NSURL*)url andFeatureFlags:(int)featureFlags andParameters:(FHConnectionParameters*)parameters;

/**
 * Set connection options.
 *
 * @param (FHConnectionOptions*)options - connection options
 */
- (void)setOptions:(FHConnectionOptions*)options;

/**
 * Send key down message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyDownMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send key up message
 *
 * @param (int)keyId - identifier of key that has been released
 * @param (int)keyMod - modified for key that has been released
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyUpMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send key pressed message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyPressedMessage:(int)keyId modifier:(int) keyMod;

/**
 * Send mouse position message
 * (NOTE: will not be sent every time called to prevent flooding with messages)
 * Use when mouse position is being updated frequently but immediate update is not
 * essential e.g. when moving mouse around the screen
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 */
- (void)sendMousePositionMessage:(int)xPos yPos:(int)yPos;

/**
 * Send mouse position message always
 * (NOTE: will be sent every time called so limit use to prevent flooding with messages)
 * Use when mouse position is not being updated frequently and precision is required for
 * the mouse position e.g. prior to a mouse click being sent.
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 */
- (void)sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos;

/**
 * Sends mouse click message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being clicked
 * (See mouseButtons in FHDefines.h)
 */
- (void) sendMouseClickMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Sends mouse up message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being released
 * (See mouseButtons in FHDefines.h)
 */
- (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Sends mouse down message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being pressed
 * (See mouseButtons in FHDefines.h)
 */
- (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Send Mouse Scroll Message
 *
 * @param (int)xPos - x-position of mouse scroll.
 * @param (int)yPos - y-position of mouse scroll.
 * @param (int)delta - y-delta of scroll.
 */
- (void)sendMouseScrollMessage:(int)xPos yPos:(int)yPos delta:(int)delta;

/**
 * Start scroll event
 * Called when start to send a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 */
- (void) startScrollEvent:(int)x yPos:(int) y velocity:(double)v;

/**
 * Start scroll event
 * Called when start to send a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)d - the y-delta value of scroll
 * @param (double)theVelocity - y-scroll velocity
 */
- (void) startScrollEvent:(int)x yPos:(int) y delta:(double)d velocity:(double)v;

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 */
- (void) generateScrollEvent:(int)x yPos:(int) y delta:(double)d  velocity:(double)a;

/**
 * End scroll event
 * Called to signify the end of a scroll event to the connection.
 *
 * @param (int)x - The scroll x-location in the FH coordinate space.
 * @param (int)y - The scroll y-location in the FH coordinate space.
 */
- (void) endScrollEvent:(int) x yPos:(int) y;

/**
 * Get server version for session connection.
 *
 * @return (NSString*) - String containing server version of current connection.
 */
- (NSString*)getServerVersion;

@end
