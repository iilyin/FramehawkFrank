//
//  ServiceScrollView.h
//  Framehawk
//
//  Scroller controller contains multiples sessions/services views.
//
//  Created by Hursh Prasad on 4/11/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "FHServiceViewController.h"

#define PAGE_CONTROL_FADE_IN_OUT_TIME       2.0

@interface ServiceScrollView : UIScrollView
 <UIGestureRecognizerDelegate,
  UIScrollViewDelegate>


@property (strong, nonatomic) FHServiceViewController* mainController;
@property (strong, nonatomic) UIPageControl* pageControl;
@property (readonly, nonatomic) NSInteger currentIndex;
@property (readonly, nonatomic) NSInteger totalActivePages;

-(void)pauseCurrentServiceView;
-(void)disableScroll;
-(void)enableScroll;
-(void)showPageControl;
-(BOOL)isViewFullyVisible;
-(void)disableSwipeBetweenSessions;
-(void)enableSwipeBetweenSessions;


@end