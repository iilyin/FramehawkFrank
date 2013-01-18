//
//  NavigationCommands.h
//  Framehawk
//
//  Created by Hursh Prasad on 4/14/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef enum {
    MC_IDLE,
    MC_SESSION_READY_TO_OPEN,
    MC_SESSION_READY_TO_CLOSE,
    MC_SESSION_NEEDS_REVERSE_PROXY,
    MC_SESSION_CANCEL_REVERSE_PROXY,
    MC_SESSION_START_REVERSE_PROXY_SERVICE,
    MC_SESSION_CLOSE_REVERSE_PROXY,
    MC_SESSION_READY_TO_SCROLLTO,
    MS_APPLICATION_OPEN_ERROR
} Menu_Command_State;

// Service Type
typedef enum {
    kFramehawkVDIService        = 1,
    kFramehawkBrowserService    = 2,
    kNativeBrowserService       = 3,
} Service_Type;

// Service Keyboard Type
typedef enum {
    kBrowserKeyboard            = 1,
    kVDIKeyboard                = 2,
} Keyboard_Type;


@interface MenuCommands : NSObject{
    Menu_Command_State  mState;
    NSMutableString     *error;
    NSArray* _cmds;
}

@property (strong, nonatomic) NSArray* cmds; 
@property (assign)          Menu_Command_State   state;
@property (atomic)          NSMutableString     *error;
@property (nonatomic)       NSDictionary        *launchpadProfile;
@property (strong, nonatomic) NSDictionary      *selectedCommand;
@property (strong,atomic)   NSMutableArray      *openSessions;
@property (atomic)          NSNumber            *closeIndex;
@property (atomic)          NSNumber            *goToIndex;
@property (atomic)          UIColor             *menuGroupTextColor;
@property (atomic)          UIColor             *menuUnselectedTextColor;
@property (atomic)          UIColor             *menuSelectedTextColor;
@property (atomic)          UIImage             *menuRowDividerImage;

@property (atomic)          BOOL                cookiesAreSet;

+(MenuCommands *)get;

-(void)clearCommandsWhenSwitchingProfile;

-(void)clearAllSessions;

-(void)setUpCommandForCurrentProfile;

+(int)getNumberOfCommands;

+(int)getNumberOfOpenCommands;

+(int)getIndexOfOpenSession:(NSString *)command;

+(BOOL)checkIfCommandIsOpen:(NSString *)command;

+(NSArray *)getAllInternalSessionCommands;

-(NSDictionary*) getCommandWithName:(NSString*)name;

-(int)getCommandIndex:(NSString*)command;

- (void)setSelectedCommandForSessionName:(NSString*)sessionName;

-(BOOL)openApplication:(NSString *)applicationName withOption:(NSDictionary *)option;

-(void)closeApplication:(NSString *)applicationName;

-(BOOL)deleteSession:(NSNumber *)index;

-(UIView *)getViewAtIndex:(int)index;

-(void)dissmissRSAPrompt;

-(BOOL)isProxyedServiceCommand:(NSString *)command;

-(void)startProxyedService:(NSString *)command;

-(void)checkForStaleCookie;

- (void)saveSelectedCommand;

- (void)saveCommand:(NSDictionary*)command;

- (BOOL)selectedCommandIsFramehawk;

- (BOOL)selectedCommandIsFramehawkVDI;

- (BOOL)selectedCommandIsFramehawkBrowser;

- (BOOL)selectedCommandUsesVDIKeyboard;

- (BOOL)selectedCommandUsesBrowserKeyboard;

- (UIViewController*)getCurrentSession;

/**
 * Get session view controller with specified key
 *
 * @param (SessionKey) - session key of session to get view controller for
 *
 * @return (UIViewController*) - view controller for session with specified key
 *                             - nil if no session found with specified key
 */
- (UIViewController*)getSessionViewControllerWithKey:(id)sessionKey;

+ (NSArray*)getAllFramehawkSessionCommands;

-(void)sendMenuEdgeCaseTouch:(UIView*)view location:(CGPoint)point;

@end