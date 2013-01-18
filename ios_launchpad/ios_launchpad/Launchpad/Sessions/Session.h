//
//  Session.h
//  Launchpad
//
//  Session class used to manage a single Framehawk sessions
//  Manages a single session
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionConnection.h"
#import "SessionView.h"
#import "FHServiceView.h"

/**
 * Session states
 */
typedef enum {
    kSessionInactive,
    kSessionOpening,
    kSessionActive,
    kSessionClosing,
    kSessionClosed,
    kSessionFailed,
    kSessionDestroyed,
} SessionState;


/**
 * Session connection error states
 */
typedef enum {
    kMissingConnectionParamsCode = 1,
    kFailedStartingConnectionCode,
    kConnectionStatusFailedCode,
    kConnectionStatusDiedUnexpectedlyCode,
    kFailedStoppingConnectionCode,
} SessionConnectionError;

/**
 * Session Delegate protocol
 */
@protocol SessionDelegate <NSObject>

/**
 * Called when the first render frame has been received.
 *
 * @param (SessionConnection *)theConnection - session connection that has received
 * the first render.
 */
- (void)firstRenderReceived:(SessionConnection *)theConnection;

/**
 * Connection status change
 * Called when there is any change in connection status.
 *
 * @param (SessionConnection *)theConnection - connection whose status has changed.
 * @param (connectionStates)theState - the state that the connection has changed to.
 * @param (NSString *)theMessage - the message about the connection state change.
 */
-(void)connectionStatusChange:(SessionConnection*)connection toState:(connectionStates)state withMessage:(NSString*)message;

@optional

@end

/**
 * SessionViewController Delegate protocol
 */
@protocol SessionViewControllerDelegate <NSObject>
- (FHServiceView *)placeholderToShowFHView;
@end

/**
 * Session Connection Utility Delegate protocol
 */
@protocol SessionConnectionUtilityDelegate <NSObject>

@optional
- (void)connectionDidStart;
- (void)connectionDidFinish;
- (void)connectionDidFailWithError:(NSError *)error;
- (void)connectionReadyToStream;

@end

/**
 * Session parameters
 */
@interface SessionParameters : NSObject
{
    NSString*   url;
    NSString*   serviceID;
    NSNumber*   region;
    NSString*   username;
    NSString*   password;
    NSString*   arguments;
};

@property   NSString*   url;
@property   NSString*   serviceID;
@property   NSNumber*   region;
@property   NSString*   username;
@property   NSString*   password;
@property   NSString*   arguments;

@end

/**
 * Session class
 */
@interface Session : NSObject <SessionConnectionDelegate>
{
    NSString* sessionName;                                      // Session Name
    SessionConnection* connection;                              // Session connection
    SessionView* view;                                          // Session view
    SessionState currentState;                                  // Session state
    id<SessionDelegate> delegate;                               // Session delegate
    id<SessionViewControllerDelegate> viewControllerDelegate;   // Session view controller delegate
    id<SessionConnectionUtilityDelegate> connectionUtilityDelegate;  // Session connection delegate
    BOOL isConnected;                                           // Session is connected flag
    BOOL wasClosedByUser;                                       // Session was closed by user
}

@property NSString* sessionName;                                // Session name
@property SessionConnection* connection;                        // Session connection
@property SessionView* view;                                    // Session view
@property SessionState currentState;                            // Session state
@property id<SessionDelegate> delegate;                         // Session delegate
@property id<SessionViewControllerDelegate> viewControllerDelegate;  // Session view controller delegate
@property id<SessionConnectionUtilityDelegate> connectionUtilityDelegate;    // Session connection delegate
@property BOOL isConnected;                                     // Session connected flag
@property BOOL wasClosedByUser;                                 // Session was closed by user

/**
 * Setup of the SessionConnection object with specified parameters
 *
 * @param (NSString*) url - String which contains the service url.
 * @param (NSString*) serviceId - String which contains the service ID value.
 * @param (NSString*) region - String which contains Region's id for the service.
 * @param (NSString*) username - Username for the service connection
 * @param (NSString*) password - Password for the specified username
 *
 * @return (BOOL) - true if connection was successful
 */
- (BOOL)connectWithURL:(NSString*)url
             serviceId:(NSString*)serviceID
                region:(NSNumber*)region
              username:(NSString*)username
              password:(NSString*)password
            parameters:(NSString*)parameters;


/**
 * Initialize session
 */
- (id)init;

/**
 * Set up view for session
 *
 * @param (CGRect)frame - the frame size for the session view
 */
- (void)setupView:(CGRect)frame;

/**
 * Start connection
 *
 * @return (BOOL) - true if connection was started successfully
 */
- (BOOL)startConnection;

/**
 * Stop connection
 */
- (void)stopConnection;

/**
 * Pause connection
 */
- (void)pauseConnection;

/**
 * Returns last connection error
 *
 * @param (NSString*)lastError - string containing information about last connection error.
 */
-(NSString*)lastError;

/**
 * Start scroll event
 * Called when start to send a scroll event to the session connection.
 *
 * @param (CGPoint)location - the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 */
- (void)startScrollEvent:(CGPoint)location velocity:(double)theVelocity;

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 */
- (void)generateScrollEvent:(CGPoint)location delta:(double)theDelta velocity:(double)theVelocity;

/**
 * End scroll event
 * Called to signify the end of a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 */
- (void)endScrollEvent:(CGPoint)location;

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
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
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
 * Sends mouse click message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 */
- (void)sendMouseClickMessage:(CGPoint)position mouseButton:(int)buttonID;

/**
 * Sends mouse up message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being released (mouseButtons in FHDefines.h)
 */
- (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Sends mouse down message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 */
- (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonNumber;

/**
 * Handle a user tap at a specified location onscreen.
 *
 * @param tapLocation The tap location in the FH coordinate space.
 */
- (void)singleTapDetected:(CGPoint)tapLocation;

/**
 * Returns true if connection is running
 *
 * @return (BOOL) - true if connection is currently running
 */
- (BOOL)connectionIsRunning;

/**
 * Resume service connection
 */
- (void)resumeConnection;

/**
 * Drop connection and view
 *
 * Stop service connection and releases connection & view
 */
- (void)dropConnectionAndView;

/**
 * Check if view is currently being created for a session
 *
 * @return (BOOL) - TRUE if the view for the session is currently being created
 */
- (BOOL)viewIsBeingCreated;

/**
 * Set current state of session view
 * Stores view state to provide information about how view is currentlu displayed.
 *
 * @param (SessionViewState)viewState - view state tp assogm tp view
 */
- (void)setCurrentViewState:(SessionViewState)viewState;

/**
 * Get server version for session connection.
 *
 * @return (NSString*) - String containing server version of current connection.
 */
- (NSString*)getServerVersion;


@end
