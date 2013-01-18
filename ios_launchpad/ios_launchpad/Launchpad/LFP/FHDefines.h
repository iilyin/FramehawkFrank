/**
 * @file
 * FHDefines.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.1.2.12317  Built: Wed Nov 21 09:06:10 PST 2012
 *
 * Defines for use in communicating using the Framehawk SDK
 * - including key codes, mouse buttons and connection states.
 *
 * @brief Defines.
 */


#ifndef __FH_DEFINES_H
#define __FH_DEFINES_H

#define FRAMEHAWK_SDK_VERSION "3.1.2.12317"

#define FHK_RECEIVE_BUFFER_SLOT_COUNT 64
#define FHK_SEND_BUFFER_SLOT_COUNT 10

typedef unsigned char byte_t;


// Use platform-specific threading rather than STL
#define OLD_THREADS


// Client supports local scrolling functionality
//#define CLIENT_SCROLL

// Buffer scrolling
//#define SMOOTH_TAU


//Server supports new scroll protocol
//#define NEW_SCROLL

#define BUFFER_FORMAT_RGBA 0
#define BUFFER_FORMAT_ARGB 1
#define BUFFER_FORMAT_BGRA 2

#define BUFFER_FORMAT BUFFER_FORMAT_RGBA

//#define PNG_SUPPORTED
#define ENABLE_ENCRYPTION
//#define PARTIAL_UPDATE

#ifndef ___max
//#  ifdef __cplusplus
//#    define ___max std::max
//#  else
#    define ___max(a, b) ( b < a ? a : b)
//#  endif
#else
#  ifdef __cplusplus
#    define max std::max
#  endif
#endif

#ifndef ___min
//#  ifdef __cplusplus
//#    define ___min std::min
//#  else
#    define ___min(a, b) ( b < a ? b : a)
//#  endif
#else
#  ifdef __cplusplus
#    define min std::min
#  endif
#endif


#ifdef FHANDROID
#include <android/log.h>
#    define ___max(a, b) ( b < a ? a : b)
#    define ___min(a, b) ( b < a ? b : a)
#define JPG_SUPPORTED

#define  LOG_TAG    "SirPaul"
#ifdef DEBUG
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#else
#define  LOGI(...) 
#endif
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)
#define RENDER_TOP_DOWN 1

#else
#include <stdio.h>
#include <stdarg.h>

#ifdef __APPLE__

#include "TargetConditionals.h"


#if (TARGET_OF_IPHONE_SIMULATOR) || (TARGET_OS_IPHONE) || (TARGET_IPHONE)
#define TARGET_OF_IPHONE
#define TARGET_OPENGLES
#else
#define TARGET_OSX
#endif

# if TARGET_OS_IPHONE
#  define JPG_SUPPORTED
//#  define CLIENT_SCROLL
#  if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_0
#   define SESSION_MODE
#  endif
# endif //TARGET_OS_IPHONE

# ifdef TARGET_OSX
#  define JPG_SUPPORTED
#  define SESSION_MODE
#  define PNG_SUPPORTED
#  undef OLD_THREADS
# endif //TARGET_OSX

#ifdef PNG_SUPPORTED
#define APPLE_PNG
#endif

#endif //__APPLE__

void __fh_log(const char* level, const char * tag, const char *fmt, ...);

typedef void(*logfunc)(const char* level, const char * tag, const char *fmt, ...);

#ifdef DEBUG
#define LOG_INFO
#endif

#ifdef LOG_INFO
#define  LOGI(...)  __fh_log("INFO", "FH", __VA_ARGS__)
#define  LOGID(TAG, ...)  __fh_log("INFO", TAG, __VA_ARGS__)
#define  LOGD(TAG, ...)  __fh_log("DEBUG", TAG, __VA_ARGS__)
#else
#define  LOGI(...)  __fh_log("INFO", "FH", __VA_ARGS__)
#define  LOGID(TAG, ...)
#define  LOGD(TAG, ...)
#endif


#define  LOGE(...)  __fh_log("ERROR", "FH", __VA_ARGS__)
#define  LOGED(TAG, ...)  __fh_log("ERROR", TAG, __VA_ARGS__)


#if TARGET_OS_IPHONE 
#define RENDER_TOP_DOWN 0
#else
#define RENDER_TOP_DOWN 1
#endif
#endif

#ifdef _WINDOWS
#define JPG_SUPPORTED
#define WIN_PTHREADS
#define OLD_THREADS

#define RENDER_TOP_DOWN 1
#define ssize_t size_t
#define sleep _sleep
#endif


/**
 * Mouse button defines, for mouse button events.
 */
typedef enum mouseButtons 
{
    kMouseButtonNone,
    kMouseButtonLeft,
    kMouseButtonScroll,
    kMouseButtonRight
} mouseButtons;


/**
 * Special keyboard key defines (for standard keys send Unicode characters).
 */
typedef enum kbdKeys 
{   
    kKbEnter = 0xEF0D, kKbBksp  = 0xEF08, kKbTab   = 0xEF09, kKbEsc   = 0xEF1B,
    kKbDel   = 0xEFFF, kKbPgUp  = 0xEF55, kKbPgDn  = 0xEF56, kKbHome  = 0xEF50,
    kKbLeft  = 0xEF51, kKbUp    = 0xEF52, kKbRight = 0xEF53, kKbDown  = 0xEF54,
    kKbEnd   = 0xEF57, kKbIns   = 0xEFCE,
    kKbF1    = 0xEFBE, kKbF2    = 0xEFBF, kKbF3    = 0xEFC0, kKbF4    = 0xEFC1,
    kKbF5    = 0xEFC2, kKbF6    = 0xEFC3, kKbF7    = 0xEFC4, kKbF8    = 0xEFC5,
    kKbF9    = 0xEFC6, kKbF10   = 0xEFC7, kKbF11   = 0xEFC8, kKbF12   = 0xEFC9
} kbdKeys;


/**
 * Keyboard modifier flag defines for alt, control & shift. Can be or-ed tegether.
 * Passed as the modifier parameter on sendKeyXXXMessage in FHConnection.h
 */
typedef enum kbdModifiers 
{
    kKbModNone  = 0,
    kKbModShift = 1,
    kKbModCtrl  = 2,
    kKbModAlt   = 4
} kbdModifiers;


/**
 * Connection states reported to the connection delegate.
 * This is shared with the client through the connectionStatusChange callback.
 */
typedef enum connectionStates 
{
    kConnNotConnected,
    kConnConnectionFailed,
    kConnConnectedOK,
    kConnConnectedSlow,
    kConnConnectionClosedNormally,
    kConnConnectionDiedUnexpectedly,
    kConnClientInitializationFailure
} connectionStates;


/**
 * Connection feature flags.
 * Passed as a parameter to initConnection and used
 * in the confirmConnectionFeatureFlags callback
 * in the connection delegate.
 */
typedef enum connectionFeatureFlags 
{
    kNoConnectionFeatures = 0x00,
    kAudioRequested       = 0x04,
    kInterlacingRequested = 0x10
} connectionFeatureFlags;


#endif
