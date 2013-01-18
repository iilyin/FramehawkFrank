//
//  RemoteViewCommandDelegate.h
//  Speedtest
//
//  TODO: move to RemoteviewPlaceholder
//
//  Created by Pavel Gorb on 2/23/12.
//  Copyright (c) 2012 Exadel, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol FHServiceViewDelegate <NSObject>
@optional
/**
 * Handle a user tap.
 * @param tapLocation The tap location in the FH coordinate space.
 */
- (void)singleTapDetected:(CGPoint)tapLocation;

/**
 * Moves the cursor at remote side to specified position.
 * @param location Location to move the cursor to.
 */
- (void)cursorLocationChanged:(CGPoint)location;

/**
 * Handle a scroll.
 * @param location The tap location in the FH coordinate space.
 * @param delta scrolling delta
 */
- (void)scrollDetected:(CGPoint)location andDelta:(CGFloat)delta;

@end
