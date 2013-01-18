//
//  FHServiceView.h
//  Launchpad
//
//  Wrapper for FHView used to access main view
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FHServiceView.h"

@class SessionView;

typedef enum TagFHSubviewPolicy 
{  
    FHPolicyNone = 0,
    FHPolicyCentered = 1 << 0,
    FHPolicyScaled = 1 << 1,
    FHPolicyScaledAspectRatioLost = 1 << 2,
    FHPolicyAlignedToBottom = 1 << 3
} FHSubviewPolicy;


#import <Foundation/Foundation.h>

@protocol FHServiceViewDelegate <NSObject>
@optional
/**
 * Handle a user tap.
 * @param tapLocation The tap location in the FH coordinate space.
 */
- (void)singleTapDetected:(CGPoint)tapLocation;

/**
 * Handle a scroll.
 * @param location The tap location in the FH coordinate space.
 * @param delta scrolling delta
 */
- (void)scrollDetected:(CGPoint)location andDelta:(CGFloat)delta;

@end


/**
 * Placeholder for the FrameHawk drawing canvas (rendering target).
 */
@interface FHServiceView : UIView
{
    SessionView*       fhView;           // the FrameHawk drawing canvas
    id<FHServiceViewDelegate> __weak tapDelegate;  // sink for tha tap events, detected over the placeholder? view
    
    FHSubviewPolicy fhPolicy;
    
    CGFloat scaleFactorW;   // Scale width factor
    CGFloat scaleFactorH;   // Scale height factor
    
    BOOL singleColored;     // If YES the background will be painted using only top color
    UIColor *topColor;      // Color of the top half of the view's background
    UIColor *bottomColor;   // Color of the bottom half of the view's background
    
    NSDate *timeLastTapOccurred;    // The time the last tap occurred
    CGPoint lastCachedTapLocation;  // The coordinates of the last tap by user on the remote content.

    // The intial offset of the view, when keyboard appears - based on last tap location.
    CGFloat initialViewYOffsetWhenKeyboardActive;
    // Total additional scroll y-offset of view, while scrolling when keyboard is active.
    CGFloat totalKeyboardViewScrollY;
    // Current y scroll for current scroll gesture when keyboard is active.
    CGFloat currentGestureScrollY;
    // Keyboard height when active
    CGFloat keyboardHeight;
    
    NSString* serviceName;  // service name (used for debugging)
}

@property (nonatomic, strong) SessionView* fhView;
@property (nonatomic, weak) id<FHServiceViewDelegate> tapDelegate;

@property (nonatomic, assign) FHSubviewPolicy fhPolicy;

@property (nonatomic, assign) BOOL singleColored;
@property (nonatomic) BOOL autoscroll;  // flag to disable auto-scroll of screen when keyboard activated e.g. when login assistant occurs

@property (nonatomic, assign) BOOL autoResetContentOffset;

@property (nonatomic) NSString* serviceName;


/**
 * Initialize the FH placeholder view.
 */
- (void) initializeInfrastructure;

/**
 * Sets the top and bottom colors of the view's background.
 * @param aTopColor Color of the top half of the view's background.
 * @param aBottomColor Color of the bottom half of the view's background. May be nil.
 */
- (void)setBackgroundTopColor:(UIColor *)aTopColor bottomColor:(UIColor *)aBottomColor;

/**
 * Shows halo effect or shows mouseCursor
 * @param show If YES - shows halo, else - mouse cursor
 */
- (void)showHalo:(BOOL)show;

/**
 * Called when view goes offscreen
 * adjusts settings for new view, including clearing offset if keyboard was visible
 */
- (void)viewGoesOffscreen;

/**
 * Get the FrameHawk drawable view out of the underlying FrameHawk view
 *
 * @return (UIView*) - view that service is drawn to
 */
- (UIView*) getFHDrawable;

/**
 * Called to scroll the view beneath the keyboard
 *
 * @param (UIPanGestureRecognizer*)recognizer - pan gesture recognizer
 * @return (BOOL) - TRUE if region under keyboard was scrolled
 */
- (BOOL)scrollViewUnderKeyboard:(UIPanGestureRecognizer*)recognizer;

/**
 * Called to get the scroll y-offset for the view beneath the keyboard
 *
 * @return (CGFloat) - y-offset for view under the keyboard
 */
- (CGFloat)scrollYOffsetForViewUnderKeyboard;

@end
