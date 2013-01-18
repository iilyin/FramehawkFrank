/**
 * @file
 * FHUIView.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.0.0.11799  Built: Thu Nov  1 08:36:16 PDT 2012
 *
 * Public Interface to the Framehawk canvas object.
 *
 * @brief Framehawk UI View file.
 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FHView.h"
#import "FHConnection.h"

@class FHConnection;
@protocol FHRenderer;

/**
 * @class FHUIView
 * @brief Public Interface to the Framehawk canvas object.
 */
@interface FHUIView :  UIScrollView <FHView, UIScrollViewDelegate, FHMessageSender>
{
    id<FHRenderer> fhView;
    BOOL doScaling;
}

/**
 * The associated FHConnection 
 */
@property (readonly) FHConnection* connection;

/**
 * Control scaling of the image to fit the view. Default is YES.
 */
@property BOOL doScaling;

/**
 * Read only access to the FHRenderer interface.
 */
@property (readonly) id<FHRenderer> renderer;

/**
 * Toggle 'halo' mouse effect.
 * The halo is visual feedback immediately after the user touches the screen.
 */
- (void) setHaloMouseCursor:(BOOL)b;

/**
 * Get the screen coordinates of the last mouse event.
 */
- (CGPoint) getMouseCoords;
- (GLuint) getViewFrameBuffer;

/**
 * Update Mouse position within view and pass this information to the service via the connection.
 */
- (void) updateMousePosition:(int)x y:(int)y;



@end
