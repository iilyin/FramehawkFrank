//
//  MagnifierView.m
//  Launchpad
//
//  Copyright (c) 2012  Framehawk, Inc. All rights reserved.

//#import <QuartzCore/CALayer.h>
//#import <QuartzCore/CAEAGLLayer.h>
//#import <CoreGraphics/CGImage.h>
//#import <OpenGLES/ES2/gl.h>
//#import <OpenGLES/ES2/glext.h>
//#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <objc/runtime.h>

#import "MagnifierView.h"
#import "FHUIView.h"

#define SHOW_TIMES 0
#define CAPTURE_INTERVAL 0.1

/*
 global OpenGL threads lock
 */
NSLock *glthreadLock;

@interface  MagnifierView(Private_methods)

- (UIImage*) captureImage;
- (UIImage*)snapshotEAGL:(UIView*)eaglview;
- (void)changeLocation:(CGPoint)newPanLocation;

@end 

MagnifierView *currentLoupe = nil;

@implementation MagnifierView

@synthesize sourceView = _sourceView;
@synthesize scale = _scale;
@synthesize capturedImage = _capturedImage;
@synthesize cursorView;
@synthesize delegate;
@synthesize lastDate, timer, threadLock;

- (void)dealloc
{
    capture = NO;
    dataLength = 0;
    magnifierView = nil;
    self.sourceView = nil;
    self.capturedImage = nil;
    self.cursorView = nil;
    self.lastDate = nil;
    self.threadLock = nil;
    free(resdata);
    resdata = NULL;
    currentLoupe = nil;
    
    CFRelease(&framebufferID);
    CGImageRelease(resultImgRef);
}

- (void)stopCapturing
{
    capture = NO;
}

- (void)initMagnifierView:(UIImage*)image
{
    self.backgroundColor = [UIColor clearColor];
    
    self.threadLock = [[NSLock alloc] init];
    // Initialization code
    self.exclusiveTouch = YES;
    
    CGRect frame = self.frame;
    
    //setup size of render view for captured image
    UIView *clipView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, frame.size.width-2, frame.size.height-2)];
    clipView.clipsToBounds = YES;
    //make clipping region circular
    clipView.layer.cornerRadius = frame.size.width / 2;
    
    //create image view for magnified content
    CGRect imageFrame = CGRectMake(0, 0, frame.size.width - 2, frame.size.height - 2);
    if (_scale != 1)
    {
        self.capturedImage = [[UIImageView alloc] initWithFrame:imageFrame];
        [clipView addSubview:self.capturedImage];
    }
    
    //create magnifier view, which is loupe itself
    [self setMagnifierImage:image];
    
    //create cursor view
    cursorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cursor.png"]];
    cursorView.frame = CGRectMake(frame.size.width / 2 - cursorView.image.size.width / 2, frame.size.height / 2 - cursorView.image.size.height / 2, cursorView.image.size.width, cursorView.image.size.height);
    
    [self addSubview:clipView];
    [self addSubview:magnifierView];
    [self addSubview:cursorView];
    
    // set default scale
    _scale = 1.0f;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapRecognizer];
}

- (void)setMagnifierImage:(UIImage*)image
{
    CGRect frame = self.frame;
    //create magnifier view, which is loupe itself
    if (!magnifierView)
        magnifierView = [[UIImageView alloc] initWithImage:image];
    else
        magnifierView.image = image;
    
    CGRect magnifierFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    CGFloat magnifierImageScale = (frame.size.height - 2.) / (magnifierFrame.size.height - 9.0);
    magnifierFrame.size.width *= magnifierImageScale;
    magnifierFrame.size.height *= magnifierImageScale;
    magnifierFrame.origin.x = magnifierFrame.origin.y = (frame.size.height - magnifierFrame.size.height) / 2;
    magnifierView.frame = magnifierFrame;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        resdata = NULL;
        dataLength = 0;
        [self initMagnifierView:[UIImage imageNamed:@"magnifier.png"]];
        currentLoupe = self;
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame magnifierImage:(UIImage*)image
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initMagnifierView:image];
        currentLoupe = self;
    }
    
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

#if 0
- (void)drawRect:(CGRect)rect
{
    // Drawing border around frame of the loupe
    
    [super drawRect:rect];
    
    float width = self.frame.size.width;
    float heigth = self.frame.size.height;
    /* Set the color that we want to use to draw the line */ 
    [[UIColor blackColor] set];
    /* Get the current graphics context */ 
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    /* Set the width for the line */ 
    CGContextSetLineWidth(currentContext, 1.0f);
    /* Start the line at this point */ 
//    CGContextMoveToPoint(currentContext, 0.0f, 0.0f);
    CGContextAddEllipseInRect(currentContext, CGRectMake(1, 1, width - 2, heigth - 2));
    /* And end it at this point */ 
//    CGContextAddLineToPoint(currentContext, 0.0f, width);
    
//    CGContextAddLineToPoint(currentContext, heigth, width);
    
//    CGContextAddLineToPoint(currentContext, heigth, 0.0f);
    
//    CGContextAddLineToPoint(currentContext, 0.0f, 0.0f);
    /* Use the context's current color to draw the line */
    CGContextStrokePath(currentContext);
}

#endif


#pragma mark -
#pragma mark Touch handling methods

- (void)oneFingerTap:(UITapGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateEnded:
        {
            // send click on magnifier view
            [delegate loupeView:self magnifierClick:[self adjustedCenter]];
            break;
        }
        default:
            break;
    }
}

- (void)panGesture:(UIPanGestureRecognizer*)recognizer
{
    CGPoint location = [recognizer locationInView:self];
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged:
            DLog(@"gesture changed: location %f, %f", location.x, location.y);
            [self changeLocation:location];
            break;
        case UIGestureRecognizerStateEnded:
            DLog(@"gesture ended: location %f, %f", location.x, location.y);
            [self stopCapturing];
            [self.delegate loupeView:self hideAtPosition:self.center click:YES];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            DLog(@"gesture canceled or failed: location %f, %f", location.x, location.y);
            [self stopCapturing];
            [self.delegate loupeView:self hideAtPosition:location click:NO];
            break;
        default:
            break;
    }
}

- (void)refreshCaptureImage:(UIImage*)image
{
    if (image == nil)
        return;
    self.capturedImage.image = image;
    
    CGRect myFrame = self.frame;
    CGRect appRect = self.superview.bounds;

    CGRect capturedImageFrame = self.capturedImage.frame;
    if (myFrame.origin.y + myFrame.size.height >= appRect.size.height)
        capturedImageFrame.origin.y = appRect.size.height - myFrame.origin.y - myFrame.size.height;
    else
        if (myFrame.origin.y < 0)
            capturedImageFrame.origin.y = - myFrame.origin.y;
        else 
            capturedImageFrame.origin.y = 0;
    
    if (myFrame.origin.x + myFrame.size.width >= appRect.size.width)
        capturedImageFrame.origin.x = appRect.size.width - myFrame.origin.x - myFrame.size.width;
    else
        if (myFrame.origin.x < 0)
            capturedImageFrame.origin.x = - myFrame.origin.x;
        else 
            capturedImageFrame.origin.x = 0;
    
    //DLog(@"capured image frame = %f, %f, %f, %f", capturedImageFrame.origin.x, capturedImageFrame.origin.y, capturedImageFrame.size.width, capturedImageFrame.size.height);
    
    self.capturedImage.frame = capturedImageFrame;
}

//- (void)changeMyFrame:(NSValue*)value
//{
//    CGRect fr = value.CGRectValue;
////    [self.threadLock tryLock];
////    [self.threadLock unlock];
//}

- (void)changeLocation:(CGPoint)newPanLocation
{
    CGRect appRect = self.superview.bounds;
    
    int widthLimit = appRect.size.width - self.frame.size.width / 2;
    int heightLimit = appRect.size.height - self.frame.size.height / 2;
    
    CGRect myFrame = self.frame;

    float deltaX = newPanLocation.x - myFrame.size.width / 2;
    float deltaY = newPanLocation.y - myFrame.size.height / 2;
    
    myFrame.origin.x += deltaX;
    if(myFrame.origin.x < - self.frame.size.width / 2)
        myFrame.origin.x = - self.frame.size.width / 2;
    if(myFrame.origin.x > widthLimit)
        myFrame.origin.x = widthLimit;
    
    myFrame.origin.y += deltaY;
    if(myFrame.origin.y < - self.frame.size.height / 2)
        myFrame.origin.y = - self.frame.size.height / 2;
    if(myFrame.origin.y > heightLimit)
        myFrame.origin.y = heightLimit;

    [self setFrame:myFrame];
    [self refreshCaptureImage:[self captureImage]];
}

- (CGPoint)adjustedCenter
{
    if (self.capturedImage.frame.origin.x == 0.0 && self.capturedImage.frame.origin.y == 0.0)
        return self.center;
    else
    {
        //CGAffineTransform tr = self.sourceView.transform;
        CGPoint loupeCenter = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        CGPoint sourceLoupeCenter = [self convertPoint:loupeCenter toView:self.sourceView];
        CGPoint capturedCursorPos = [self convertPoint:loupeCenter toView:self.capturedImage];
        DLog(@"capt ured cursor pos size = %f , %f", capturedCursorPos.x, capturedCursorPos.y);
        DLog(@"captured image size = %f , %f", self.capturedImage.frame.size.width, self.capturedImage.frame.size.height);
        
        CGPoint capturedCursorShift = CGPointMake(capturedCursorPos.x - self.capturedImage.frame.size.width / 2, capturedCursorPos.y - self.capturedImage.frame.size.height / 2);
        DLog(@"captured image cursor shift = %f , %f", capturedCursorShift.x, capturedCursorShift.y);
        
        if (CGPointEqualToPoint(capturedCursorShift, CGPointZero))
            return self.center;
        else
        {
            CGFloat x = 0;
            //if  (capturedCursorShift.x == 0)
                x = sourceLoupeCenter.x;
            //else
            //    x = _sourceCenter.x + capturedCursorShift.x / _scale / tr.a;
            
            CGFloat y = 0; 
            //if  (capturedCursorShift.y == 0)
                y = sourceLoupeCenter.y;
            //else
            //    y = _sourceCenter.y + capturedCursorShift.y / _scale / tr.d;

            return [self.sourceView convertPoint:CGPointMake(x, y) toView:self.superview];
        }
    }
}

- (void) captureThread
{
    if (!capture || _scale == 1)
        return;
    if (![self.threadLock tryLock])
        return;

    {
#if SHOW_TIMES
        NSDate *cur = [NSDate date];
        NSLog(@"capturing");
        static NSInteger count = 0;
#endif
        
        if (resultImgRef == nil)
        {
            lastDate = [NSDate date];
        }
        else
        {
            NSDate *newDate = [NSDate date];
            if (!self.lastDate || [newDate timeIntervalSinceDate:lastDate] >= CAPTURE_INTERVAL)
                lastDate = newDate;
            else
            {
                [self.threadLock unlock];
#if SHOW_TIMES
                NSTimeInterval spent = [[NSDate date] timeIntervalSinceDate:cur];
                NSLog(@"capture skipped, seconds spent = %f", spent);
#endif
                if (self.superview)
                    dispatch_async(dispatch_get_main_queue(), ^(){
                    [self performSelector:@selector(nextCapture:) withObject:nil afterDelay:CAPTURE_INTERVAL];
                    });
                return;
            }
        }
        
        
        
        if (1)
        {
            NSArray* views = [self.sourceView subviews];
            
            for (UIView* view in views) {
                // try to find CAEAGLLayer
                if([[view layer] isMemberOfClass:[CAEAGLLayer class]]){
                    // we have deal with internal AEGL layer and other aproach should be used for it.
                    //DLog(@"calling snapshot...");
                    //DLog(@"... snapshot done");
                    [self snapshotEAGL:view];
                    break;
                }
            }
        }

#if SHOW_TIMES
        NSTimeInterval spent = [[NSDate date] timeIntervalSinceDate:cur];
        static NSTimeInterval average = 0.0;
        count++;
        average += spent;
        NSLog(@"capture finished, seconds spent = %1.5f , average time = %1.5f", spent, average/count );
#endif
        [self.threadLock unlock];
    }
    
    if (![NSThread isMainThread])
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.superview)
            {
                [self refreshCaptureImage:[self captureImage]];
                [self performSelector:@selector(nextCapture:) withObject:nil afterDelay:CAPTURE_INTERVAL];
            }
        });
}

- (void) nextCapture:(NSTimer*)timer
{
    [self performSelectorInBackground:@selector(captureThread) withObject:nil];
}

#pragma mark Private methods

- (UIImage*) captureImage{
    
#if (SHOW_TIMES)
    NSDate *start = [NSDate date];
#endif
    
    if (resultImgRef == NULL)
    {
        if (self.superview)
        {
            [self captureThread];
            [self performSelector:@selector(nextCapture:) withObject:nil afterDelay:CAPTURE_INTERVAL];
        }
    }
    
    CGImageRef tmp = nil;
    
    {
        CGFloat w = CGImageGetWidth(resultImgRef);
        CGFloat h = CGImageGetHeight(resultImgRef);
        CGSize imageSize = CGSizeMake(w, h);
        CGPoint sourceCenter = [self.superview convertPoint:self.center toView:self.sourceView];
        
       // DLog(@"Self center = %f, %f; source coordinates = %f, %f; scale = %f, %f; translation scale = %f, %f ", self.center.x, self.center.y, sourceCenter.x,  sourceCenter.y,self.center.x / sourceCenter.x, self.center.y / sourceCenter.y, self.sourceView.transform.a, self.sourceView.transform.d);
        
        CGFloat sourceWidth = self.frame.size.width / _scale / self.sourceView.transform.a;
        CGFloat sourceHeght = self.frame.size.height / _scale / self.sourceView.transform.d;
        
//        double hscale = w / imageSize.width;
//        double vscale = h / imageSize.height;
        
        if (sourceCenter.y + sourceHeght / 2 >= imageSize.height)
            sourceCenter.y = imageSize.height - sourceHeght / 2;
        else
            if (sourceCenter.y < sourceHeght / 2)
                sourceCenter.y = sourceHeght / 2;
        if (sourceCenter.x + sourceWidth / 2 >= imageSize.width)
            sourceCenter.x = imageSize.width - sourceWidth / 2;
        else
            if (sourceCenter.x < sourceWidth / 2)
                sourceCenter.x = sourceWidth / 2;
        
        _sourceCenter = sourceCenter;
        
        
        tmp = CGImageCreateWithImageInRect(resultImgRef, 
                                                      CGRectMake((sourceCenter.x - sourceWidth / 2), (int)(sourceCenter.y - sourceHeght / 2), sourceWidth, sourceHeght)
                                                      );
    }
    
    UIImage* img = [UIImage imageWithCGImage:tmp];
   
    CGImageRelease(tmp);

#if (SHOW_TIMES)
    NSLog(@"Subcapture spent %f", [[NSDate date] timeIntervalSinceDate:start]);
#endif
    
    return img;

}


- (void) setSourceView:(UIView *)sourceView{

    if(_sourceView != sourceView)
        _sourceView = sourceView;
}

- (void)stopCaptureThread
{
    [self.threadLock lock];
    capture = NO;
    [self.threadLock unlock];
}

- (void)didMoveToSuperview
{
    if (self.superview != nil)
    {
        capture = YES;
        [self performSelector:@selector(refreshCaptureImage:) withObject:[self captureImage] afterDelay:0.0];
    }
    else
    {
        [self performSelectorInBackground:@selector(stopCaptureThread) withObject:self];
    }
}

- (UIImage*)snapshotEAGL:(UIView*)eaglview
{
//    DLog(@"snapshot started");
//    DLog(@"For Loupe View = 0x%x", (int)self);
    //First of all i needs to get correct inde of reder buffer for our EAGL layer
    
    static GLint backingWidth = 0, backingHeight = 0;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point, 
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    

    if (resdata == NULL)
        DLog(@"Results buffer is clear!!!!!!!!!!!!");
    // Get the size of the backing CAEAGLLayer
    
#if SHOW_TIMES
    NSDate *grabStart = [NSDate date];
#endif
    if ([NSThread isMainThread])
    {
        glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
        glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    }
    else
    {
    }
    
    if (backingWidth == 0 || backingHeight == 0)
        return nil;
    
    NSInteger width = backingWidth, height = backingHeight;
    
    BOOL firstDraw = NO;
    CGRect intersection;
    
    if (dataLength != width * height * 4 || resdata == NULL)
    {
        dataLength = width * height * 4;
        if (resdata)
            free(resdata);
        
        if (resultImgRef)
            CGImageRelease(resultImgRef);
        
        firstDraw = YES;
        
        // copy loupe view image from framebuffer into resdata
        resdata = malloc(dataLength);
        DLog(@"allocated %d at pointer %x", dataLength, (unsigned int)resdata);
        
//        GLint oldFBO, oldViewPort[4];
//        glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFBO);
//        framebufferID = oldFBO;
//        glGetIntegerv(GL_VIEWPORT, oldViewPort);
//        glBindFramebufferOES(GL_FRAMEBUFFER_OES, bufferID);
//        glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
        
        if (capture && dataLength != 0 && resdata != NULL)
        {
            GLubyte *dest = resdata;
            int change = backingWidth * 4;
            for (int i = 0, startY = backingHeight - 1; i < backingHeight; i++, startY--, dest += change) {
                glReadPixels(0, startY, backingWidth, 1, GL_RGBA, GL_UNSIGNED_BYTE, dest);
            }
        }
        else
            DLog(@"result buffer is empty, data len = %d!!!", dataLength);

//        glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFBO);
    }
    else
    {
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
        
        CGRect sourceFrame = [eaglview convertRect:self.bounds fromView:self];
        intersection = CGRectIntersection(CGRectMake(0, 0, width, height), sourceFrame);
        int offest = (int)(/*height - */(int)intersection.origin.y/* - (int)intersection.size.height*/) * width * 4;
        
        __block int startY = height - (int)intersection.origin.y/* - (int)intersection.size.height*/;
        int startX = (int)intersection.origin.x * 4;
        __block GLubyte *destination = resdata + offest + startX;
        
        int change = width * 4;
        @try {
            if (![NSThread isMainThread])
            {
                if (capture && resdata && dataLength != 0)
                    //reads only intersection bytes
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [glthreadLock lock];
                        GLint oldFBO;
                        glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFBO);
                        
                        glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebufferID);
                        GLint defaultFBO; 
                        glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &defaultFBO);
                        for (int i = 0; i < (int)intersection.size.height; i++)
                        {
//                            glReadPixels((int)intersection.origin.x, startY--, (int)intersection.size.width, 1, GL_RGBA, GL_UNSIGNED_BYTE, destination);
                            destination += change;
                        }
                        glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFBO);
                        [glthreadLock unlock];
                    });
                else
                    DLog(@"result buffer is empty, data len = %d!!!", dataLength);
            }
            else
                glReadPixels((int)intersection.origin.x, startY++, (int)intersection.size.width, 1, GL_RGBA, GL_UNSIGNED_BYTE, destination);
        }
        @catch (NSException *exception) {
            DLog(@"Exception %@", exception.userInfo);
        }
        @finally {
        }
    }
    
#if SHOW_TIMES
    NSLog(@"GL capture seconds spent %f", [[NSDate date] timeIntervalSinceDate:grabStart]);
    NSDate *drawStart = [NSDate date];
#endif
    if (firstDraw && capture && dataLength != 0)
    {
        // Create a CGImage with the pixel data
        // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
        // otherwise, use kCGImageAlphaPremultipliedLast
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        // set up image to grab loupe view from original view image (resdata)
        CGDataProviderRef ref1 = CGDataProviderCreateWithData(NULL, resdata, dataLength, NULL);
        resultImgRef = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                         ref1, NULL, true, kCGRenderingIntentDefault);
        CFRelease(ref1);
        
        CGColorSpaceRelease(colorspace);
    }
    
#if SHOW_TIMES
    NSLog(@"drawing into context done, spent %f\n\n\n", [[NSDate date] timeIntervalSinceDate:drawStart]);
#endif
    
    return nil;
}

@end

/*
 OpenGL threads concurrency workaround.
 WARNING: experimental
 */

NSMethodSignature *signature = nil;
NSInvocation *invocation = nil;

@implementation EAGLContext(custom)

+ (void)load {
    if (signature == nil)
    {           
        @autoreleasepool {
            signature = [[self class] instanceMethodSignatureForSelector:@selector(presentRenderbuffer:)];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = @selector(presentRenderbufferOld:);
        }
    }
    
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(presentRenderbuffer:)), class_getInstanceMethod(self, @selector(presentRenderbufferOld:)));
}

- (BOOL)presentRenderbufferOld:(NSUInteger)target
{
    // don't do this when in background
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
        return NO;
    
#if SHOW_TIMES
    NSDate *start = [NSDate date];
#endif
    if (!glthreadLock)
        glthreadLock = [[NSLock alloc] init];
    [glthreadLock lock];
    invocation.target = self;
    [invocation setArgument:&target atIndex:2];
    [invocation invoke];
    BOOL ret = NO;
    [invocation getReturnValue:&ret];
    [glthreadLock unlock];
#if SHOW_TIMES
    DLog(@"EAGLContext presentRenderBuffer: spend %f", [[NSDate date] timeIntervalSinceDate:start]);
#endif
    return YES;
}
@end

