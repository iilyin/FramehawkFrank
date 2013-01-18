//
//  FHServiceView.m
//  Launchpad
//
//  Wrapper for FHView used to access main view
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "UIKit/UIGestureRecognizerSubclass.h"
#import "FHServiceView.h"
#import "SessionView.h"
#import "AppDelegate.h"

#define kDefaultTopColor [UIColor blackColor]
#define kDefaultBottomColor [UIColor whiteColor]

// Double taps that occur rapidly within a specified period of time & within a specified
// distance will send the second tap message with the exact same tap location as the initial tap

// The maximum time between taps that will mean any previous cached tap will be used
// for location of second point in a double tap
#define DOUBLE_TAP_USE_CACHED_INTERVAL              0.3
// The maximum distance between two taps, for the second tap to use the previous cached tap point
// This will prevent two quick taps that are on opposite sides of the screen
// from being sent to same point
#define DOUBLE_TAP_MAXIMUM_DISTANCE_TO_USE_CACHE    80.0


/**
 * Tap gesture recognizer descendant. The only purpose of subclassing is
 * to distinguish our gesture recognizers (attached to the FH view)
 * from other recognizers attached by the framework.
 */
@interface RAVTapGestureRecognizer : UITapGestureRecognizer
@end
@implementation RAVTapGestureRecognizer
@end

/**
 * Placeholder for the FrameHawk drawing canvas (rendering target).
 */
@interface FHServiceView ()

/**
 * Initialize the FH placeholder view.
 */
- (void) initializeInfrastructure;

/**
 * Get the FrameHawk drawable out of the underlying FrameHawk view
 */
- (UIView*) getFHDrawable;

/**
 * Handle single taps over the FrameHawk drawing canvas
 */
- (void) handleTap:(UITapGestureRecognizer *)recognizer;

/**
 * Drop all the hand-crafted recognizers, attached to the given view
 */
- (void) dropRecognizers:(UIView*)view;

/**
 * Calculates and sets the scaleFactor.
 * @param view View which frame will be used to calculate scaleFactor.
 */
- (void)calculateScaleFactorsForView:(UIView *)view;

/**
 * Applies the scale using calculated scaleFactor
 * @param view View which will be used to apply scaleFactor to.
 */
- (void)applyScaleFactorsToView:(UIView *)view;

- (void)setFHAlignment;

@end

@implementation FHServiceView

@synthesize fhView;
@synthesize tapDelegate;
@synthesize fhPolicy;

@synthesize singleColored;
@synthesize autoscroll;
@synthesize autoResetContentOffset;

@synthesize serviceName;

#pragma mark - Initialization stuff

/**
 * Designated initializer for the FrameHawk placeholer
 */
- (id)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) == nil )
        return nil;
    [self initializeInfrastructure];
    return self;
}

/**
 * Initialize view instance, recovered from the XIB file.
 */
- (id) initWithCoder:(NSCoder *)aDecoder
{
    if( (self = [super initWithCoder:aDecoder]) == nil )
        return nil;
    [self initializeInfrastructure];
    return self;
}

/**
 * Release acquire resources.
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    DLog(@"FHServiceView Dealloc: %@", [self description] );
    self.tapDelegate = nil;
    if( self.fhView.superview == self )
    {
        [self.fhView removeFromSuperview];
//        self.fhView = nil;
    }
#ifdef DEBUG
    else if( self.fhView )
    {
        DLog(@"RemoteAppView: on deallocate the fhView is not NULL and mapped to another placeholder!!!" );
    }
#endif
    
    topColor = nil;
    bottomColor = nil;
}

#pragma mark - Configuration stuff

/**
 * Accessor methods for the underlying FrameHawk drawing canvas.
 */
- (SessionView*) fhView
{
    return fhView;
}

- (void) setFhView:(SessionView *)view
{
    if( fhView )
    {
        // just remove it from superview: see willRemoveFromSuperview method of this class
        [fhView removeFromSuperview];
    }
    fhView = view;
    
    DLog(@">>>> setFhView: %fx%f!", [fhView frame].size.width, [fhView frame].size.height );

    // if view is nil then do nothing
    if( fhView == nil )
        return;

    // previous holder of the FH view should be informed!!!
    FHServiceView* rvp = (FHServiceView*) fhView.superview;
    if( [rvp isKindOfClass:[FHServiceView class]] )
    {
        rvp.fhView = nil;
    }
#ifdef DEBUG
    else if( rvp )
    {
        DLog(@"RemoteAppView: previous holder of the fhView is not RemoteAppView instance!" );
    }
#endif
    
    // assign scroll view delegate
    [fhView setDelegate:(id<UIScrollViewDelegate>)self];
    
    // assign gesture recognizers to the view
    UIView* fhCanvas = [self getFHDrawable];
    DLog(@"RemoteViewPlaceholder %p, Canvas = %@", self, fhCanvas);
    if( fhCanvas != nil )
    {
        fhCanvas.userInteractionEnabled = YES;
        [self dropRecognizers:fhCanvas];
        
        // long press recognizer for selection and dragging
        // this is a dummy event used to prevent single tap being
        // sent when a single long press is occuring
        UILongPressGestureRecognizer *oneFingerLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerLongPress:)];
        oneFingerLongPressRecognizer.numberOfTouchesRequired = 1;
        oneFingerLongPressRecognizer.cancelsTouchesInView = NO;
        [fhCanvas addGestureRecognizer:oneFingerLongPressRecognizer];

        //  Single Tap Recognizer
        RAVTapGestureRecognizer *tap = [[RAVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        // this is to prevent a single tap being sent along with a long press
        [tap requireGestureRecognizerToFail: oneFingerLongPressRecognizer];
        [fhCanvas addGestureRecognizer:tap];
        tap = nil;
    }
    
    // actually add the FrameHawk view to the placeholder
    [self setFHAlignment];
    
    if((self.fhPolicy & FHPolicyScaled) || (self.fhPolicy & FHPolicyScaledAspectRatioLost))
    {
        [self calculateScaleFactorsForView:[fhView getView]];
        [self applyScaleFactorsToView:[fhView getView]];
    }
    [fhView reset];
    [self addSubview:[fhView getView]];
    [self sendSubviewToBack:[fhView getView]];
//[self bringSubviewToFront:[fhView getView]];
}

/**
 * Sets the top and bottom colors of the view's background.
 * @param aTopColor Color of the top half of the view's background.
 * @param aBottomColor Color of the bottom half of the view's background. May be nil.
 */
- (void)setBackgroundTopColor:(UIColor *)aTopColor bottomColor:(UIColor *)aBottomColor
{
    if(nil != aTopColor)
        topColor = aTopColor;
    if(nil != aBottomColor)
        bottomColor = aBottomColor;
}

- (void)setFHAlignment
{
    CGRect frm = self.fhView.frame;
    DLog(@">>>> setFHAlignment: %fx%f!", frm.size.width, frm.size.height );
    if (frm.size.width<frm.size.height)
        DLog(@">>>> Width less than height!" );
    
    // If FHPolicyCentered - draw FHView on the center of its placeholder
    if(self.fhPolicy & FHPolicyCentered)
    {
        CGRect sFrm = self.bounds;
        frm.origin.x = (sFrm.size.width - frm.size.width) / 2.0f;
        frm.origin.y = (sFrm.size.height - frm.size.height) / 2.0f;
    }
    else // If not centered - analyse possible variants
    {
        // If draw bottom-aligned
        if(self.fhPolicy & FHPolicyAlignedToBottom)
        {
            CGRect sFrm = self.bounds;
            
            frm.origin.x = 0.;
            frm.origin.y = sFrm.size.height - frm.size.height;
        }
        else // Draw top aligned (not centered, not bottom-aligned).
        {
            frm.origin.x = 0.;
            frm.origin.y = 0.;
        }
    }
    if( !CGRectEqualToRect(frm, self.fhView.frame) )
    {
        [self.fhView setFrame:frm];
        DLog(@"remote view placeholder set fhview frame to %f, %f, %f, %f", frm.origin.x, frm.origin.y, frm.size.width, frm.size.height);
    }
}

#pragma mark - UIView housekeeping stuff

/**
 * Handle the situations when this view becomes visible or not
 * @param newWindow Window object which is about to change
 */
- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if(nil == newWindow)
    {
        // Assuming this view goes from the top of visible hierarchy
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
    else 
    {
        if(self.window != newWindow)
        {
            // Assuming the view becomes top view in the visible hierarchy
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        }
    }
}

/**
 * Handle the situations when FH view is remapped to another placeholder.
 */
- (void)willRemoveSubview:(UIView *)subview
{
    if( subview == [self.fhView getView] )
    {
        // drop gesture recognizers, assigned to the drawing canvas
        UIView* fhCanvas = [self getFHDrawable];
        [self dropRecognizers:fhCanvas];
        // reassign the scroll view delegate
        [self.fhView setDelegate:self.fhView];
    }
}
 
/**
 * Layout the FrameHawk view on the placeholder
 */
- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (autoResetContentOffset)
    {
        [[self.fhView getView] setContentOffset:CGPointZero animated:NO];
        DLog(@"remote view placeholder reset fhview content offset");
    }
    
    [self setFHAlignment];
}

/**
 * The view content refresh method.
 */
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
 
    // render background rectangle
    if(self.singleColored)
    {   // display background as a single color
        CGContextSetFillColorWithColor(gc, [topColor CGColor]);
        CGContextFillRect(gc, rect);
    }
    else 
    {
        // display background split into to different colored rectangles, one on top of the other
        CGRect topRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height / 2.0f);
        CGRect bottomRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height / 2.0f, self.bounds.size.width, self.bounds.size.height / 2.0f);
        
        CGContextAddRect(gc, topRect);
        CGContextSetFillColorWithColor(gc, [topColor CGColor]);
        CGContextFillPath(gc);
        
        CGContextAddRect(gc, bottomRect);
        CGContextSetFillColorWithColor(gc, [bottomColor CGColor]);
        CGContextFillPath(gc);
    }
}

#pragma mark - Public APIimplementation 

/**
 * Get distance between 2 points
 *
 * @param (CGPoint)pt1 - first point
 * @param (CGPoint)pt2 - second point
 *
 * @return (CGFloat) - distance between two specified points
 */
-(CGFloat) distanceBetweenTwoPoints:(CGPoint)pt1 point2:(CGPoint)pt2
{
    CGFloat dx = pt2.x - pt1.x;
    CGFloat dy = pt2.y - pt1.y;
    return sqrt(dx*dx + dy*dy );
};

#pragma mark - Action handlers

#pragma mark Gesture handling

/**
 * Handle single finger long press over the FrameHawk drawing canvas
 */
- (void) oneFingerLongPress:(UITapGestureRecognizer *)recognizer
{
}

/**
 * Handle single taps over the FrameHawk drawing canvas
 */
- (void) handleTap:(UITapGestureRecognizer *)recognizer
{
    UIView* fhCanvas = [self getFHDrawable];
    switch(recognizer.state)
    {
        case UIGestureRecognizerStateEnded:
            {
                // get current time
                NSDate *currentTime = [NSDate date];
                // calculate time since last tap occurred
                NSTimeInterval timeSinceLastTap = [currentTime timeIntervalSinceDate:timeLastTapOccurred];
                // get current tap location
                CGPoint currentTapLocation = [recognizer locationInView:fhCanvas];

                DLog(@"Time since last tap: %f", timeSinceLastTap);
                // if this is first tap, or tap is occurring outside of double tap time
                // or tap is far enough away from previous tap location
                // then set tap to current location, otherwise use cached tap location
                if ((nil==timeLastTapOccurred)  ||
                    (timeSinceLastTap >= DOUBLE_TAP_USE_CACHED_INTERVAL) ||
                    ([self distanceBetweenTwoPoints:lastCachedTapLocation point2:currentTapLocation]>DOUBLE_TAP_MAXIMUM_DISTANCE_TO_USE_CACHE)
                    )
                {
                    DLog(@"*********** NEW TAP LOCATION **************");
                    DLog(@"FHServiceView=%@ 0x%x", [self description], (int)self);
                    lastCachedTapLocation = currentTapLocation;
                    // set last tap time to current time
                    timeLastTapOccurred = currentTime;
                }
                else
                {
                    DLog(@"*********** OLD TAP LOCATION **************");
                    // clear last tap time to force a new tap location next time
                    // this way only a double tap will occur in the same location
                    // preventing constant tapping across screen caching in same location
                    timeLastTapOccurred = nil;
                }
                
                // send tap value
                [self.tapDelegate singleTapDetected:lastCachedTapLocation];

            }
            break;
        default:
            break;
    }
}

#pragma mark - Utility routines

/**
 * Initialize the FH placeholder view.
 */
- (void) initializeInfrastructure
{
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.clipsToBounds = YES;
    self.opaque = YES;
    self.contentMode = UIViewContentModeRedraw;
    
    // clear scale value
    scaleFactorW = 1.0;
    scaleFactorH = 1.0;
    
    // set single color background
    self.singleColored = YES;
    topColor = kDefaultTopColor;
    bottomColor = kDefaultBottomColor;
 
    // clear delegate for sending tap information to
    self.tapDelegate = nil;
    
    self.autoscroll = YES;
    
    self.autoResetContentOffset = YES;
}

/**
 * Get the FrameHawk drawable view out of the underlying FrameHawk view
 *
 * @return (UIView*) - view that service is drawn to
 */
- (UIView*) getFHDrawable
{
    // if no view assigned return nil
    if( self.fhView == nil )
        return nil;
    
    UIView* fhCanvas = (UIView*) (self.fhView.renderer);
    if( [fhCanvas isKindOfClass:[UIView class]] )
        return fhCanvas;
    
    // search for Framehawk canvas in subviews
    for( fhCanvas in [[self.fhView getView] subviews] )
    {
        if( [fhCanvas conformsToProtocol:@protocol(FHRenderer)] )
            return fhCanvas;
    }

    // return nil
    return nil;
}

/**
 * Drop all the hand-crafted recognizers, attached to the given view
 */
- (void) dropRecognizers:(UIView*)view
{
    NSArray* recogArr = [NSArray arrayWithArray:view.gestureRecognizers];
    for( UIGestureRecognizer* gr in recogArr )
    {
        if( [gr isKindOfClass:[RAVTapGestureRecognizer class]] )
        {
            [view removeGestureRecognizer:gr];
        }
    }
}

/**
 * Enable or disable touch feedback halo
 *
 * @param (BOOL)show - TRUE if want to display Halo feedback
 */
- (void)showHalo:(BOOL)show
{
    [self.fhView setDisplayMouseCursor:!show];
    [self.fhView setHaloMouseCursor:show];
}

#pragma mark - UIScrollView delegate implementation

/**
 * Forward (at least try to) unknown (probably UIScrollViewDelegate)
 * invocations to the underlying fhView (which is self-delegated scroll-view descendant).
 * This is done for not to overwrite all the delegate methods, but intercept only
 * those, related to zooming.
 */
- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
    
    if ([self.fhView respondsToSelector:aSelector])
        [invocation invokeWithTarget:self.fhView];
    else
        [self doesNotRecognizeSelector:aSelector];
}

/**
 * Prepare the method signature for selctors, known to us and to our underlying
 * fhView - scroll-view delegate.
 */
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (!signature)
    {
        signature = [self.fhView methodSignatureForSelector:selector];
    }
    return signature;
}

/**
 * Provide the view to scale when zooming is about to occur in the scroll view.
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if( [self.fhView getView] == scrollView && [[self.fhView getView] respondsToSelector:@selector(viewForZoomingInScrollView:)] )
    {
        return [[self.fhView getView] viewForZoomingInScrollView:scrollView];
    }
    return nil;
}

/**
 * Handle the scroll view’s zoom factor changed.
 * Allow fhView scrolling only if it's zoom factor is 1.
 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if( [self.fhView getView] == scrollView && [[self.fhView getView] respondsToSelector:@selector(scrollViewDidZoom:)] )
    {
        [[self.fhView getView] scrollViewDidZoom:scrollView];
    }

    if (![self.fhView isZoomed])
    {   // allow scroll
        AppDelegate* a = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [a.viewController.scrollView enableSwipeBetweenSessions];
    }
    else
    {   // disable scroll
        AppDelegate* a = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [a.viewController.scrollView disableSwipeBetweenSessions];
    }
    
/*    
    CGRect fullFrame = self.bounds;
    if(self.fhView.zoomScale != 1.0)
    {
        [self.fhView setScrollEnabled:YES];
        CGSize sz = fullFrame.size;
        sz.width *= self.fhView.zoomScale;
        sz.height *= self.fhView.zoomScale;
        [self.fhView setContentSize:sz];
    }
    else
    {
        [self.fhView setScrollEnabled:NO];
        [self.fhView setContentSize:fullFrame.size];
        [self.fhView setContentOffset:CGPointZero animated:NO];
    }
*/
}

#pragma mark - Scaling methods

- (void)calculateScaleFactorsForView:(UIView *)view {
    scaleFactorW = self.frame.size.width / view.frame.size.width;
    if(self.fhPolicy & FHPolicyScaled)
    {
        // Just use the same
        scaleFactorH = scaleFactorW;
    }
    if(self.fhPolicy & FHPolicyScaledAspectRatioLost)
    {
        scaleFactorH = self.frame.size.height / view.frame.size.height;
    }
}

- (void)applyScaleFactorsToView:(UIView *)view {
    CGAffineTransform scale = CGAffineTransformMakeScale(scaleFactorW, scaleFactorH);
    view.transform = scale;
}

#pragma mark - Keyboard will show notification received

/**
 * Called when keyboard will be appear after being opened
 */
- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.autoscroll)
        return;
    
    // reset scroll on visible service view area not covered by keyboard
    totalKeyboardViewScrollY = 0.0f;

    // get additional information about keyboard will show notification
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];

    // get keyboard frame size (adjusted for orientation)
    CGRect orientatedKeyboardFrame = [self convertRect:keyboardFrame toView:nil];
    CGRect panelRect = self.frame;
    
    // store keyboard height
    keyboardHeight = orientatedKeyboardFrame.size.height;

    // calculate height of service view visible when keyboard is onscreen
    int viewHeight = self.frame.size.height;
    int panelHeightVisibleWhenKeyboardActive = (viewHeight - keyboardHeight);
    
    DLog(@"$KeyBoard Frame:%@ Panel Rect:%@ offsetY:%f",NSStringFromCGRect(keyboardFrame),NSStringFromCGRect(panelRect), initialViewYOffsetWhenKeyboardActive);
    
    // TODO: Remove????
//    if (keyboardFrame.origin.x == -352 || keyboardFrame.origin.x == 718) {
//        [self keyboardWillHide:nil];
//        return;
//    }
    
    // default initial view y-offset to zero, so bottom of service view shifts up with keyboard
    initialViewYOffsetWhenKeyboardActive = 0.0;
    
    DLog(@"KBUp FHServiceView=%@ 0x%x", [self description], (int)self);
    // if tapped service view 3/4s down or more in the region that will be visible
    // when the keyboard is onscreen, then adjust service view offset so keyboard
    // doesn't obscure the last tapped area
    if (lastCachedTapLocation.y > (panelHeightVisibleWhenKeyboardActive * .75) /* TODO: Remove??? && (keyboardFrame.origin.x == 0 || keyboardFrame.origin.x == 366)*/)
    {
        // default offset to entire height of keyboard (bottom of view flush with keyboard top)
        initialViewYOffsetWhenKeyboardActive = -keyboardHeight;
        
        // if adjusting offset to move last tap to center of view won't move view past bottom
        if ((lastCachedTapLocation.y + initialViewYOffsetWhenKeyboardActive) < (panelHeightVisibleWhenKeyboardActive / 2.0f))
        {
            // adjust offset so last tap location is centered in visible view region
            initialViewYOffsetWhenKeyboardActive += (panelHeightVisibleWhenKeyboardActive / 2.0f) - (lastCachedTapLocation.y + initialViewYOffsetWhenKeyboardActive);
        }

// TODO: remove???        if (panelRect.origin.y != -offsetY)
        {
            DLog(@"$Bringing Keyboard Up$");
            DLog(@"$ panelRect.origin.y=%f $", panelRect.origin.y);
            // set service view panel origin-y to new offset y
            panelRect.origin.y = initialViewYOffsetWhenKeyboardActive;
            DLog(@"$ offsetY=%f $", initialViewYOffsetWhenKeyboardActive);
            
            // animate screen panel to adjust for keyboard appearing
            [UIView animateWithDuration:animationDuration delay:0 options:animationCurve animations:
             ^{
                 // store service view offset adjusted for keyboard frame
                 [self setFrame:panelRect];
             }
            completion:
             ^(BOOL finished)
             {
                 DLog(@"$Brought Up Finished$");
             }]; 
        }
    }
}

/**
 * Called when keyboard will be hidden after being dismissed
 */
- (void)keyboardWillHide:(NSNotification *)notification
{
    // get additional information about keyboard will hide notification
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;

    // get information about keyboard animation
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];

    // if there is any scroll offset in the view below the keyboard then reset view offset
    if ((initialViewYOffsetWhenKeyboardActive != 0) || (totalKeyboardViewScrollY != 0)){
        
        // animate screen panel to adjust view service offset for keyboard disappearing
#if 0
        //CSP-40 Took out slide down animation vibrates screen in iOS 6
        [UIView animateWithDuration:animationDuration delay:0. options:animationCurve animations:
         ^{
#endif
             // set panel offset back to zero once keyboard if offscreen
             CGRect panelRect = self.frame;
             panelRect.origin.y = 0;//panelRect.origin.y + offsetY - totalKeyboardViewScrollY;
       //      DLog(@"$KeyBoard Down Hide Frame:%@ panelRect %@ offsetY %f notification %@",NSStringFromCGRect(keyboardFrame),NSStringFromCGRect(panelRect),offsetY,notification);

             [self setFrame:panelRect];
#if 0
         }
        completion:
         ^(BOOL finished)
         {
             DLog(@"$Brought Down Finished$");
             // set service view offset to zero, once keyboard is offscreen
             offsetY = 0;
         }];
#endif
    }
}

/**
 * Called when view goes offscreen after swiping
 */
- (void)viewGoesOffscreen
{
    // reset initial view y-offset for newly visible view
    initialViewYOffsetWhenKeyboardActive = 0.0;

    // clear last tapped location
    lastCachedTapLocation = CGPointZero;
}

/**
 * Description of service
 *
 * @return (NSString *) - description of service name
 */
-(NSString *)description
{
    // return service name
    return [NSString stringWithFormat:@"<ServiceName:%@>", serviceName];
}

/**
 * Called to scroll the view beneath the keyboard
 * Only performs scroll if not reached the top or bottom of service view
 *
 * @param (UIPanGestureRecognizer*)recognizer - pan gesture recognizer
 * @return (BOOL) - TRUE if region under keyboard can be scrolled more
 *                - FALSE if region has scrolled to edge so can pass scroll through to service
 */
- (BOOL)scrollViewUnderKeyboard:(UIPanGestureRecognizer*)recognizer
{
    // flag to detect if reached edge of view scroll limits
    bool bCanScrollMore = TRUE;

    // get pan gesture translation in view
    CGPoint translation = [recognizer translationInView:(UIView*)[self.fhView renderer]];
    
    // get current frame of service view panel
    CGRect panelRect = self.frame;
    
    // set current keyboard view scroll value to y-translation value
    currentGestureScrollY = translation.y;

    // don't allow visible view to scroll past top of service view
    if ((totalKeyboardViewScrollY + currentGestureScrollY + initialViewYOffsetWhenKeyboardActive) >= 0)
    {
        // clip total keyboard view scroll y-value to top of service view
        totalKeyboardViewScrollY = -initialViewYOffsetWhenKeyboardActive;

        // clear current gesture  scroll
        currentGestureScrollY = 0.0f;

        // set no more scrolling, so can now pass scroll gesture through to service
        bCanScrollMore = FALSE;
    }

    // don't allow visible view to scroll past bottom of service view
    if ((totalKeyboardViewScrollY + currentGestureScrollY + initialViewYOffsetWhenKeyboardActive) <= -keyboardHeight)
    {
        // clip total keyboard view scroll y-value to bottom of view
        totalKeyboardViewScrollY = -(keyboardHeight+initialViewYOffsetWhenKeyboardActive);

        // clear current gesture scroll
        currentGestureScrollY = 0.0f;
        
        // set no more scrolling, so can now pass scroll gesture through to service
        bCanScrollMore = FALSE;
    }

    // adjust view for scroll view within keyboard view
    panelRect.origin.y = totalKeyboardViewScrollY + currentGestureScrollY + initialViewYOffsetWhenKeyboardActive;
    [self setFrame:panelRect];

    // set total scroll offset of view when ending scroll
    if ((recognizer.state == UIGestureRecognizerStateEnded)
        || (recognizer.state == UIGestureRecognizerStateCancelled)
        || (recognizer.state == UIGestureRecognizerStateFailed)
    )
    {
        // add current offset to total keyboard view scroll
        totalKeyboardViewScrollY += currentGestureScrollY;
        // clear current gesture y scroll
        currentGestureScrollY = 0.0f;
    }
    
    // return whether can scroll view some more
    return bCanScrollMore;
}

/**
 * Called to get the scroll y-offset for the view beneath the keyboard
 *
 * @return (CGFloat) - additional scroll y-offset for view under the keyboard
 */
- (CGFloat)scrollYOffsetForViewUnderKeyboard
{
    return totalKeyboardViewScrollY + initialViewYOffsetWhenKeyboardActive;
}

@end
