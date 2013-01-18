//
//  SessionView.h
//  Launchpad
//
//  SessionView class used to manage a Framehawk session view
//  Manages a single session view
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "FHUIView.h"

/**
 * Session View states
 */
typedef enum {
    kSessionViewInactive,
    kSessionViewFullyOnscreen,
    kSessionViewPartiallyOnscreen,
    kSessionViewFullyOffscreen,
    kSessionViewObscured,
} SessionViewState;

/**
 * Session View class
 */
@interface SessionView : NSObject
{
    FHUIView* view;                         // Framehawk connection view
    SessionViewState currentState;          // Session view state
}

@property SessionViewState currentState;    // Session view state

/**
 * Init Session View.
 *
 * @param (CGRect)frame - frame for session view.
 */
- (id)initWithFrame:(CGRect)frame;

/**
 * Set delegate for session view.
 *
 * @param (id)theDelegate - delegate for session view.
 */
-(void)setDelegate:(id)theDelegate;

/**
 * Update Mouse position within view.
 *
 * @param (int)x - x-position to set mouse within view.
 * @param (int)y - y-position to set mouse within view.
 */
- (void) updateMousePosition:(int)x y:(int)y;


/**
 * Mark Sesion View as needing redrawn.
 */
- (void) setNeedsDisplay;

/**
 * Session View renderer.
 *
 * @return (id) - renderer for view.
 */
- (id) renderer;

/**
 * Get frame for view.
 *
 * @return (CGRect) - frame for view
 */
- (CGRect)frame;

/**
 * Set frame for view.
 *
 * @param (CGRect)theFrame - frame to set for view.
 */
- (void)setFrame:(CGRect)theFrame;

/**
 * Get superview for session view.
 *
 * @return (UIView*) - view for session
 */
- (UIView*)superview;

/**
 * Remove view from superview.
 */
- (void)removeFromSuperview;

/**
 * Disable zoom for Session View.
 */
- (void) disableZoom;

/**
 * Enable zoom for Session View.
 */
- (void) enableZoom;

/**
 * Check if Session View is zoomed in.
 *
 * @return (BOOL) - set to TRUE if view is zoomed in.
 */
- (BOOL) isZoomed;

/**
 * Toggle show/hide mouse cursor.
 *
 * @param (BOOL)b - set to TRUE if want to show mouse cursor.
 *                - set to FALSE if want to hide mouse cursor.
 */
- (void) setDisplayMouseCursor:(BOOL)b;

/**
 * Toggle 'halo' mouse effect.
 * The halo is visual feedback immediately after the user touches the screen.
 *
 * @param (BOOL)b - set to TRUE if want to show halo effect.
 *                - set to FALSE if do not want to show halo effect.
 */
- (void) setHaloMouseCursor:(BOOL)b;

/**
 * Reset session view.
 */
- (void) reset;

/**
 * Set session view as hidden.
 *
 * @param (BOOL)b - set to TRUE to hide session view
 */
- (void)setHidden:(BOOL)b;

/**
 * Convert point from specified view coordinates to session view coordinates.
 *
 * @param (CGPoint)thePoint - point to convert.
 * @param (UIView *)fromView - view to convert from.
 *
 * @return (CGPoint)point - original point convert to coordinates in session view.
 */
- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;

/**
 * Get session view.
 *
 * @return (FHUIView*) - view for session.
 */
- (FHUIView*)getView;

@end
