/**
 * @file
 * FHView.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.1.2.12317  Built: Wed Nov 21 09:06:10 PST 2012
 *
 * Public interface to the Framehawk canvas object.
 *
 * @brief Framehawk View file.
 */


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@class FHConnection;
@protocol FHRenderer;

/**
 * Public interface to the Framehawk canvas object.
 */
@protocol FHView <NSObject>

/**
 * The associated FHConnection.
 */
@property (readonly) FHConnection* connection;

/**
 * Control scaling of the image to fit the view. Default is NO.
 */
@property BOOL doScaling;

/**
 * Read only access to the FHRenderer interface.
 */
@property (readonly) id<FHRenderer> renderer;

/**
 * Toggle show/hide mouse cursor.
 */
- (void) setDisplayMouseCursor:(BOOL)b;

/**
 * Update Mouse position within view.
 */
- (void) updateMousePosition:(int)x y:(int)y;


#if TARGET_OS_IPHONE
/**
 * Get the coordinates of the last mouse event.
 */
- (CGPoint) getMouseCoords;

- (GLuint) getViewFrameBuffer;

/**
 * Toggle 'halo' mouse effect
 */
- (void) setHaloMouseCursor:(BOOL)b;

#endif

@end
