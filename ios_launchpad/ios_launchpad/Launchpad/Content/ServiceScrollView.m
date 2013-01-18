//
//  ServiceScrollerView.m
//  Framehawk
//
//  Scroller controller contains multiples sessions/services views.
//
//  Created by Hursh Prasad on 4/11/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "MenuCommands.h"
#import "FHServiceViewController.h"
#import "AppDelegate.h"
#import "UIUtils.h"

#import "BrowserServiceViewController.h"
#import "ServiceScrollView.h"
#import "ProfileDefines.h"

#define ScrollWidth  1024
#define ScrollHeight 768

// Page control format
#define ENABLE_PAGE_CONTROLS                1
#define PAGE_CONTROL_OVERLAY_HEIGHT         28
#define PAGE_CONTROL_OVERLAY_BUTTON_WIDTH   30
#define PAGE_CONTROL_OVERLAY_CORNER_RADIUS  12.0
#define PAGE_CONTROL_ALPHA_VALUE            0.2
#define PAGE_CONTROL_IDLE_TIMEOUT           0.0

@interface ServiceScrollView ()
@property (assign) CGPoint startLocation;
@end

@implementation ServiceScrollView

@synthesize currentIndex, totalActivePages, mainController, pageControl, startLocation;

/**
 * Set up scroll view
 */
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setContentSize:CGSizeMake(ScrollWidth, ScrollHeight)];
                
        [self setDelegate:self];
        
        
        self.showsHorizontalScrollIndicator = NO;
        self.pagingEnabled = YES;
        startLocation = CGPointMake(0, 0);
        self.delaysContentTouches = YES;
        self.canCancelContentTouches = NO;
        
        
        for (UIGestureRecognizer *g in self.gestureRecognizers) {
            if ([g isKindOfClass:[UIPanGestureRecognizer class]]) {
                ((UIPanGestureRecognizer *)g).maximumNumberOfTouches = 3;
                ((UIPanGestureRecognizer *)g).minimumNumberOfTouches = 2;
              }
        }
        
        self.scrollEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.userInteractionEnabled = YES;
        
        [[MenuCommands get] addObserver:self forKeyPath:@"state" options:0 context:nil];
    }
    
    return self;
}

/**
 * Asks if two gesture recognizers should be allowed to recognize gestures simultaneously.
 */
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
            
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        DLog(@" SHOULD SIM GESTURE TOUCH COUNT %d",((UIPanGestureRecognizer *)gestureRecognizer).numberOfTouches);
        if (((UIPanGestureRecognizer *)gestureRecognizer).numberOfTouches == 3) {
            return NO;
        }
        
        //Check to see if there is session is up - keep track of one time state
        if(!((FHServiceViewController *)[[MenuCommands get] getCurrentSession]).firstAppearCompleted){
            [self disableScroll];
            return NO;
        }else{
            [self enableScroll];
        }
    }
    
    /* Check if othergesture helps with fine grain control
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        DLog(@" SHOULD SIM OTHER GESTURE TOUCH COUNT %d",((UIPanGestureRecognizer *)otherGestureRecognizer).numberOfTouches);
    }*/

    return YES;
}

/**
 * Clean up on deallocation
 */
- (void) dealloc {
    MenuCommands* c = [MenuCommands get];
    [c removeObserver:self forKeyPath:@"state"];
}

#pragma mark -
#pragma mark ServiceScrollView Implementation

/**
 * Returns index of currently visible page
 */
- (NSInteger)currentIndex {
    NSInteger currentlyDisplayedPage = ([self contentOffset].x + (ScrollWidth/2))/ScrollWidth;

    DLog(@"currentlyDisplayedPage = %i", currentlyDisplayedPage);
    
    // limit current index to within number of open sessions
    int openSessions = [[[MenuCommands get] openSessions] count];
    if (currentlyDisplayedPage>=openSessions)
    {
        currentlyDisplayedPage = openSessions-1;
        if (currentlyDisplayedPage<0)
            currentlyDisplayedPage = 0;
    }
    
    DLog(@"currentlyDisplayedPage (mod) = %i of %i openSessions", currentlyDisplayedPage, openSessions);
    
    return currentlyDisplayedPage;
}

/**
 * Returns total number of currently active pages
 */
- (NSInteger)totalActivePages {
    MenuCommands* menu = [MenuCommands get];
    
    NSInteger totalOpenSessions = [menu.openSessions count];
    
    // return total number pf sessions (1 session per page)
    return totalOpenSessions;
}

/**
 * init up page control overlay
 */
- (void)showPageControl
{
    if (ENABLE_PAGE_CONTROLS)
    {
        // remove any existing page controls from view
        [pageControl removeFromSuperview];
        
        // create new page controller
        pageControl = [[UIPageControl alloc] init];
        [pageControl setBackgroundColor:[UIColor blackColor]];
        [pageControl setOpaque:YES];
        [pageControl setAlpha:PAGE_CONTROL_ALPHA_VALUE];
        [pageControl.layer setCornerRadius:PAGE_CONTROL_OVERLAY_CORNER_RADIUS];
        
        // set up page control selection (& resets page controller inactive timer)
        [self updatePageControl];
        
        // add page control to view
        [pageControl setAlpha:1.0];
        [self.superview addSubview:pageControl];
        // fade out page control
        [UIView animateWithDuration:PAGE_CONTROL_FADE_IN_OUT_TIME
                         animations:^{pageControl.alpha = 0.0;}
                         completion:^(BOOL finished){}];
    }
}


/**
 * updates page control overlay
 */
- (void)updatePageControl
{
    // set number of page dots
    [pageControl setNumberOfPages:[self totalActivePages]];
    // set current page dot to highlight
    [pageControl setCurrentPage:[self currentIndex]];
    
    // set up width of background
    CGRect f = pageControl.frame;
    CGRect b = self.superview.bounds;
    f.size.width = PAGE_CONTROL_OVERLAY_BUTTON_WIDTH * [self totalActivePages];
    f.size.height = PAGE_CONTROL_OVERLAY_HEIGHT;
    f.origin.x = b.size.width/2 - f.size.width/2;
    f.origin.y = b.size.height-b.size.height/8 - f.size.height/2;
    pageControl.frame = f;
}

#pragma mark Page Controller idle timer control
/**
 * Show spinning 'loading' controller at specified location
 */
- (void) showSpinViewAt: (NSInteger) idx {
    
    
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.frame = CGRectMake(20, 20, 50, 50);
    spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                UIViewAutoresizingFlexibleRightMargin |
                                UIViewAutoresizingFlexibleTopMargin |
                                UIViewAutoresizingFlexibleBottomMargin);
    
    
    UIImageView* v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"preloader_bg.png"]];
    [v sizeToFit];

    v.frame = CGRectMake(ScrollWidth*idx+512-v.frame.size.width/2, 100, v.frame.size.width, v.frame.size.height); 
    [self addSubview:v];    
    
    [v addSubview:spinner];
    [spinner startAnimating];
    
    [UIView animateWithDuration:3
                          delay:0
                        options:UIViewAnimationOptionTransitionCrossDissolve 
                     animations:^{
                         v.alpha = .4;
                     }
                     completion:^(BOOL finished) {
                         [v removeFromSuperview];
                     }];
}

/**
 * message is sent to the receiver when the value at the specified key path relative to the given object has changed
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGRect frame;
    switch ([MenuCommands get].state) {
        case MC_SESSION_NEEDS_REVERSE_PROXY:
        case MC_SESSION_READY_TO_OPEN:{
            
            // position session at end of open commands
            UIViewController *controller = [[[MenuCommands get] openSessions] lastObject];
            frame = controller.view.frame;
            int numberOfOpenSessions = [MenuCommands getNumberOfOpenCommands];
            frame.origin.x = ScrollWidth * (numberOfOpenSessions - 1);
            controller.view.frame = frame;
            
            // adjust contrent size to new number of open sessions
            [self setContentSize:CGSizeMake(ScrollWidth * ([MenuCommands getNumberOfOpenCommands]), ScrollHeight)];
            [self addSubview:controller.view];
            
            //DLog(@"Added to Scroll %@",controller.view);
            //DLog(@"Set Content Size %f %f",size.width,size.height);
            
            // scroll to location of newly opened session
            [self scrollRectToVisible:frame animated:YES];
        
            // show loading image
            [self showSpinViewAt:[MenuCommands getNumberOfOpenCommands] - 1];
        
        }
            break;

        case MC_SESSION_READY_TO_SCROLLTO:{
            // pause currently open session
            [self pauseCurrentServiceView];

            // get frame of index of session to go to
            UIView *v = (UIView *)[[MenuCommands get] getViewAtIndex:[[MenuCommands get].goToIndex intValue]];
            frame = v.frame;
            
            // animate to specified session frame
            [self scrollRectToVisible:frame animated:YES];

            if ([[[[MenuCommands get] openSessions]objectAtIndex:[[[MenuCommands get] goToIndex] intValue]] isKindOfClass:[BrowserServiceViewController class]]) {
                BrowserServiceViewController *f = (BrowserServiceViewController *)[[[MenuCommands get] openSessions]objectAtIndex:[[[MenuCommands get] goToIndex] intValue]];
                
                if (f.search != nil) {
                    [f browseToURL];
                }
            }
        }
            break;

        case MC_SESSION_READY_TO_CLOSE:
            if ([[[MenuCommands get] closeIndex] intValue] != -1) {
                [self removeSession:[[MenuCommands get] closeIndex]];
                
                // disable the login assistant button if no sessions open
                AppDelegate* a = [UIApplication sharedApplication].delegate;
                MenuViewController* mvc = a.viewController.menuViewController;
                [mvc setLoginAssistantButtonStatus];
            }
            break;

        default:
            break;
    }
}

/**
 * Called when the user scrolls the content view within the receiver.
 */
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    // pause session
    [self pauseCurrentServiceView];
    // set width based on number of open commands
    int numOpenSessions = [MenuCommands getNumberOfOpenCommands];
    [self setContentSize:CGSizeMake(ScrollWidth * numOpenSessions, ScrollHeight)];
    [self tileView];
}

/**
 * Called when a scrolling animation in the scroll view concludes
 */
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self scrollViewDidEndDecelerating:self];
    DLog(@"%@",[self subviews]);
}


/**
 * Pauses the current session view
 */
- (void)pauseCurrentServiceView
{
    NSInteger cIndex = self.currentIndex;
    MenuCommands* menu = [MenuCommands get];
    FHServiceViewController* controller = (FHServiceViewController *)[menu.openSessions objectAtIndex:cIndex];
    [controller pauseConnection];
}


/**
 * Scroll view is about to begin scrolling the content.
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    DLog(@"ABOUT TO SCROLL");
}

/**
 * Handle scroll view drag ended
 * If the view is not going to decelerate then we resume session immediately
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    DLog(@"****** scrollViewDidEndDragging *****");
    if (decelerate)
    {
        DLog(@"****** YES *****");
        // Drag ended but acceleration so will let scrollViewDidEndDecelerating handle resume
    }
    else
    {
        DLog(@"****** NO *****");
        // Drag ended but no more deceleration
        // so will need to resume session now by calling scrollViewDidEndDecelerating
        [self scrollViewDidEndDecelerating:self];
    }
}


/**
 * Handle once scroll view finished decelerating after swipe
 */
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSInteger cIndex = self.currentIndex;
    MenuCommands* menu = [MenuCommands get];
    
    DLog(@"****** Did End Decceleration ***** %i",cIndex);
    
    if ([[menu.openSessions objectAtIndex:cIndex] isKindOfClass:[FHServiceViewController class]]) {
        FHServiceViewController* controller = (FHServiceViewController *)[menu.openSessions objectAtIndex:cIndex];
        DLog(@"****** Set Session #%i",cIndex);
        
        [controller initializeActiveView];
        
        // set up main controller based on session
        self.mainController = controller;
        [(AppDelegate *)[UIApplication sharedApplication].delegate setMainController:controller];
        
        // Update the menu's selected command
        menu.selectedCommand = [menu getCommandWithName:controller.command];
    }
    
    // update page control
    [self updatePageControl];
    
}

/**
 * Disable swipe between sessions
 */
-(void)disableSwipeBetweenSessions{
    // disable scroll to prevent user swiping between sessions
    self.scrollEnabled = NO;
    
}

/**
 * Enable swipe between sessions
 */
-(void)enableSwipeBetweenSessions{
    // enable scroll to allow user to swipe between sessions
    self.scrollEnabled = YES;
}

/**
 * Tile views
 * Tiles services views across scroll view
 */
-(void)tileView{
    [self debugSubViews];
    
    // get list of pages that should be in visible view
    CGRect visibleBounds = self.bounds;
    int firstPageIndex  = floorf(CGRectGetMinX(visibleBounds)/CGRectGetWidth(visibleBounds));
    int lastPageIndex   = floorf((CGRectGetMaxX(visibleBounds)-1)/CGRectGetWidth(visibleBounds));
    DLog(@"<<< tileView >>>");
    DLog(@"A. FirstPage Index %i LastPageIndex %i",firstPageIndex,lastPageIndex);
    DLog(@"A. [MenuCommands getNumberOfOpenCommands] %i",[MenuCommands getNumberOfOpenCommands]);
    
    firstPageIndex  = MAX(firstPageIndex, 0);
    lastPageIndex   = MIN(lastPageIndex, [MenuCommands getNumberOfOpenCommands] - 1);
    
    DLog(@"FirstPage Index %i LastPageIndex %i",firstPageIndex,lastPageIndex);

    // remove any views that are not currently visible onscreen
    for (int x = 0; x<[MenuCommands getNumberOfOpenCommands]; x++) {
        UIView* toRemove = [[MenuCommands get] getViewAtIndex:x];
        DLog(@"<<< View #%i = %@  (0x%x) >>>", x, [toRemove description], (int)toRemove);
        if (x < firstPageIndex || x > lastPageIndex) {
            DLog(@"<<< Removing view %@ (0x%x) with Index %i >>>", [toRemove description], (int)toRemove , x);
            [toRemove removeFromSuperview];
        }
    }
    
    
    CGRect frame;

    // insert any view that should be in view
    for (int index = firstPageIndex; index<=lastPageIndex; index++) {
        if (![self isDisplayedAtIndex:index]) {
            UIView *newView =   [[MenuCommands get] getViewAtIndex:index];
            frame = newView.frame;
            frame.origin.x = ScrollWidth * index;
            newView.frame = frame;
            DLog(@"<<< Inserting view %@ with Index %i xpos=%i >>>", [newView description], index, (int)newView.frame.origin.x);
            [self addSubview:newView];
        }
    }
    
    
    // debug output of all views
    DLog(@"<<<<<<<<<<<<>>>>>>>>>>>>>>>");
    DLog(@"<<< Current Tiled Views >>>");
    for (int x = 0; x<[MenuCommands getNumberOfOpenCommands]; x++) {
        UIView* theView = [[MenuCommands get] getViewAtIndex:x];
        DLog(@"<<< View #%i  %@ (0x%x) xpos=%i >>>", x, [theView description], (int)theView, (int)theView.frame.origin.x);
    }
    
}

/**
 * Update service views and displays
 * & resumes current actively displayed session
 */
-(void) refreshDisplayedService
{
    // re-tile view
    [self tileView];
    
    // update page control
    [self updatePageControl];
    
    // resume newly active session
    [self resumeNewlyActiveSession];
}

/**
 * Returns true if view is fully visible (not mid horizontal-scroll)
 */
-(BOOL)isViewFullyVisible
{
    float currOffset = fmod(self.contentOffset.x, ScrollWidth);
    return (currOffset<1.0f);
}

/**
 * Returns true if there is a view currently displayed at this index
 */
-(void)debugSubViews{
    DLog(@"****************************************************************");
    //DLog(@"%@",[self subviews]);
    int i = 0;
    for (UIView *v in [self subviews]) {
        if (![v isKindOfClass:[UIImageView class]])
        {
            DLog(@"SubView #%i X=%i",i , (int)v.frame.origin.x);
            i++;
            
        };
    }
    DLog(@"****************************************************************");
}


/**
 * Returns true if there is a view currently displayed at this index
 */
-(BOOL)isDisplayedAtIndex:(int)index{
    //DLog(@"****************************************************************");
    //DLog(@"%@",[self subviews]);
    //DLog(@"****************************************************************");
    
    for (UIView *v in [self subviews]) {
        if (![v isKindOfClass:[UIImageView class]] && v.frame.origin.x == (index * ScrollWidth)) {
            return YES;
        }
    }
    
    return NO;
}

/**
 * Check if view with specified x-offset is in current subviews
 */
-(BOOL)checkViewIsInSubView:(float)Xoffset{
    
    for (int x=0; x<[[self subviews] count]; x++) {
        if (![[[self subviews] objectAtIndex:x] isKindOfClass:[UIImageView class]] ) {
            if(((UIView *)[[self subviews] objectAtIndex:x]).frame.origin.x == Xoffset)
                return YES;
        }
    }
    return NO;
}

/**
 * Resume newly active session
 *
 * Used when a session is closed as opposed to swiping back to a session
 * to resume the newly active session
 */
-(void)resumeNewlyActiveSession
{
    DLog(@">>>> Resume Session @%i", self.currentIndex);
    MenuCommands* menu = [MenuCommands get];
    DLog(@">>>> Resume Session @%i of @%i", self.currentIndex, [menu.openSessions count]);

    self.mainController = [menu.openSessions objectAtIndex:self.currentIndex];
    DLog(@">>>> mainController = 0x%x", (int)self.mainController);
    [(AppDelegate *)[UIApplication sharedApplication].delegate setMainController:self.mainController];
    [self.mainController resumeConnection];
}


/**
 * Removes session from view and adjusts 
 */
-(void)removeSession:(NSNumber*)closeIndex{
    DLog(@"*** CLOSE Index: %i with Open Sessions: %i",[closeIndex intValue],[MenuCommands getNumberOfOpenCommands]);
    
    // If no open sessions then do nothing
    if ([MenuCommands getNumberOfOpenCommands] == 0) return;
    
    // If only one session open then delete and disable scroll
    if ([MenuCommands getNumberOfOpenCommands] == 1)
    {
        [[MenuCommands get] deleteSession:closeIndex];
        self.contentSize = CGSizeMake(ScrollWidth, ScrollHeight);
        // update page control
        [self updatePageControl];
        self.scrollEnabled = NO;
        // resume newly active session
        [self resumeNewlyActiveSession];
        return;
    }

    // delete selected session
    NSInteger cIndex = self.currentIndex;   // current visible session index
    UIView *closeView = [[MenuCommands get] getViewAtIndex:[closeIndex integerValue]];
    DLog(@">>>> Number of open commands: %i", [MenuCommands getNumberOfOpenCommands]);
    DLog(@">>>> Closing Session: %@ at index %i", [closeView description], [closeIndex intValue]);
    [[MenuCommands get] deleteSession:closeIndex];
    // get the next session view
    UIView *nextView = [[MenuCommands get] getViewAtIndex:currentIndex];

    // enable scrolling only if there is more than 1 remaining session open
    self.scrollEnabled = [MenuCommands getNumberOfOpenCommands] > 1;

    // set view to next view
    if (![self checkViewIsInSubView:nextView.frame.origin.x]) {
        [self addSubview:nextView];
    }
    
    // if the session being closed is the currently visible session
    if ([closeIndex intValue] == cIndex) {
        
        // was the closed session the last session?
        if ([closeIndex intValue] == [MenuCommands getNumberOfOpenCommands]) {
            // set scroll to last existing session
            CGRect frame = [[MenuCommands get] getViewAtIndex:([MenuCommands getNumberOfOpenCommands])].frame;
            [self scrollRectToVisible:frame animated:YES];
            CGSize size = self.contentSize;
            // set contents size to multiple of open commands
            size.width = ScrollWidth * [MenuCommands getNumberOfOpenCommands];
            self.contentSize = size;
            
            // refresh current service view
            [self refreshDisplayedService];

            return;
        }

        // Move over subsequent views
        CGRect frame;
        UIView *nextView;
        for(int x=[closeIndex intValue];x<[MenuCommands getNumberOfOpenCommands];x++){
            nextView = [[MenuCommands get] getViewAtIndex:x];
            frame = nextView.frame;
            frame.origin.x -= ScrollWidth;
            nextView.frame = frame;
        }
            
        [self scrollRectToVisible:frame animated:YES];
        
    }else if ([closeIndex intValue] > cIndex){
        // the session being closed is after the currently visible session
        // move over sessions after the closed session
        CGRect frame; UIView *nextView;
        for (int x=[closeIndex intValue];x<[MenuCommands getNumberOfOpenCommands];x++)
        {
            nextView = [[MenuCommands get] getViewAtIndex:x];
            frame = nextView.frame;
            frame.origin.x -= ScrollWidth;
            nextView.frame = frame;
        }
        
        // reduce width of content by width of closed session
        CGSize size = self.contentSize;
        size.width -= ScrollWidth;
        self.contentSize = size;

    }else if (cIndex > [closeIndex intValue]) {
        // the session being closed is before the currently visible session
        CGRect frame; UIView *nextView;
        for (int x = [closeIndex intValue];x<[MenuCommands getNumberOfOpenCommands]; x++)
        {
            nextView = [[MenuCommands get] getViewAtIndex:x];
            frame = nextView.frame;
            frame.origin.x -= ScrollWidth;
            nextView.frame = frame;
        }
        
        // set frame to current session
        frame = CGRectMake([self contentOffset].x - ScrollWidth, 0, ScrollWidth, ScrollHeight);
        // scroll to visible session
        [self scrollRectToVisible:frame animated:NO];

    }

    // refresh current service view & display page control
    [self refreshDisplayedService];
}

/**
 * Disable scrolling in current service view
 */
-(void)disableScroll
{
    //DLog(@"disableScroll!!");
    self.scrollEnabled = NO;
    self.alwaysBounceHorizontal = NO;
}

/**
 * Re-enable scrolling in current service view
 */
-(void)enableScroll
{
    //DLog(@"enableScroll!!");
    self.scrollEnabled = YES;
    self.alwaysBounceHorizontal = YES;
}

@end