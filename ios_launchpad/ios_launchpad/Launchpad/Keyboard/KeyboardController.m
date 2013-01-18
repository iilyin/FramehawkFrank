//
//  KeyboardController.m
//  Launchpad
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "KeyboardController.h"
#import "CustomKeyButton.h"
#import "UIUtils.h"
#import "FHDefines.h"
#import "CustomButton.h"
#import "FunctionKeysController.h"

#define KEYBOARD_FUNCTION_BUTTON_WIDTH      55
#define KEYBOARD_FUNCTION_BUTTON_HEIGHT     35

#define TOTAL_FUNCTION_KEYS                 12

#define KEYBOARD_TOOLBAR_BUTTON_HIGHLIGHT_COLOR [UIColor colorWithRed:.0 green:.0 blue:.812 alpha:1]

@implementation CustomButtonInfo

@synthesize title, image, backgroundImage, pressedBackgroundImage, width, tag, backgroundInsets, pressedBackgroundInsets;

+ (id)customButtonInfoWithTitle:(NSString*)title width:(CGFloat)width tag:(XKeyTag)tag
{
    CustomButtonInfo *info = [[CustomButtonInfo alloc] init];
    info.title = title;
    info.width = width;
    info.tag = tag;
    
    return info;
}

+ (id)customButtonInfoWithImage:(NSString*)image width:(CGFloat)width tag:(XKeyTag)tag
{
    CustomButtonInfo *info = [[CustomButtonInfo alloc] init];
    info.image = image;
    info.width = width;
    info.tag = tag;
    
    return info;
}

+ (id)customButtonInfoWithTitle:(NSString*)title image:(NSString*)image backgroundImage:(NSString*)backgroundImage backgroundInsets:(UIEdgeInsets)backInsets pressedBackgroundImage:(NSString*)pressedBackgroundImage  pressedInsets:(UIEdgeInsets)pressedInsets width:(CGFloat)width tag:(XKeyTag)tag
{
    CustomButtonInfo *info = [[CustomButtonInfo alloc] init];
    info.title = title;
    info.image = image;
    info.backgroundImage = backgroundImage;
    info.backgroundInsets = backInsets;
    info.pressedBackgroundImage = pressedBackgroundImage;
    info.pressedBackgroundInsets = pressedInsets;
    info.width = width;
    info.tag = tag;
    
    return info;
}

- (UIImage*)backImage
{
    if (!self.backgroundImage)
        
        return nil;
    if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, self.backgroundInsets))
        return [UIImage imageNamed:self.backgroundImage];
    else
        return [[UIImage imageNamed:self.backgroundImage] resizableImageWithCapInsets:self.backgroundInsets];
}

- (UIImage*)pressedBackImage
{
    if (!self.pressedBackgroundImage)
        return nil;
    
    if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, self.pressedBackgroundInsets))
        return [UIImage imageNamed:self.pressedBackgroundImage];
    else
        return [[UIImage imageNamed:self.pressedBackgroundImage] resizableImageWithCapInsets:self.pressedBackgroundInsets];
}

@end

@interface KeyboardController(PrivateMethods)
- (void)updateKeyboardAccessoryView;
- (void)addCustomButtonToKeyboard;
- (int)updateKeyboardFlags;
- (void)xCtrlAction:(CustomKeyButton*)button;
- (void)xAltAction:(CustomKeyButton*)button;
- (void)xCtrlAltDelAction:(CustomKeyButton*)button;
- (void)xToggleFnKeys:(CustomKeyButton*)button;
- (void)customKeyAction:(CustomKeyButton*)button;
- (int)keysForXKeyTag:(XKeyTag)tag;
- (int)keysForFunctionKeyTag:(NSInteger)tag;
@end

@implementation KeyboardController

@synthesize returnKeyType, keyboardType, autocapitalizationType = _autocapitalizationType;
@synthesize fnKeysToolbar;
@synthesize fnKeyToolbarController;

/**
 * Initialise keyboard state settings
 */
- (id)init
{
    self                = [super init];
    ctrlPressed         = NO;
    altPressed          = NO;
    keyboardFlags       = NO;
    enableFnKeysPressed = NO;
    
    return self;
}

/**
 * Show keyboard
 */
- (void)showKeyboard 
{
    showKeyboard = YES;
    self.returnKeyType = UIReturnKeyDefault;
    [self becomeFirstResponder];
}

/**
 * Hide keyboard
 */
- (void) hideKeyboard
{
    showKeyboard = NO;
    [self clearFunctionKeysSelected];
    [self dismissFunctionKeys];
    [self resignFirstResponder];
}

/**
 * Toggle keyboard on or off
 */
- (void)togglekeyboard 
{   
    if ([self isFirstResponder])
    {
        [self hideKeyboard];
    }
    else
    {
        [self showKeyboard];
    }
}

#pragma mark Keyboard handling

/**
 * canBecomeFirstResponder
 * returns TRUE if keyboard can be displayed
 */
- (BOOL)canBecomeFirstResponder
{
    return showKeyboard;
}

/**
 * Keyboard is dismissed
 */
- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    showKeyboard = NO;
    return YES;
}

- (void) insertText:(NSString* )text
{
}

/**
 * Handle delete key from keyboard overriding method from UIKeyInput class.
 */
- (void)deleteBackward 
{
}

/**
 * Returns a Boolean value that indicates whether the text-entry objects has any text.
 */
- (BOOL)hasText
{
    return YES;
}

/**
 * Returns current keyboard input accessory view
 */
- (UIView*)inputAccessoryView
{
    return currentKeyboardAccessoryView;
}

#pragma mark Keyboard accessory view control

/**
 * Set current keyboard type
 */
- (void)setCurrentKeyboardType:(KeyboardType)type
{
    if (type == currentKeyBoardType)
        return;
    
    currentKeyBoardType = type;
    [self updateKeyboardAccessoryView];
}

/**
 * createFunctionsAccessoryView - creates function keys toolbar
 */
- (UIView*)createFunctionsAccessoryView
{
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [UIUtils layoutKeyboardToolbar:toolbar];
    
    NSMutableArray *functionKeys = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    flexible.width = 10;
    
    CGSize buttonSize = CGSizeMake(KEYBOARD_FUNCTION_BUTTON_WIDTH, KEYBOARD_FUNCTION_BUTTON_HEIGHT);
    
    for (int i = 1; i <= TOTAL_FUNCTION_KEYS; i++)
    {
        CustomKeyButton *keyButton = [CustomKeyButton createWithTitle:[NSString stringWithFormat:@"F%d", i] size:buttonSize delegate:self action:@selector(customKeyAction:) keys:[self keysForFunctionKeyTag:i] tag:i];
        
        [functionKeys addObject:keyButton];
        if (i != TOTAL_FUNCTION_KEYS)
            [functionKeys addObject:flexible];
    }
    
    toolbar.items = functionKeys;
    
    return toolbar;
}

/**
 * Create keyboard accessory - displays toolbar above regular iOS keyboard that displays
 * additional key functionality e.g. cursor arrows, CTRL, ALT, INS, etc.
 */
- (UIView*)createXAccessoryViewWithType:(KeyboardType) typeForXKeyBoard
{
    NSArray *buttonsInfo = nil;
    
    if ([self respondsToSelector:@selector(xAccessoryButtonsInfoForKeyBoardType:)] && 
        (buttonsInfo = [self xAccessoryButtonsInfoForKeyBoardType:typeForXKeyBoard]) == nil)
        buttonsInfo = [NSArray arrayWithObjects:
                       [CustomButtonInfo customButtonInfoWithTitle:@"Ctrl" width:50 tag:kXCtrl],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Alt" width:50 tag:kXAlt],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Tab" width:50 tag:kXTab],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Esc" width:50 tag:kXEsc],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Del" width:50 tag:kXDel],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Ins" width:50 tag:kXInsert],
                       //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:10 tag:kXNone],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Home" width:50 tag:kXHome],
                       [CustomButtonInfo customButtonInfoWithTitle:@"End" width:50 tag:kXEnd],
                       //[CustomButtonInfo customButtonInfoWithTitle:@"fixed" width:10 tag:kXNone],
                       [CustomButtonInfo customButtonInfoWithTitle:@"PgUp" width:50 tag:kXPageUp],
                       [CustomButtonInfo customButtonInfoWithTitle:@"PgDn" width:50 tag:kXPageDown],
                       //[CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:50 tag:kXNone],
                       [CustomButtonInfo customButtonInfoWithImage:@"leftArrowButton.png" width:40 tag:kXLeft],
                       [CustomButtonInfo customButtonInfoWithImage:@"upArrowButton.png" width:40 tag:kXUp],
                       [CustomButtonInfo customButtonInfoWithImage:@"downArrowButton.png" width:40 tag:kXDown],
                       [CustomButtonInfo customButtonInfoWithImage:@"rightArrowButton.png" width:40 tag:kXRight],
                       [CustomButtonInfo customButtonInfoWithTitle:@"flexible"  width:50 tag:kXNone],
                       [CustomButtonInfo customButtonInfoWithTitle:@"F1-F12" width:90 tag:kXToggleFnKeys],
                       [CustomButtonInfo customButtonInfoWithTitle:@"Dismiss" width:65 tag:kxMinimizeKeyBoard],
                       nil];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [UIUtils layoutKeyboardToolbar:toolbar];
    
    NSMutableArray *functionKeys = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    for (CustomButtonInfo *info in buttonsInfo)
    {
        if ([info.title isEqualToString:@"flexible"])
        {
            [functionKeys addObject:flexible];
            continue;
        }
        else
            if ([info.title isEqualToString:@"fixed"])
            {
                UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
                fixed.width = info.width;
                [functionKeys addObject:fixed];
                continue;
            }
        
        CustomKeyButton *keyButton = nil;
        
        SEL action = nil;
        BOOL selected = NO;
        
        // set action selector according to key type
        switch (info.tag) {
            case kXCtrl:
                action = @selector(xCtrlAction:);
                selected = ctrlPressed; 
                break;
            case kXAlt:
                action = @selector(xAltAction:);
                selected = altPressed;
                break;
            case kXInsert:
                action = @selector(customKeyAction:);
                selected = insPressed;
                break;
            case kXCtrlAltDel:
                action = @selector(xCtrlAltDelAction:);
                break;
            case kXToggleFnKeys:
                action = @selector(xToggleFnKeys:);
                selected = enableFnKeysPressed;
                break;
            default:
                action = @selector(customKeyAction:);
                break;
        }
        
        
        if (info.title)
            keyButton = [CustomKeyButton createWithTitle:info.title
                                          backroundImage:[info backImage] 
                                   pressedBackroundImage:[info pressedBackImage]
                                                    size:CGSizeMake(info.width, 35)
                                                delegate:self 
                                                  action:action 
                                                    keys:[self keysForXKeyTag:info.tag]
                                                    tag:info.tag];
        else
            keyButton = [CustomKeyButton createWithImage:[UIImage imageNamed:info.image]
                                          backroundImage:[info backImage]
                                   pressedBackroundImage:[info pressedBackImage]
                                                    size:CGSizeMake(info.width, 35)
                                                delegate:self
                                                  action:action
                                                    keys:[self keysForXKeyTag:info.tag]
                                                    tag:info.tag];
        
        
        keyButton.tag = info.tag;
        
        keyButton.width = info.width;
        keyButton.selected = selected;
        
        [functionKeys addObject:keyButton];
    }
    
    toolbar.items = functionKeys;
    
    return toolbar;
}

/*
- (UIView*)createXAccessoryView
{
    NSArray *titles = [NSArray arrayWithObjects:@"esc",@"tab",@"ctrl",@"alt",@"fixed",@"⌘",@"flexible",@"ctrl+alt+del",@"flexible",@"del",@"flexible",@"arrowLeft.png", @"arrowUp.png", @"arrowDown.png", @"arrowRight.png",nil];
    NSDictionary *buttons = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:70], @"esc",
                             [NSNumber numberWithInt:70], @"tab",
                             [NSNumber numberWithInt:70], @"ctrl",
                             [NSNumber numberWithInt:70], @"alt",
                             [NSNumber numberWithInt:70], @"⌘",
                             [NSNumber numberWithInt:150], @"ctrl+alt+del",
                             [NSNumber numberWithInt:70], @"del",
                             [NSNumber numberWithInt:50], @"arrowLeft.png",
                             [NSNumber numberWithInt:50], @"arrowUp.png",
                             [NSNumber numberWithInt:50], @"arrowDown.png",
                             [NSNumber numberWithInt:50], @"arrowRight.png",
                             nil
                             ];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [UIUtils layoutKeyboardToolbar:toolbar];
    
    NSMutableArray *functionKeys = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSInteger xButtonTag = 0;
    
    for (NSString *title in titles)
    {
        if ([title isEqualToString:@"flexible"])
        {
            [functionKeys addObject:flexible];
            continue;
        }
        else
            if ([title isEqualToString:@"fixed"])
            {
                UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
                fixed.width = 10;
                [functionKeys addObject:fixed];
                continue;
            }
        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:title ofType:nil];
        CustomKeyButton *keyButton = nil;
        
        SEL action = nil;
        BOOL selected = NO;
        
        // set action selector accoring to key type
        switch (xButtonTag) {
            case kXCtrl:
                action = @selector(xCtrlAction:);
                selected = ctrlPressed; 
                break;
            case kXAlt:
                action = @selector(xAltAction:);
                selected = altPressed;
                break;
            case kXCtrlAltDel:
                action = @selector(xCtrlAltDelAction:);
                break;
            default:
                action = @selector(customKeyAction:);
                break;
        }
        
        if (imagePath == nil)
            keyButton = [CustomKeyButton createWithTitle:title
                                                    size:CGSizeMake([[buttons valueForKey:title] integerValue], 35)
                                                delegate:self 
                                                  action:action 
                                                    keys:[self keysForXKeyTag:xButtonTag]];
        else
            keyButton = [CustomKeyButton createWithImageName:title
                                                        size:CGSizeMake([[buttons valueForKey:title] integerValue], 35)
                                                    delegate:self 
                                                      action:action 
                                                        keys:[self keysForXKeyTag:xButtonTag]];
        
        keyButton.selected = selected;
        
        [functionKeys addObject:keyButton];
        
        xButtonTag++;
    }
    
    toolbar.items = functionKeys;
    
    return toolbar;
}
*/

/**
 * Updates keyboard accessory view based on current keyboard type
 */
- (void)updateKeyboardAccessoryView
{
    switch (currentKeyBoardType) {
        case kUnknownType:
            self.keyboardType = UIKeyboardTypeDefault;
            currentKeyboardAccessoryView = nil;
            break;
        case kAlphabeticKeyboard:
            self.keyboardType = UIKeyboardTypeAlphabet;
            currentKeyboardAccessoryView = nil;
            break;
        case kAlphabeticFunKeyboard:
        {
            self.keyboardType = UIKeyboardTypeAlphabet;
            currentKeyboardAccessoryView = [self createFunctionsAccessoryView];
            functionToolbar = [self createFunctionKeysToolbarView];
        }   
            break;
        case kAlphabeticXTabKeyboard:
            self.keyboardType = UIKeyboardTypeAlphabet;
            currentKeyboardAccessoryView = [self createXAccessoryViewWithType:kAlphabeticXTabKeyboard];
            break;
        case kAlphabeticXExtendedDesktopKeyboard:
        {
            self.keyboardType = UIKeyboardTypeAlphabet;
            currentKeyboardAccessoryView = [self createXAccessoryViewWithType:kAlphabeticXExtendedDesktopKeyboard];
        }
            break;
        default:
            break;
    }
}

#pragma mark function/XXX buttons handlers

/**
 * Handles Ctrl+Alt button
 * By default, changes corresponding keyboard flags
 * To customize behavior, override in descendant class
 */
- (void)xCtrlAction:(CustomKeyButton*)button
{
    ctrlPressed = !ctrlPressed;
    button.selected = ctrlPressed;
    // set button to blue when toggled on
    [button setTintColor:(ctrlPressed ? KEYBOARD_TOOLBAR_BUTTON_HIGHLIGHT_COLOR : nil)];
    keyboardFlags = [self updateKeyboardFlags];
}

/**
 * Handles Alt button
 * By default, changes corresponding keyboard flags
 * To customize behavior, override in descendant class
 */
- (void)xAltAction:(CustomKeyButton*)button
{
    altPressed = !altPressed;
    button.selected = altPressed;
    // set button to blue when toggled on
    [button setTintColor:(altPressed ? KEYBOARD_TOOLBAR_BUTTON_HIGHLIGHT_COLOR : nil)];
    keyboardFlags = [self updateKeyboardFlags];
}

/**
 * Handles Ctrl+Alt+Del button
 * By default, does nothing
 * To customize behavior, override in descendant class
 */
- (void)xCtrlAltDelAction:(CustomKeyButton*)button
{
}

/**
 * Handles Toggle Fn keys button
 * By default, toggles keyboard toolbar
 * To customize behavior, override in descendant class
 */
- (void)xToggleFnKeys:(CustomKeyButton*)button
{
    enableFnKeysPressed = [self toggleFunctionKeys:button];
    // toggle function keys and set button to blue when toggled on
    [button setTintColor:(enableFnKeysPressed ? KEYBOARD_TOOLBAR_BUTTON_HIGHLIGHT_COLOR : nil)];
}


/**
 * Handles custom key button
 * By default, does nothing
 * To customize behavior, override in descendant class. 
 * Key id can be obtained from button parameter (button.keys)
 */
- (void)customKeyAction:(CustomKeyButton*)button
{
}

/**
 * Returns FHLib defined key id for corresponding X key tag
 */
- (int)keysForXKeyTag:(XKeyTag)tag
{
    switch (tag) {
        case kXCtrl:
            return 0;
            break;
        case kXAlt:
            return 0;
            break;
        case kXTab:
            return kKbTab;
            break;
        case kXEsc:
            return kKbEsc;
            break;
        case kXDel:
            return kKbDel;
            break;
        case kXInsert:
            return kKbIns;
            break;
        case kXCommand:
            return 0;
            break;
        case kXHome:
            return kKbHome;
            break;
        case kXEnd:
            return kKbEnd;
            break;
        case kXPageUp:
            return kKbPgUp;
            break;
        case kXPageDown:
            return kKbPgDn;
            break;
        case kXLeft:
            return kKbLeft;
            break;
        case kXUp:
            return kKbUp;
            break;
        case kXDown:
            return kKbDown;
            break;
        case kXRight:
            return kKbRight;
            break;
        case kXToggleFnKeys:
            return 0;
            break;
        default:
            return 0;
            break;
    }
}

/**
 * Returns FHLib defined key id for corresponding F key tag
 */
- (int)keysForFunctionKeyTag:(NSInteger)tag
{
    switch (tag) {
        case 1:
            return kKbF1;
            break;
        case 2:
            return kKbF2;
            break;
        case 3:
            return kKbF3;
            break;
        case 4:
            return kKbF4;
            break;
        case 5:
            return kKbF5;
            break;
        case 6:
            return kKbF6;
            break;
        case 7:
            return kKbF7;
            break;
        case 8:
            return kKbF8;
            break;
        case 9:
            return kKbF9;
            break;
        case 10:
            return kKbF10;
            break;
        case 11:
            return kKbF11;
            break;
        case 12:
            return kKbF12;
            break;
        default:
            return 0;
            break;
    }
}

/**
 * Updates keyboard flags based on specific control key flags (ctrl, alt)
 */
- (int)updateKeyboardFlags
{
    int flags = 0;
    
    if (ctrlPressed)
        flags |= kKbModCtrl;
    if (altPressed)
        flags |= kKbModAlt;
    
    return flags;
}

/**
 * resetModeFlags - resets ctrl, alt & insert key flags
 */
- (void) resetModeFlags
{
    ctrlPressed = NO;
    altPressed = NO;
    insPressed = NO;
}


/**
 * Reset all mode flags and buttons selected state to NO
 * Clear all custom buttons to off
 */
- (void) resetXKeyboardModeButtonsSelected
{
    if([currentKeyboardAccessoryView isKindOfClass:[UIToolbar class]] && currentKeyBoardType == kAlphabeticXExtendedDesktopKeyboard && (ctrlPressed || altPressed || insPressed))
    {
        UIToolbar *accessoryToolbar = (UIToolbar *) currentKeyboardAccessoryView;
        
        UIView *view;
        for(view in [accessoryToolbar items])
        {
            if([view isKindOfClass:[CustomKeyButton class]])
            {
                CustomKeyButton *button = (CustomKeyButton *) view;
                if (button.tag!=kXToggleFnKeys)
                {
                    button.selected = NO;
                    // set button to blue when toggled on
                    [button setTintColor:nil];
                }
            }
        }
        [self resetModeFlags];
    }
    
    keyboardFlags = [self updateKeyboardFlags];
}


#pragma mark Keyboard custom buttons control

- (UIView*)listSubviews:(UIView*)view :(NSString*)prefix :(CGPoint)point :(id)parent : (UIView*)previous
{
    DLog(@"%@%@", prefix, view);
    if (view == functionButton || view == xButton)
        return previous;
    
    CGPoint localPoint = [view convertPoint:point fromView:parent];
    
    NSString* newPrefix = [prefix stringByAppendingString:@" "];
    for (UIView* subview in [view subviews])
        previous = [self listSubviews:subview :newPrefix: localPoint :parent :previous];
    
    if ([view isKindOfClass:NSClassFromString(@"UIKBKeyView")] && [view pointInside:localPoint withEvent:nil])
    {
        DLog(@"found!!!%@", view);
        if (previous == nil) 
            previous = view;
        else 
            if (view.frame.origin.y > previous.frame.origin.y)
                previous = view;
    }
    
    return previous;
}

- (void)updateCustomKeyboardButtons:(UIView*)button
{
    CGRect buttonFrame = button.frame;
    CGFloat buttonWidth = buttonFrame.size.width / 2 - 11.0;
    
    if (functionButton == nil)
    {
        functionButton = [CustomButton buttonWithType:UIButtonTypeCustom];
        [self tuneFnKeyButton:functionButton];
        UIImage *image = [[UIImage imageNamed:@"keyBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 11, 8.5)];
        [functionButton setBackgroundImage:image forState:UIControlStateNormal];
        [functionButton addTarget:self action:@selector(functionKeyTap:) forControlEvents:UIControlEventTouchUpInside];
        
        xButton = [CustomButton buttonWithType:UIButtonTypeCustom];
        [self tuneXxKeyButton:xButton];
        [xButton setBackgroundImage:image forState:UIControlStateNormal];
        [xButton addTarget:self action:@selector(xKeyTap:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [functionButton setHideListener:self :@selector(customButtonHide)];
    
    functionButton.frame = CGRectMake(buttonFrame.origin.x, buttonFrame.origin.y, buttonWidth, buttonFrame.size.height);
    
    [button.superview addSubview:functionButton];
    buttonFrame.origin.x += buttonWidth + 11.;
    buttonFrame.size.width -= buttonWidth + 11.;
    
    if (currentKeyBoardType == kAlphabeticKeyboard)
    {
        button.frame = buttonFrame;
    }
    else
    {
        xButton.frame = buttonFrame;
        [button.superview addSubview:xButton];
        [button removeFromSuperview];
    }
}

- (void)tuneFnKeyButton:(CustomButton*)button
{
    [UIUtils layoutKeyboardCustomButton:functionButton];
    [functionButton setTitle:@"Fn" forState:UIControlStateNormal];
}

- (void)tuneXxKeyButton:(CustomButton*)button
{
    [UIUtils layoutKeyboardCustomButton:xButton];
    [xButton setTitle:@"ctrl alt ⌘" forState:UIControlStateNormal];
}

- (void)addCustomButtonToKeyboard
{
    if ((currentKeyBoardType != kAlphabeticFunKeyboard) && (currentKeyBoardType != kAlphabeticXKeyboard) && (currentKeyBoardType != kAlphabeticKeyboard)
        )
        return;
	
    UIWindow* tempWindow;
	UIView* keyboard;
	UIView* subview;
    
	//Check each window in our application
	for(int c = 0; c < [[[UIApplication sharedApplication] windows] count]; c ++)
	{
		//Get a reference of the current window
		tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:c];
		
		//Get a reference of the current view 
		for(int i = 0; i < [tempWindow.subviews count]; i++)
		{
			subview = [tempWindow.subviews objectAtIndex:i];
			
            for(int j = 0; j < [subview.subviews count]; j++)
            {
                keyboard = [subview.subviews objectAtIndex:j];
                
                if([[keyboard description] hasPrefix:@"<UIKeyboardAutomatic"] == YES)
                {
                    UIView *newView = [self listSubviews:keyboard :@" " : CGPointMake(50, 290) : keyboard : nil];
                    if (newView != nil)
                    {
                        buttonView = newView;
                        [self updateCustomKeyboardButtons:buttonView];
                    }
                }
            }
		}
	}
}

- (void)keyboardDidChange:(NSNotification*)notification
{
    if (self.isFirstResponder)
        [self addCustomButtonToKeyboard];
}

- (void)keyboardWillAppear:(NSNotification*)notification 
{
    /* add function keys toolbar if the function key button is selected */
    if (enableFnKeysPressed)
    {
        [self addFunctionKeysToolbar:nil];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification{
    DLog(@"$BlueTooth$ %@",notification);
}

- (void)customButtonBecameHidden:(NSNotification*)notification
{
}

/**
 * Handles function key tap
 */
- (void)functionKeyTap:(id)sender
{
    if (currentKeyBoardType == kAlphabeticKeyboard)
        [self setCurrentKeyboardType:kAlphabeticFunKeyboard];
    else
        [self setCurrentKeyboardType:kAlphabeticKeyboard];
    if (buttonView != nil)
    {
        CGRect newButonFrame = CGRectMake(functionButton.frame.origin.x, functionButton.frame.origin.y, buttonView.frame.origin.x + buttonView.frame.size.width - functionButton.frame.origin.x, buttonView.frame.origin.y + buttonView.frame.size.height - functionButton.frame.origin.y);
        buttonView.frame = newButonFrame;
        if (buttonView.superview == nil)
            [functionButton.superview addSubview:buttonView];
        //        [self updateCustomKeyboardButtons:buttonView];
    }
    [functionButton setHideListener:nil :nil];
    [xButton setHideListener:nil :nil];
    [functionButton removeFromSuperview];
    [xButton removeFromSuperview];
    
    [self resignFirstResponder];
    [self togglekeyboard];
}

- (void)xKeyTap:(id)sender
{
    if (currentKeyBoardType == kAlphabeticXKeyboard)
        [self setCurrentKeyboardType:kAlphabeticFunKeyboard];
    else
        [self setCurrentKeyboardType:kAlphabeticXKeyboard];
    if (buttonView != nil)
    {
        CGRect newButonFrame = CGRectMake(functionButton.frame.origin.x, functionButton.frame.origin.y, buttonView.frame.origin.x + buttonView.frame.size.width - functionButton.frame.origin.x, buttonView.frame.origin.y + buttonView.frame.size.height - functionButton.frame.origin.y);
        buttonView.frame = newButonFrame;
        if (buttonView.superview == nil)
            [functionButton.superview addSubview:buttonView];
        //        [self updateCustomKeyboardButtons:buttonView];
    }
    [functionButton setHideListener:nil :nil];
    [xButton setHideListener:nil :nil];
    [functionButton removeFromSuperview];
    [xButton removeFromSuperview];
    
    [self resignFirstResponder];
    [self togglekeyboard];
}

#pragma mark Custom button event handling

- (void)customButtonHide
{
    [self performSelector:@selector(addCustomButtonToKeyboard) withObject:nil afterDelay:0];
    DLog(@"button hide");
}

#pragma mark

- (void)checkKeyboardButtons
{
/*TODO:    
    if (self.isFirstResponder)
        [self performSelector:@selector(addCustomButtonToKeyboard) withObject:nil afterDelay:0];
*/ 
}

- (int)keyboardFlags
{
    return keyboardFlags;
}

- (NSArray*)xAccessoryButtonsInfoForKeyBoardType:(KeyboardType) typeForXKeyBoard
{
    return nil;
}

- (void)keyboardVisibleChanged:(BOOL)visible
{
    
}

/**
 * Adds function keys toolbar to input accessory view
 */
- (void)addFunctionKeysToolbar:(id)sender
{
    CustomKeyButton *button = (CustomKeyButton *)sender;
    if (self.fnKeysToolbar && self.fnKeysToolbar.popoverVisible) {
        [self.fnKeysToolbar dismissPopoverAnimated:YES];
        [button setTintColor:nil];
        return;
    }
    
    [button setTintColor:KEYBOARD_TOOLBAR_BUTTON_HIGHLIGHT_COLOR];
    // then add function keys toolbar
    fnKeyToolbarController = [[FunctionKeysController alloc] initWithNibName:nil bundle:nil];
    // set delegate for handling function key input
    self.fnKeyToolbarController.functionKeyDelegate = self;
    // add function keys toolbar into view
    DLog(@"Size of PopOver %@",NSStringFromCGRect(fnKeyToolbarController.view.frame));
     self.fnKeysToolbar = [[UIPopoverController alloc] initWithContentViewController:self];
     self.fnKeysToolbar.delegate = self;
    self.fnKeysToolbar.contentViewController = fnKeyToolbarController;
    [self.fnKeysToolbar setPopoverContentSize:fnKeyToolbarController.view.frame.size animated:YES];
    [self.fnKeysToolbar presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

/**
 * Clear function keys toolbar selected
 */
- (void)clearFunctionKeysSelected
{
    UIToolbar *accessoryToolbar = (UIToolbar *) currentKeyboardAccessoryView;

    for (id item in [accessoryToolbar items]) {
        if([item isKindOfClass:[CustomKeyButton class]]){
            CustomKeyButton *button = (CustomKeyButton *)item;
            if (button.tag == kXToggleFnKeys) {
                enableFnKeysPressed = NO;
                [button setTintColor:nil];
            }
        }
    }
}

/**
 * Dismiss keyboard accessory toolbars e.g. function keys
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self clearFunctionKeysSelected];
}

/**
 * Dismiss function keys toolbar.
 */
- (void)dismissFunctionKeys
{
    // clear function key highlight
    [self.fnKeysToolbar dismissPopoverAnimated:NO];
    enableFnKeysPressed = NO;
}

/**
 * Toggle function keys toolbar on and off
 * returns true if function keys are toggled on
 */
- (BOOL)toggleFunctionKeys:(id)sender
{
    // check if fn key view already visible
    if ([self.fnKeysToolbar isPopoverVisible])
    {
        [self.fnKeysToolbar dismissPopoverAnimated:NO];
        return FALSE;
    }
    else
    {
        // if function keys toolbar wasn't already active
        [self addFunctionKeysToolbar:sender];
    }
    return TRUE;
}

/**
 * Create a toolbar with the function keys
 */
- (UIView*)createFunctionKeysToolbarView
{
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [UIUtils layoutKeyboardToolbar:toolbar];
    
    toolbar.frame = CGRectMake(0, 0, 768, 64);
    [toolbar setBarStyle:UIBarStyleBlack];
    [toolbar setTranslucent:YES];

    NSMutableArray *functionKeys = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    CGSize buttonSize = CGSizeMake(KEYBOARD_FUNCTION_BUTTON_WIDTH, KEYBOARD_FUNCTION_BUTTON_HEIGHT);
    
    for (int i = 1; i <= TOTAL_FUNCTION_KEYS; i++)
    {
        CustomKeyButton *keyButton = [CustomKeyButton createWithTitle:[NSString stringWithFormat:@"Fn%d", i] size:buttonSize delegate:self action:@selector(customKeyAction:) keys:[self keysForFunctionKeyTag:i] tag:i];
        
        [functionKeys addObject:keyButton];
        if (i != TOTAL_FUNCTION_KEYS)
            [functionKeys addObject:flexible];
    }
    
    toolbar.items = functionKeys;
    
    return toolbar;
}

@end
