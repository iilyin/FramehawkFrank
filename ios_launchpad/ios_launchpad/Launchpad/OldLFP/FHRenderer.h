/**
 * @file
 * FHRenderer.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.0.0.11799  Built: Thu Nov  1 08:36:16 PDT 2012
 *
 * FHRenderer represents an interface for displaying image information received
 * from the service.
 * This object is the aspect of FHView seen from the connection itself.
 * As such it is interesting only to implementors of an FHView.
 * Framehawk client apps should use the FHView interface.
 *
 * @brief Rendering interface.
 */


#import <Foundation/Foundation.h>
#import "FHDefines.h"

@class FHConnection;
@protocol FHRendererContext;


/**
 * Interface to the Framehawk renderer.
 */
@protocol FHRenderer

@property (retain) id<FHRendererContext> connection;

/** 
 * doUpdateFrame is called by the connection when image data is available.
 * 
 * parameters-
 * d an array containing image data. This is currently assumed to be RGBA format.
 * x, y, w, h the coordinates of the image on the screen. Currently this is only 
 * called with x, y = 0 and w,h = the full size of the screen.
 */
- (void) doUpdateFrame: (unsigned char*) d x:(int)x y:(int)y w:(int)w h:(int)h;


#ifdef CLIENT_SCROLL
// Client-controlled scroll region
- (void) defineScrollRegion:(int)id x:(int) x y:(int) y w:(int)w h:(int)h;
#endif

/** 
 * doRenderFrame is called by the connection when image data provided in doUpdateFrame
 * should be drawn to the screen.
 */
- (void) doRenderFrame;

/** 
 * Set mouse position within connection view.
 */
- (void) updateMousePosition:(int)x y:(int)y;

/** 
 * Set whether you want to display the mouse cursor over the connected view.
 */
- (void) setDisplayMouseCursor:(BOOL)b;

#if TARGET_OS_IPHONE

/** 
 * Get co-ordinates of current mouse position in view.
 */
- (CGPoint) getMouseCoords;

- (GLuint) getViewFrameBuffer;


#endif

@end
