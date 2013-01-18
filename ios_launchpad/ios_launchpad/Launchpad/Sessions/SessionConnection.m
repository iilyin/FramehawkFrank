//
//  SessionConnection.m
//  Launchpad
//
//  SessionConnection class used to connect to a Framehawk session
//  Manages a single session connection
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SessionConnection.h"

#if 1
#if PRODUCTION
#define INITIAL_BG_COLOR           0xFF708090   // grey color
#define INITIAL_PHASE_BG_COLOR     0xFF701919   // framehawk blue color
#else
#define INITIAL_BG_COLOR           0xFFf020a0   // purple color
#define INITIAL_PHASE_BG_COLOR     0xFF7fff00   // green color
#endif
#else
#define INITIAL_BG_COLOR           0xFF000000   // black
#define INITIAL_PHASE_BG_COLOR     0xFF000000   // black
#endif


@implementation SessionConnection

@synthesize currentState;   // Session connection state

/**
 * Deallocation clean up
 */
- (void)dealloc
{
    // clear connection delegate
    [connection setDelegate:nil];
    // clear connection view
    [connection setView:nil];
    // free connection
    connection = nil;
}

/**
 * Set delegate (Session) for SessionConnection
 *
 * @param (id)theDelegate - delegate for session connection
 */
-(void)setDelegate:(id)theDelegate
{
    // set connection delegate as self
    [connection setDelegate:self];
    // set delegate
    delegate = theDelegate;
}

/**
 * Set requested buffer
 *
 * @param (CGRect)theBufferRect - rectangular buffer
 */
-(void)setRequestedBuffer:(CGRect)theBufferRect
{
    [connection setRequestedBuffer:theBufferRect];
}

/**
 * Is connection running
 *
 * @return (BOOL) - TRUE if session connection is running
 */
-(BOOL)isRunning
{
    return [connection running];
}

/**
 * Is connection paused
 *
 * @return (BOOL) - TRUE if session connection is paused
 */
-(BOOL)isPaused
{
    return [connection isPaused];
}

/**
 * Returns last connection error
 *
 * @return (NSString*) - last connection error string
 */
-(NSString*)lastError
{
    return [connection error];
}

/**
 * Start connection
 *
 * @return (BOOL) - true if connection was started successfully
 */
- (BOOL)startConnection
{
    // set up connection background colors]
    int initialBGColor = INITIAL_BG_COLOR;
    if ([connection respondsToSelector:@selector(setInitialBkColor:)])
        [connection setInitialBkColor:initialBGColor];
    int initialPhaseColor = INITIAL_PHASE_BG_COLOR;
    if ([connection respondsToSelector:@selector(setPhaseBGColor:)])
        [connection setPhaseBGColor:initialPhaseColor];
    
    DLog(@"FH Library version:%@", [connection clientVersion]);

    // set state to connection opening
    [self setCurrentState:kSessionConnectionOpening];
    
    return [connection startConnection];
}

/**
 * Pause connection
 */
- (void)pauseConnection
{
    if ([connection running])
    {
        // set state to connection paused
        [self setCurrentState:kSessionConnectionPaused];
        [connection pauseConnection];
    }
}

/**
 * Stop connection
 */
- (void)stopConnection
{
    if ([connection running])
    {
        DLog(@"SessionConnection stopConnection IN");
        // set state to connection closing
        [self setCurrentState:kSessionConnectionClosing];
        [connection stopConnection];
        DLog(@"SessionConnection stopConnection OUT");
    }
    else
    {
        DLog(@"stopConnection WAS NOT RUNNING");
    }
}

/**
 * Set View for connection
 *
 * @parmam (FHView *)v - view to set for session connection to render into
 */
-(void)setView:(FHView *)v;
{
    [connection setView:v];
}

/**
 * Initialize a connection.
 *
 * @param (NSURL*)url - url of service to connect to
 * @param (int)featureFlags - feature flags requested from service
 * @param (FHConnectionParameters*)parameters - connection parameters
 *
 * @return (id) SessionConnection that was created
 */
- (id) initWithURL:(NSURL*)url andFeatureFlags:(int)featureFlags andParameters:(FHConnectionParameters*)parameters
{
    self = [super init];
    if (nil != self)
    {
        connection = [[FHConnection alloc] initWithURL:url andFeatureFlags:featureFlags andParameters:parameters];
        
        // set state to connection inactive
        [self setCurrentState:kSessionConnectionInactive];
    }
    
    return self;
}

/**
 * Set connection options.
 *
 * @param (FHConnectionOptions*)options - connection options
 */
- (void)setOptions:(FHConnectionOptions*)options;
{
    [connection setOptions:options];
}

/**
 * Send key down message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyDownMessage:(int)keyId modifier:(int) keyMod
{
    [connection sendKeyDownMessage:keyId modifier:keyMod];
}

/**
 * Send key up message
 *
 * @param (int)keyId - identifier of key that has been released
 * @param (int)keyMod - modified for key that has been released
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyUpMessage:(int)keyId modifier:(int) keyMod
{
    [connection sendKeyUpMessage:keyId modifier:keyMod];
}

/**
 * Send key pressed message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyPressedMessage:(int)keyId modifier:(int) keyMod
{
    [connection sendKeyPressedMessage:keyId modifier:keyMod];
}

/**
 * Send mouse position message
 * (NOTE: will not be sent every time called to prevent flooding with messages)
 * Use when mouse position is being updated frequently but immediate update is not
 * essential e.g. when moving mouse around the screen
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 */
- (void)sendMousePositionMessage:(int)xPos yPos:(int)yPos
{
    [connection sendMousePositionMessage:xPos yPos:yPos];
}

/**
 * Send mouse position message always
 * (NOTE: will be sent every time called so limit use to prevent flooding with messages)
 * Use when mouse position is not being updated frequently and precision is required for
 * the mouse position e.g. prior to a mouse click being sent.
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 */
- (void)sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos
{
    [connection sendMousePositionMessageAlways:xPos yPos:yPos];
}

/**
 * Sends mouse click message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being clicked
 * (See mouseButtons in FHDefines.h)
 */
- (void)sendMouseClickMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber
{
    [connection sendMouseDownMessage:xPos yPos:yPos buttonNumber:buttonNumber];
    [connection sendMouseUpMessage:xPos yPos:yPos buttonNumber:buttonNumber];
}

/**
 * Sends mouse up message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being released
 * (See mouseButtons in FHDefines.h)
 */
- (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber
{
    [connection sendMouseUpMessage:xPos yPos:yPos buttonNumber:buttonNumber];
}

/**
 * Sends mouse down message at specified position with specified mouse button number
 *
 * @param (int)xPos - x-position of mouse click on screen
 * @param (int)yPos - y-position of mouse click on screen
 * @param (int)buttonNumber - mouse button that is being pressed
 * (See mouseButtons in FHDefines.h)
 */
- (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber
{
    [connection sendMouseDownMessage:xPos yPos:yPos buttonNumber:buttonNumber];
}

/**
 * Send Mouse Scroll Message
 *
 * @param (int)xPos - x-position of mouse scroll.
 * @param (int)yPos - y-position of mouse scroll.
 * @param (int)delta - y-delta of scroll.
 */
- (void)sendMouseScrollMessage:(int)xPos yPos:(int)yPos delta:(int)delta
{
    [connection sendMouseScrollMessage:xPos yPos:yPos delta:delta];
}

/**
 * Start scroll event
 * Called when start to send a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 */
- (void) startScrollEvent:(int)x yPos:(int) y velocity:(double)v
{
    [connection startScrollEvent:x yPos:y velocity:v];
}

/**
 * Start scroll event
 * Called when start to send a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)d - the y-delta value of scroll
 * @param (double)theVelocity - y-scroll velocity
 */
- (void) startScrollEvent:(int)x yPos:(int) y delta:(double)d velocity:(double) v
{
    [connection startScrollEvent:x yPos:y delta:d velocity:v];
}

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the connection.
 *
 * @param (int)x - The x-position of the scroll location in the FH coordinate space.
 * @param (int)y - The y-position of the scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 */
- (void) generateScrollEvent:(int)x yPos:(int) y delta:(double)d  velocity:(double)a
{
    [connection generateScrollEvent:x yPos:y delta:d velocity:a];
}

/**
 * End scroll event
 * Called to signify the end of a scroll event to the connection.
 *
 * @param (int)x - The scroll x-location in the FH coordinate space.
 * @param (int)y - The scroll y-location in the FH coordinate space.
 */
- (void) endScrollEvent:(int) x yPos:(int) y
{
    [connection endScrollEvent:x yPos:y];
}

#pragma mark - FHConnectionDelegate implementation

/**
 * First render received
 * Called when the first render frame has been received for a connection.
 *
 * @param (SessionConnection *)theConnection - Framehawk session connection that has received the first render.
 */
- (void)firstRenderReceived:(FHConnection *)theConnection
{
    DLog(@"SessionConnection::firstRenderReceived");
    [delegate firstRenderReceived:self];
}

/**
 * Connection status change
 * Called when there is any change in connection status.
 *
 * @param (FHConnection *)theConnection - connection whose status has changed.
 * @param (connectionStates)theState - the state that the connection has changed to.
 * @param (NSString *)theMessage - the message about the connection state change.
 */
- (void)connectionStatusChange:(FHConnection *)theConnection toState:(connectionStates)theState withMessage:(NSString *)theMessage
{
    switch (theState)
    {
        case kConnConnectionFailed:
        {
            // set state to connection error
            [self setCurrentState:kSessionConnectionError];
        }
            break;

        case kConnConnectionDiedUnexpectedly:
        {
            // set state to connection connected closed
            [self setCurrentState:kSessionConnectionClosed];
        }
            break;

        case kConnConnectedOK:
        {
            // set state to connection connected ok
            [self setCurrentState:kSessionConnectionOpen];
        }
            break;

        case kConnConnectedSlow:
        {
            // set state to connection connected ok
            [self setCurrentState:kSessionConnectionOpen];
        }
            break;

        case kConnConnectionClosedNormally:
        {
            // set state to connection closed
            [self setCurrentState:kSessionConnectionClosed];
        }
            break;

        default:
            break;
    }

    // send information to SessionConnection delegate
    [delegate connectionStatusChange:self toState:theState withMessage:theMessage];
}

/**
 * Called to confirm the client supports the required feature flags (see FHDefines.h).
 * This must return TRUE for a connection to complete.
 *
 * @param (SessionConnection*)connection - the connection that is checking.
 * @param (connectionFeatureFlags)featureFlags - flags for connection feature to check supported by client.
 *
 * @return (BOOL) - TRUE if the client supports all the specified feature flags.
 */
-(BOOL)confirmConnectionFeatureFlags:(SessionConnection*)connection withFeatureFlags:(connectionFeatureFlags)featureFlags;
{
    DLog(@"SessionConnection::confirmConnectionFeatureFlags:withFeatureFlags:");
    return YES;
}

/**
 * Get server version for session connection.
 *
 * @return (NSString*) - String containing server version of current connection.
 */
- (NSString*)getServerVersion
{
    return [connection getServerVersion];
}


@end
