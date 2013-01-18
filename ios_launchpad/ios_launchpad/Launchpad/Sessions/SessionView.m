//
//  SessionView.m
//  Launchpad
//
//  SessionView class used to manage a Framehawk session view
//  Manages a single session view
//
//  Created by Rich Cowie on 11/7/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "SessionView.h"
#import "FHView.h"


// User credentials table layout information
static const double kDefaultZoomScale                       = 1.0f;
static const double kMaximumZoomScale                       = 1.75f;

/**
 * Session View class
 */
@implementation SessionView

@synthesize currentState;   // Session view state

/**
 * Init Session View.
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if(nil != self)
    {
        view = [[FHUIView alloc] initWithFrame:frame];
        
        [view setHaloMouseCursor:NO];
        
        [view setClipsToBounds:YES];
        [view setContentOffset:CGPointZero];
        [view setContentSize:CGSizeMake(frame.size.width, frame.size.height)];
        [view setScrollEnabled:NO];
        [view setBounces:NO];
        [view setAlwaysBounceHorizontal:NO];
        [view setAlwaysBounceVertical:NO];
        [view setMinimumZoomScale:kDefaultZoomScale];
        [view setMaximumZoomScale:kMaximumZoomScale];
        [view setBouncesZoom:NO];
    }
    
    return self;
}

/**
 * Deallocation clean up
 */
- (void)dealloc
{
    view = nil;
}



/**
 * Set delegate for session view.
 *
 * @param (id)theDelegate - delegate for session view.
 */
-(void)setDelegate:(id)theDelegate
{
    // set session view delegate
    [view setDelegate:theDelegate];
}

/**
 * Update Mouse position within view.
 *
 * @param (int)x - x-position to set mouse within view.
 * @param (int)y - y-position to set mouse within view.
 */
- (void) updateMousePosition:(int)x y:(int)y
{
    [view updateMousePosition:x y:y];
}

/**
 * Mark Sesion View as needing redrawn.
 */
- (void) setNeedsDisplay
{
    [view setNeedsDisplay];
}

/**
 * Session View renderer.
 *
 * @return (id) - renderer for view.
 */
- (id) renderer
{
    return [view renderer];
}

/**
 * Get frame for view.
 *
 * @return (CGRect) - frame for view
 */
- (CGRect)frame
{
    return view.frame;
}

/**
 * Set frame for view.
 *
 * @param (CGRect)theFrame - frame to set for view.
 */
- (void)setFrame:(CGRect)theFrame
{
   view.frame = theFrame;
}

/**
 * Get superview for session view.
 *
 * @return (UIView*) - view for session
 */
- (UIView*)superview
{
    return [view superview];
}


/**
 * Remove view from superview.
 */
- (void)removeFromSuperview
{
    [view removeFromSuperview];
}


/**
 * Disable zoom for Session View.
 */
- (void) disableZoom
{
    [view setMaximumZoomScale:kDefaultZoomScale];
    [view setMinimumZoomScale:kDefaultZoomScale];
}

/**
 * Enable zoom for Session View.
 */
- (void) enableZoom
{
    [view setMinimumZoomScale:kDefaultZoomScale];
    [view setMaximumZoomScale:kMaximumZoomScale];
}

/**
 * Check if Session View is zoomed in.
 *
 * @return (BOOL) - set to TRUE if view is zoomed in.
 */
- (BOOL) isZoomed
{
    return ([view zoomScale]!=kDefaultZoomScale);
}

/**
 * Toggle show/hide mouse cursor.
 *
 * @param (BOOL)b - set to TRUE if want to show mouse cursor.
 *                - set to FALSE if want to hide mouse cursor.
 */
- (void) setDisplayMouseCursor:(BOOL)b
{
    [view setDisplayMouseCursor:b];
}

/**
 * Toggle 'halo' mouse effect.
 * The halo is visual feedback immediately after the user touches the screen.
 *
 * @param (BOOL)b - set to TRUE if want to show halo effect.
 *                - set to FALSE if do not want to show halo effect.
 */
- (void) setHaloMouseCursor:(BOOL)b
{
    [view setHaloMouseCursor:b];
}

/**
 * Reset session view.
 */
- (void) reset
{
    [view setContentOffset:CGPointZero animated:NO];
    [view setZoomScale:kDefaultZoomScale];
    [view setScrollEnabled:NO];
}

/**
 * Set session view as hidden.
 *
 * @param (BOOL)b - set to TRUE to hide session view
 */
- (void)setHidden:(BOOL)b
{
    [view setHidden:b];
}

/**
 * Convert point from specified view coordinates to session view coordinates.
 *
 * @param (CGPoint)thePoint - point to convert.
 * @param (UIView *)fromView - view to convert from.
 *
 * @return (CGPoint)point - original point convert to coordinates in session view.
 */
- (CGPoint)convertPoint:(CGPoint)thePoint fromView:(UIView *)fromView
{
    CGPoint convertedPoint;
    
    convertedPoint = [fromView convertPoint:thePoint toView:view];
    
    return convertedPoint;
}

/**
 * Get session view.
 *
 * @return (FHUIView*) - view for session.
 */
- (FHUIView*)getView
{
    return view;
}

@end
