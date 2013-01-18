//
//  SessionManager.h
//  Launchpad
//
//  SessionManager class used to manage connections to Framehawk sessions
//  Manages multiple session connections
//
//  All interaction with a session (e.g. mouse, keyboard input) should be
//  sent via the session manager accessing sessions using the key that
//  was returned when the session was started.
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Session.h"

@class Session;
@class SessionView;
@class SessionParameters;

/**
 * Session Manager states
 */
typedef enum {
    kSessionManagerNoActiveSessions,
    kSessionManagerSingleActiveSession,
    kSessionManagerMultipleActiveSessions,
} SessionManagerState;

/**
 * Session Key
 */
typedef NSString* SessionKey;


// count of any pending service connections (started but not yet completed 1st render or failed)
extern int  pendingServiceConnections;

/**
 * Session Manager class
 */
@interface SessionManager : NSObject
{

    SessionManagerState currentState;           // Session Manager state

}

@property SessionManagerState currentState;     // Session Manager state

/**
 * Create session
 *
 * @param (NSString*)theSessionName - session name
 * @param (SessionParameters*)theParameters - session parameters
 * @param (id)theViewDelegate - session view delegate
 * @param (id)theConnectionDelegate - session connection delegate
 * @param (int)count - estimated maximum number of sessions
 *
 * @return (SessionKey) - key used to reference session via Session Manager
 */
+ (SessionKey)createSessionNamed:(NSString*)theSessionName withParameters:(SessionParameters*)theParameters viewDelegate:(id)theViewDelegate connectionDelegate:(id)theConnectionDelegate sessionCount:(int)count;

/**
 * Check if is currently creating a session view
 *
 * @return (NSString*) - string containing session name for session with specified key
 *                     - nil if no session with specified key exists
 */
+ (NSString*)getSessionNameForSessionWithKey:(SessionKey)sessionKey;

/**
 * Check if is currently creating a session view
 *
 * @return (BOOL) - true if is currently creating a session view
 */
+ (BOOL)isCreatingSessionView;

/**
 * Start scroll event
 * Called when start to send a scroll event to the session connection.
 *
 * @param (CGPoint)location - the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) startScrollEvent:(CGPoint)location velocity:(double)theVelocity toSessionWithKey:(SessionKey)sessionKey;

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) generateScrollEvent:(CGPoint)location delta:(double)theDelta velocity:(double)theVelocity toSessionWithKey:(SessionKey)sessionKey;

/**
 * End scroll event
 * Called to signify the end of a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) endScrollEvent:(CGPoint)location toSessionWithKey:(SessionKey)sessionKey;

/**
 * Send key down message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyDownMessage:(int)keyId modifier:(int) keyMod toSessionWithKey:(SessionKey)sessionKey;

/**
 * Send key up message
 *
 * @param (int)keyId - identifier of key that has been released
 * @param (int)keyMod - modified for key that has been released
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyUpMessage:(int)keyId modifier:(int) keyMod toSessionWithKey:(SessionKey)sessionKey;

/**
 * Send key pressed message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyPressedMessage:(int)keyId modifier:(int) keyMod toSessionWithKey:(SessionKey)sessionKey;

/**
 * Send mouse position message
 * (NOTE: will not be sent every time called to prevent flooding with messages)
 * Use when mouse position is being updated frequently but immediate update is not
 * essential e.g. when moving mouse around the screen
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMousePositionMessage:(int)xPos yPos:(int)yPos toSessionWithKey:(SessionKey)sessionKey;

/**
 * Send mouse position message always
 * (NOTE: will be sent every time called so limit use to prevent flooding with messages)
 * Use when mouse position is not being updated frequently and precision is required for
 * the mouse position e.g. prior to a mouse click being sent.
 *
 * @param (int)xPos - x-position of mouse
 * @param (int)yPos - y-position of mouse
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos toSessionWithKey:(SessionKey)sessionKey;

/**
 * Sends mouse click message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseClickMessage:(CGPoint)position mouseButton:(int)buttonID toSessionWithKey:(SessionKey)sessionKey;

/**
 * Sends mouse up message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being released (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber toSessionWithKey:(SessionKey)sessionKey;

/**
 * Sends mouse down message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber toSessionWithKey:(SessionKey)sessionKey;

/**
 * Handle a user tap at a specified location onscreen.
 *
 * @param tapLocation The tap location in the FH coordinate space.
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)singleTapDetected:(CGPoint)tapLocation toSessionWithKey:(SessionKey)sessionKey;

/**
 * Pause connection
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)pauseConnection:(SessionKey)sessionKey;

/**
 * Returns true if connection is running for session with given key
 *
 * @param (SessionKey)sessionKey - key used to access session
 *
 * @return (BOOL) - true if connection is currently running
 */
+ (BOOL)connectionIsRunning:(SessionKey)sessionKey;

/**
 * Resume service connection for session with given key
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)resumeConnection:(SessionKey)sessionKey;

/**
 * dropConnectionAndView
 * Stop service connection and remove view
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)dropConnectionAndView:(SessionKey)sessionKey;

/**
 * Set view state of view for session with specified key
 *
 * @param (SessionViewState)viewState - view state tp assogm tp view
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)setCurrentViewState:(SessionViewState)viewState forSessionWithKey:(SessionKey)sessionKey;

/**
 * Get current view state of view for session with specified key
 *
 * @param (SessionKey)sessionKey - key used to access session
 *
 * @return (SessionViewState)viewState - current view state for session view
 */
+ (SessionViewState)getCurrentViewStateForSessionWithKey:(SessionKey)sessionKey;

/**
 * getSessionKeyForSessionWithView
 * Returns a session key
 *
 * @param (SessionView*)sessionView - view to search for matching session
 *
 * @return (SessionKey) - key for session that has specified sessionView
 */
+ (SessionKey)getSessionKeyForSessionWithView:(SessionView*)sessionView;

/**
 * cleanUpSessions
 *
 * Performs clean up of sessions services removing any that have
 * closed their connection and destroyed their view
 */
+ (void)cleanUpSessions;

/**
 * Get server version for session connection.
 *
 * @param (SessionKey)sessionKey - key used to access session
 * @return (NSString*) - String containing server version of current connection.
 */
+ (NSString*)getServerVersionForSessionWithKey:(SessionKey)sessionKey;

@end
