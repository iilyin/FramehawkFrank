//
//  SessionManager.m
//  Launchpad
//
//  SessionManager class used to manage connections to Framehawk sessions
//  Manages multiple session connections
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SessionManager.h"
#import "Session.h"
#import "SessionView.h"

// Dictionary of sessions
static NSMutableDictionary     *sessionsDictionary;

// session key generator seed
static int sessionKeyGeneratorSeed;

// count of any pending service connections (started but not yet completed 1st render of failed)
int  pendingServiceConnections;

@implementation SessionManager

@synthesize currentState;   // Session Manager state

/**
 * Get session with specified key
 *
 * @param (SessionKey)sessionKey - key used to access session
 *
 * @return (Session *) - Session with given key (or nil if no session with given key found)
 */
+(Session *)getSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session *connection = (Session *)[sessionsDictionary objectForKey:sessionKey];
    return connection;
}

/**
 * Create session named
 *
 * @param (NSString*)theSessionName - session name
 * @param (SessionParameters*)theParameters - session parameters
 * @param (id)theViewDelegate - session view delegate
 * @param (id)theConnectionDelegate - session connection delegate
 * @param (int)count - estimated maximum number of sessions
 *
 * @return (SessionKey) - key used to reference session via Session Manager
 */
+ (SessionKey)createSessionNamed:(NSString*)theSessionName withParameters:(SessionParameters*)theParameters viewDelegate:(id)theViewDelegate connectionDelegate:(id)theConnectionDelegate sessionCount:(int)count
{
    
    static dispatch_once_t predicate;
    
    // initial set up of dictionary of sessions
    dispatch_once(&predicate, ^{
        // create mutable dictionary for sessions
        sessionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:count];
        // reset session key generator seed
        sessionKeyGeneratorSeed = 0;
    });
    
    // always create a new session, allowing old sessions time to shut down

    // create new session
    Session* newSession = [[Session alloc] init];

    // assign session name
    [newSession setSessionName:theSessionName];
    
    // set up delegates for session
    [newSession setViewControllerDelegate:theViewDelegate];
    [newSession setConnectionUtilityDelegate:theConnectionDelegate];
    
    // store session with key
    NSString* sessionKey = [NSString stringWithFormat:@"%i", ++sessionKeyGeneratorSeed];
    [sessionsDictionary setObject:newSession forKey:sessionKey];
    
    // connect to session
    [newSession connectWithURL:[theParameters url]
                  serviceId:[theParameters serviceID]
                     region:[theParameters region]
                   username:[theParameters username]
                   password:[theParameters password]
                 parameters:[theParameters arguments]];
    
    // return session key
    return sessionKey;
    
}


/**
 * Check if is currently creating a session view
 *
 * @return (NSString*) - string containing session name for session with specified key
 *                     - nil if no session with specified key exists
 */
+ (NSString*)getSessionNameForSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    return [session sessionName];
}


/**
 * Check if is currently creating a session view
 *
 * @return (BOOL) - true if is currently creating a session view
 */
+ (BOOL)isCreatingSessionView
{
    BOOL bCreatingASessionView = FALSE;

    // check if any sessions are currently creating a session view
    // parse list of current sessions
    for (id key in [sessionsDictionary allKeys]) {
        // get current session
        Session* session = [SessionManager getSessionWithKey:key];
        
        // check if session state is not that is has been destroyed
        if ([session viewIsBeingCreated])
        {
            // set creating a session flag
            bCreatingASessionView = TRUE;
            // can exit since we found a session whose view is being created
            break;
        }
    }

    // return if any sessions were being created
    return bCreatingASessionView;
}

/**
 * Start scroll event
 * Called when start to send a scroll event to the session connection.
 *
 * @param (CGPoint)location - the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) startScrollEvent:(CGPoint)location velocity:(double)theVelocity toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];

    // send start scroll event to session
    [session startScrollEvent:location velocity:theVelocity];
}

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) generateScrollEvent:(CGPoint)location delta:(double)theDelta velocity:(double)theVelocity toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // send scroll event to session
    [session generateScrollEvent:location delta:theDelta velocity:theVelocity];
}

/**
 * End scroll event
 * Called to signify the end of a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void) endScrollEvent:(CGPoint)location toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // send end scroll event to session
    [session endScrollEvent:location];
}


/**
 * Send key down message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyDownMessage:(int)keyId modifier:(int)keyMod toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // send key pressed message to session with given key
    [session sendKeyDownMessage:keyId modifier:keyMod];
}

/**
 * Send key up message
 *
 * @param (int)keyId - identifier of key that has been released
 * @param (int)keyMod - modified for key that has been released
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyUpMessage:(int)keyId modifier:(int)keyMod toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // send key pressed message to session with given key
    [session sendKeyUpMessage:keyId modifier:keyMod];
}

/**
 * Send key pressed message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendKeyPressedMessage:(int)keyId modifier:(int) keyMod toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // send key pressed message to session with given key
    [session sendKeyPressedMessage:keyId modifier:keyMod];
}

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
+ (void)sendMousePositionMessage:(int)xPos yPos:(int)yPos toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    [session sendMousePositionMessage:xPos yPos:yPos];
}

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
+ (void)sendMousePositionMessageAlways:(int)xPos yPos:(int)yPos toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    [session sendMousePositionMessageAlways:xPos yPos:yPos];
}

/**
 * Sends mouse click message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseClickMessage:(CGPoint)position mouseButton:(int)buttonID toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    [session sendMouseClickMessage:position mouseButton:buttonID];
}

/**
 * Sends mouse up message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being released (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    [session sendMouseUpMessage:xPos yPos:yPos buttonNumber:buttonNumber];
}

/**
 * Sends mouse down message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // Send mouse down message to session
    [session sendMouseDownMessage:xPos yPos:yPos buttonNumber:buttonNumber];
}

/**
 * Handle a user tap at a specified location onscreen.
 *
 * @param tapLocation The tap location in the FH coordinate space.
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)singleTapDetected:(CGPoint)tapLocation toSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // Send tap location to session
    [session singleTapDetected:tapLocation];
}


/**
 * Pause connection
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)pauseConnection:(SessionKey)sessionKey;
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];

    // pause session connection
    [session pauseConnection];
}

/**
 * Returns true if connection is running for session with given key
 *
 * @param (SessionKey)sessionKey - key used to access session
 *
 * @return (BOOL) - true if connection is currently running
 */
+ (BOOL)connectionIsRunning:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // return true if session connection is running
    return ([session connectionIsRunning] && [session isConnected]);
}

/**
 * Resume service connection for session with given key
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)resumeConnection:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // resume connection
    [session resumeConnection];
}

/**
 * dropConnectionAndView
 * Stop service connection and remove view
 *
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)dropConnectionAndView:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // drop connection and view
    [session dropConnectionAndView];
}

/**
 * Set view state of view for session with specified key
 *
 * @param (SessionViewState)viewState - view state tp assogm tp view
 * @param (SessionKey)sessionKey - key used to access session
 */
+ (void)setCurrentViewState:(SessionViewState)viewState forSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // set state for session
    [session setCurrentViewState:viewState];
}

/**
 * Get current view state of view for session with specified key
 *
 * @param (SessionKey)sessionKey - key used to access session
 *
 * @return (SessionViewState)viewState - current view state for session view
 */
+ (SessionViewState)getCurrentViewStateForSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];
    
    // set state for session
    return [session currentState];
}

/**
 * getSessionKeyForSessionWithView
 * Returns a session key
 *
 * @param (SessionView*)sessionView - view to search for matching session
 *
 * @return (SessionKey) - key for session that has specified sessionView
 */
+ (SessionKey)getSessionKeyForSessionWithView:(SessionView*)sessionView
{
    SessionKey sessionKeyForSessionWithView = nil;
    
    // parse list of current sessions
    for (id key in [sessionsDictionary allKeys]) {
        // get current session
        Session* session = [SessionManager getSessionWithKey:key];
        
        // check if session's view matches requested session view
        if ([session view]==sessionView)
        {
            // set session key for this session 
            sessionKeyForSessionWithView = key;
            break;
        }
    }

    // return session key for session that uses specified view
    return sessionKeyForSessionWithView;
}

/**
 * cleanUpSessions
 *
 * Performs clean up of sessions services removing any that have
 * closed their connection and destroyed their view
 */
+ (void)cleanUpSessions
{
    // perform clean up on sessions
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // create dictionary of sessions to keep
        NSMutableDictionary *sessionsToKeep = [NSMutableDictionary dictionaryWithCapacity:[sessionsDictionary count]];

        // parse list of current sessions
        for (id key in [sessionsDictionary allKeys]) {
            // get current session
            Session* session = [SessionManager getSessionWithKey:key];

            // check if session state is not that is has been destroyed
            if ([session currentState]!=kSessionDestroyed)
            {
                @try
                {
                    // add session to list of sessions to keep
                    [sessionsToKeep setObject:session forKey:key];
                }
                @catch (...) {
                    // something messed up - session not added
                    return;
                }
            }
            else
            {
                // release session view
                session.view = nil;
                // release session connection
                session.connection = nil;
                // release session
                session = nil;
            }
        }
        // set sessions dictionary to list of sessions to keep
        [sessionsDictionary setDictionary:sessionsToKeep];
        
        int totalSessionsInDictionary = [sessionsDictionary count];
        DLog(@">>> totalSessionsInDictionary = %d", totalSessionsInDictionary);
    });
}

/**
 * Get server version for session connection.
 *
 * @param (SessionKey)sessionKey - key used to access session
 * @return (NSString*) - String containing server version of current connection.
 */
+ (NSString*)getServerVersionForSessionWithKey:(SessionKey)sessionKey
{
    // get session for given key
    Session* session = [SessionManager getSessionWithKey:sessionKey];

    // return server version for current session
    return [session getServerVersion];
}

@end
