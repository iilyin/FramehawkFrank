//
//  Session.m
//  Launchpad
//
//  Session class used to manage a single Framehawk sessions
//  Manages a single session
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "Session.h"
#import "SessionManager.h"
#import "SettingsUtils.h"
#import "GlobalDefines.h"
#import "CommandCenter.h"

static NSString *const kSessionErrorDomain = @"SessionErrorDomain";
static NSString *const kSessionConfigurationError = @"This service has not been configured correctly - please contact your administrator.";

@interface Session () <FHConnectionDelegate>

@end

/**
 * Session parameters
 */
@implementation SessionParameters

@synthesize url;
@synthesize serviceID;
@synthesize region;
@synthesize username;
@synthesize password;
@synthesize arguments;

@end


@implementation Session

@synthesize currentState;               // Session state
@synthesize sessionName;                // Session name
@synthesize connection;                 // Connection
@synthesize view;                       // View
@synthesize delegate;                   // Session delegate
@synthesize viewControllerDelegate;     // View controller delegate
@synthesize connectionUtilityDelegate;  // Connection utility delegate
@synthesize isConnected;                // Session is connected flag
@synthesize wasClosedByUser;            // Session was closed by user

BOOL bViewBeingCreated;

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
            parameters:(NSString*)parameters
{
    if ([view getView]!=nil)
    {
        DLog(@"Start on non-empty view");
        return FALSE;
    }
    
    if(nil == url || 0 >= [url length] ||
       nil == serviceID || 0 >= [serviceID length] ||
       nil == region)
        
    {
        if([self.connectionUtilityDelegate respondsToSelector:@selector(connectionDidFailWithError:)])
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(kSessionConfigurationError, kSessionConfigurationError) forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:kSessionErrorDomain code:kMissingConnectionParamsCode userInfo:userInfo];
            [self.connectionUtilityDelegate connectionDidFailWithError:error];
        }
        return FALSE;
    }
    
    NSURL *serviceURL = [[NSURL alloc] initWithString:url];
    FHConnectionParameters* connParms = [[FHConnectionParameters alloc] init];
    [connParms setServiceId:serviceID];
    [connParms setRegion:[NSString stringWithFormat:@"%@", region]];
    
    if(username)
        [connParms setUser:username];
    if(password)
        [connParms setPass:password];
    
    // TODO: parameters should be dynamic
    [connParms setServiceWidth:1024];
    [connParms setServiceHeight:768];
    
    // set parameters if there are any (including URL)
    [connParms setServiceParameters:parameters];
    
    // load proxy username & password from settings
    NSString* proxyUserName = [SettingsUtils loadStringSettingWithKey:kSettingsProxyUserNameKey];
    NSString* proxyPassword = [SettingsUtils loadStringSettingWithKey:kSettingsProxyPasswordKey];
    
    // set up (optional) connection options - used for lab mode
    FHConnectionOptions *connectionOptions = [[FHConnectionOptions alloc] init];
    [connectionOptions setProxyUsername:proxyUserName];
    [connectionOptions setProxyPassword:proxyPassword];
    [connectionOptions setAcceptUnknownCA:YES];
    
    // set connection feature flags
	int connectRequestedFeatureFlags = 0;
    connectRequestedFeatureFlags |= kAudioRequested;
    
    [self setConnection:[[SessionConnection alloc] initWithURL:serviceURL andFeatureFlags:(connectionFeatureFlags)connectRequestedFeatureFlags andParameters:connParms]];
    
    CGRect fframe = CGRectMake(0, 0, 1024, 768);
    [connection setRequestedBuffer:fframe];
    [connection setDelegate:self];
    [connection setOptions:connectionOptions];
    
    DLog(@"Try to connect to service with URL: %@, serviceID: %@, region: %@", url, serviceID, region);
    DLog(@"Username %@ Password %@", username, password);
    
    
    @try
    {
        // increase number of pending service connections
        pendingServiceConnections++;
        
        // if application is not in the background
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            // ...Setup the Framehawk view
            DLog(@"Setup FHView for %@", [self sessionName]);
            [self setupView:fframe];
        }
        
        // If the Framehawk connection can be started...
        if ([self startConnection] && [CommandCenter networkIsAvailable])
        {
        }
        // Elsewise if an error was provided by the Framehawk connection...
        else
        {
            // increase number of pending service connections
            pendingServiceConnections--;
            
            if ([self lastError])
            {
                DLog(@"Framehawk Launchpad: Error connecting to Framehawk. '%@'.", [self lastError]);
                [NSException raise:@"Connection Error" format:@"A connection could not be established due to an error."];
            }
            // Elsewise...
            else {
                // only display error if view is active
                if ([self view])
                {
                    if ([CommandCenter networkIsAvailable])
                        [NSException raise:@"Connection error" format:@"Unknown error. Either service or network is unavailable."];
                    else
                        [NSException raise:@"Connection error" format:@"Cannot establish connection. Check network settings."];
                }
            }
        }
    }
    @catch (NSException *exc)
    {
        DLog(@"Exception: Name:%@, Reason:%@", [exc name], [exc reason]);
        if([self.connectionUtilityDelegate respondsToSelector:@selector(connectionDidFailWithError:)])
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString([exc reason], @"") forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:kSessionErrorDomain code:kFailedStartingConnectionCode userInfo:userInfo];
            [self.connectionUtilityDelegate connectionDidFailWithError:error];
        }
        return FALSE;
    }
    
    return TRUE;
}

/**
 * Initialize session
 */
- (id)init
{
    self = [super init];
    if(nil != self)
    {
        isConnected     = FALSE;
        wasClosedByUser = TRUE;
    }
    return self;
}

/**
 * Deallocation clean up
 */
- (void)dealloc
{
    // clear connection
    connection = nil;
    // clear view
    view = nil;
}

/**
 * Set up view for session
 *
 * @param (CGRect)frame - the frame size for the session view
 */
- (void)setupView:(CGRect)frame
{
    // flag view being created
    bViewBeingCreated = TRUE;
    
    DLog(@"Visible Frame X:%f Y:%f Width:%f Height:%f", frame.origin.x, frame.origin.y
         , frame.size.width, frame.size.height);
    
    // allocate session view
    [self setView:[[SessionView alloc] initWithFrame:frame]];
    DLog(@"setupView 0x%x self.fhConnection=0x%x!!!!", (int)[view getView], (int)connection);
    [connection setView:(FHView *)([view getView])];
    if([self.viewControllerDelegate respondsToSelector:@selector(placeholderToShowFHView)]) {
        FHServiceView *rvp = [self.viewControllerDelegate placeholderToShowFHView];
        rvp.fhView = view;
        DLog(@"Set rvp.fhView to self.fhView=0x%x", (int)view);
    }
    DLog(@"VIEW CREATED!!!!");
    
    // flag view finished
    bViewBeingCreated = FALSE;
}


/**
 * Start connection
 *
 * @return (BOOL) - true if connection was started successfully
 */
- (BOOL)startConnection
{
    return [connection startConnection];
}

/**
 * Stop connection
 */
- (void)stopConnection
{
    // Clear session connected flag
    [self setIsConnected:FALSE];
    [connection stopConnection];
}

/**
 * Pause connection
 */
- (void)pauseConnection
{
    [connection pauseConnection];
}

/**
 * Returns last connection error
 *
 * @param (NSString*)lastError - string containing information about last connection error.
 */
-(NSString*)lastError
{
    return [connection lastError];
}

/**
 * Start scroll event
 * Called when start to send a scroll event to the session connection.
 *
 * @param (CGPoint)location - the scroll location in the FH coordinate space.
 * @param (double)theVelocity - y-scroll velocity
 */
- (void) startScrollEvent:(CGPoint)location velocity:(double)theVelocity
{
    if (([self connectionIsRunning]) /*&& (![connection isPaused])*/)
        [connection startScrollEvent:(int)(location.x) yPos:(int)(location.y) velocity:theVelocity];
}

/**
 * Generate a scroll event.
 * Called when sending a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 * @param (double)theDelta - y-scroll delta
 * @param (double)theVelocity - y-scrolling velocity
 */
- (void) generateScrollEvent:(CGPoint)location delta:(double)theDelta velocity:(double)theVelocity
{
    if (([self connectionIsRunning]) /*&& (![connection isPaused])*/)
        [connection generateScrollEvent:(int)(location.x) yPos:(int)(location.y) delta:theDelta velocity:theVelocity];
    //    [self.fhConnection sendMouseScrollMessage:(int)(location.x) yPos:(int)(location.y) delta:delta];
    DLog(@"Handled scroll gesture at: %.2f, %.2f with delta: %.2f velocity:%.2f", location.x, location.y, theDelta, theVelocity);
}

/**
 * End scroll event
 * Called to signify the end of a scroll event to the session connection.
 *
 * @param (CGPoint)location - The scroll location in the FH coordinate space.
 */
- (void) endScrollEvent:(CGPoint)location
{
    if (([self connectionIsRunning]) /*&& (![connection isPaused])*/)
        [connection endScrollEvent:(int)(location.x) yPos:(int)(location.y)];
}

/**
 * Send key down message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modifiedSessi for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyDownMessage:(int)keyId modifier:(int)keyMod
{
    if ([self connectionIsRunning])
        [connection sendKeyDownMessage:keyId modifier:keyMod];
}

/**
 * Send key up message
 *
 * @param (int)keyId - identifier of key that has been released
 * @param (int)keyMod - modified for key that has been released
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyUpMessage:(int)keyId modifier:(int)keyMod
{
    if ([self connectionIsRunning])
        [connection sendKeyUpMessage:keyId modifier:keyMod];
}


/**
 * Send key pressed message
 *
 * @param (int)keyId - identifier of key that has been pressed
 * @param (int)keyMod - modified for key that has been pressed
 * (e.g. shift, ctrl, alt) from FHDefines.h
 */
- (void)sendKeyPressedMessage:(int)keyId modifier:(int)keyMod
{
    if ([self connectionIsRunning])
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
    if ([self connectionIsRunning])
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
    if ([self connectionIsRunning])
        [connection sendMousePositionMessageAlways:xPos yPos:yPos];
}

/**
 * Sends mouse click message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 */
- (void)sendMouseClickMessage:(CGPoint)position mouseButton:(int)buttonID
{
    if ([self connectionIsRunning])
        [connection sendMouseClickMessage:position.x yPos:position.y buttonNumber:buttonID];
}

/**
 * Sends mouse up message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being released (mouseButtons in FHDefines.h)
 */
- (void)sendMouseUpMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonID
{
    if ([self connectionIsRunning])
        [connection sendMouseUpMessage:xPos yPos:yPos buttonNumber:buttonID];
}

/**
 * Sends mouse down message at specified position with specified button ID
 *
 * @param (CGPoint)position - position of mouse click on screen
 * @param (int)buttonID - mouse button that is being pressed (mouseButtons in FHDefines.h)
 */
- (void)sendMouseDownMessage:(int)xPos yPos:(int)yPos buttonNumber:(int)buttonID
{
    if ([self connectionIsRunning])
        [connection sendMouseDownMessage:xPos yPos:yPos buttonNumber:buttonID];
}

/**
 * Handle a user tap at a specified location onscreen.
 *
 * @param tapLocation The tap location in the FH coordinate space.
 */
- (void)singleTapDetected:(CGPoint)tapLocation
{
    // if connection is not running then don't pass on taps
    if ([self connectionIsRunning])
    {
        [connection sendMouseClickMessage:(int)(tapLocation.x)  yPos:(int)(tapLocation.y) buttonNumber:kMouseButtonLeft];
    }
}

/**
 * Returns true if connection is running
 *
 * @return (BOOL) - true if connection is currently running
 */
- (BOOL)connectionIsRunning
{
    return ([connection isRunning] && isConnected);
}

/**
 * Resume service connection
 *
 */
- (void)resumeConnection
{
    if ( [connection isPaused] )
    {
        if ([connection isRunning])
        {
            @try
            {
                BOOL bForceRefresh = false;
                // if no view was yet created
                // (e.g. application backgrounded before connection completed)
                if (![view getView])
                {   // then set up the view
                    DLog(@"Resume setup FHView for %@", [self sessionName]);
                    bForceRefresh = true;
                }
                
                //DLog(@"Resume setup FHView 0x%x for %@", (int)[session fhView], [self sessionName]);
                [connection startConnection];
                // force refresh
                if (bForceRefresh)
                {
                    // force refresh of view
                    [[self view] setNeedsDisplay];
                    // sending a mouse scroll value of 0 - this force refresh of the view
                    [connection sendMouseScrollMessage:0 yPos:0 delta:0.0f];
                }
            }
            @catch (NSException *exc)
            {
                DLog(@"Exception: Name:%@, Reason:%@", [exc name], [exc reason]);
                if([self.connectionUtilityDelegate respondsToSelector:@selector(connectionDidFailWithError:)])
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString([exc reason], @"") forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:kSessionErrorDomain code:kFailedStartingConnectionCode userInfo:userInfo];
                    [self.connectionUtilityDelegate connectionDidFailWithError:error];
                }
            }
        }
    }
}

/**
 * Drop connection and view
 *
 * Stop service connection and releases connection & view
 */
- (void)dropConnectionAndView
{
    DLog(@"dropConnectionAndView");
    
    //    [connection setView:nil];
    if([self.viewControllerDelegate respondsToSelector:@selector(placeholderToShowFHView)])
    {
        FHServiceView *rvp = [self.viewControllerDelegate placeholderToShowFHView];
        //NSAssert( (rvp.fhView==view), @"rvp.fhView does not match SessionView." );
        rvp.fhView = nil;
    }
    //Quickly drop service
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            DLog(@"stopConnection IN");
            [self stopConnection];
            DLog(@"stopConnection OUT");
        }
        @catch (NSException *exc) {
            DLog(@"Exception: Name:%@, Reason:%@", [exc name], [exc reason]);
            if([self.connectionUtilityDelegate respondsToSelector:@selector(connectionDidFailWithError:)])
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString([exc reason], @"") forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:kSessionErrorDomain code:kFailedStoppingConnectionCode userInfo:userInfo];
                [self.connectionUtilityDelegate connectionDidFailWithError:error];
            }
        }
        @catch (...)
        {
            DLog(@"Not Good!!!!");
        }
        @finally {
            DLog(@"CLOSE CONNECTION!!!!!");
            // set state to session destroyed
            [self setCurrentState:kSessionDestroyed];
            
            // clean up terminated sessions from sessions list
            [SessionManager cleanUpSessions];
        }
        
    });
}

#pragma mark - FHConnectionDelegate implementation

/**
 * Called when the first render frame has been received.
 *
 * @param (SessionConnection *)theConnection - session connection that has received
 * the first render.
 */
- (void)firstRenderReceived:(SessionConnection *)theConnection
{
    // decrement number of pending service connections
    pendingServiceConnections--;
    
    // set session connected flag
    isConnected = TRUE;
    DLog(@"FHConnectionUtitlity::firstRenderReceived");
    [delegate firstRenderReceived:theConnection];
    
    // let connection delegate know that connection is now active
    if([self.connectionUtilityDelegate respondsToSelector:@selector(connectionReadyToStream)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connectionUtilityDelegate connectionReadyToStream];
        });
    }
    
    DLog(@"FHConnectionUtitlity::firstRenderReceived done");
}

/**
 * Connection status change
 * Called when there is any change in connection status.
 *
 * @param (SessionConnection *)theConnection - connection whose status has changed.
 * @param (connectionStates)theState - the state that the connection has changed to.
 * @param (NSString *)theMessage - the message about the connection state change.
 */
- (void)connectionStatusChange:(SessionConnection *)theConnection toState:(connectionStates)theState withMessage:(NSString *)theMessage
{
    switch (theState)
    {
        case kConnConnectionFailed:
        {
            // set state to connection closed
            [self setCurrentState:kSessionFailed];
        }
            break;
            
        case kConnConnectionDiedUnexpectedly:
        {
            // only show error dialog if session is not already closed
            if ([self currentState]<kSessionClosed)
            {
                // set state to connection connected closed
                [self setCurrentState:kSessionClosed];

                // send error message
                NSString* connectionString = [NSString stringWithFormat:@"Connection to session (%@) was lost!", [self sessionName]];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:connectionString forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:kSessionErrorDomain code:kConnectionStatusDiedUnexpectedlyCode userInfo:userInfo];
                [connectionUtilityDelegate connectionDidFailWithError:error];
            }
        }
            break;
            
        case kConnConnectedOK:
        {
            // set state to connection connected ok
            [self setCurrentState:kSessionActive];
        }
            break;
            
        case kConnConnectedSlow:
        {
            // set state to connection connected ok
            [self setCurrentState:kSessionActive];
        }
            break;
            
        case kConnConnectionClosedNormally:
        {
            // set state to connection closed
            [self setCurrentState:kSessionClosed];
            // release connection and view
            [self dropConnectionAndView];
        }
            break;
            
        default:
            break;
    }
    
    // send information to Session delegate
    [delegate connectionStatusChange:theConnection toState:theState withMessage:theMessage];
    
}

/**
 * Check if view is currently being created for a session
 *
 * @return (BOOL) - TRUE if the view for the session is currently being created
 */
- (BOOL)viewIsBeingCreated
{
    return bViewBeingCreated;
}

/**
 * Set current state of session view
 * Stores view state to provide information about how view is currentlu displayed.
 *
 * @param (SessionViewState) - view state tp assogm tp view
 */
- (void)setCurrentViewState:(SessionViewState)viewState
{
    [view setCurrentState:viewState];
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
