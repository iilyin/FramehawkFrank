/**
 * @file
 * ProfileDefines.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 *
 * Defines for accessing profile information sent from Framehawk Studio
 *
 * @brief Defines for profile keys.
 */

#ifndef __PROFILE_DEFINES_H
#define __PROFILE_DEFINES_H

// This key is inserted by the client when storing the server address to access data from
#define kProfileLaunchpadServiceUrlKey              @"launchpadServiceUrl"

// Calls to access profile information
#define kFramehawkGetProfilesList                   @"/getprofileslist"
#define kFramehawkGetProfile                        @"/getprofile?profileId=%@"

// Keys for accessing values from profile information sent from Framehawk Studio

// profile information
#define kProfileInfoKey                             @"profileInfo"
#define kProfileNameKey                             @"profileName"
#define kProfileIdKey                               @"profileId"
//#define kProfileDescriptionKey                    @"profileDescription"
#define kProfileVersionKey                          @"profileVersion"

// profile skin information
#define kProfileSkinKey                             @"skin"
#define kProfileGroupLabelTextColorKey              @"buttonGroupLabelTextColor"
#define kProfileKeyboardActivateTabKey              @"keyboardActivateTab"
#define kProfileMenuCloseServiceIconKey             @"menuCloseServiceIcon"
#define kProfileMenuDrawerBackgroundKey             @"menuDrawerBackground"
#define kProfileMenuDrawerBackgroundColorKey        @"menuDrawerBackgroundColor"
#define kProfileMenuDrawerLogoKey                   @"menuDrawerLogo"
#define kProfileMenuDrawerTabKey                    @"menuDrawerTab"
//#define kProfileLoginAssistSelectedKey            @"menuEasyLoginSelected"
//#define kProfileLoginAssistUnselectedKey          @"menuEasyLoginUnselected"
//#define kProfileHelpSelectedKey                   @"menuHelpSelected"
//#define kProfileHelpUnselectedKey                 @"menuHelpUnselected"
#define kProfileMenuItemSelectedBackgroundKey       @"menuItemSelectedBackground"
#define kProfileMenuItemUnselectedBackgroundKey     @"menuItemUnselectedBackground"
//#define kProfilePressedButtonTextColorKey         @"menuPressedButtonTextColor"
//#define kProfileProfilesSelectedKey               @"menuProfilesSelected"
//#define kProfileProfilesUnselectedKey             @"menuProfilesUnselected"
#define kProfileMenuRowDividerKey                   @"menuRowDivider"
//#define kProfileMenuSearchIconKey                 @"menuSearchIcon"
#define kProfileMenuSectionBottomDividerKey         @"menuSectionBottomDivider"
#define kProfileMenuSectionTopDividerKey            @"menuSectionTopDivider"
//#define kProfileMenuSelectedButtonTextColorKey    @"menuSelectedButtonTextColor"
//#define kProfileMenuSettingsSelectedKey           @"menuSettingsSelected"
//#define kProfileMenuSettingsUnselectedKey         @"menuSettingsUnselected"
#define kProfileMenuToolbarBackgroundKey            @"menuToolbarBackground"
//#define kProfileMenuToolbarDividerKey             @"menuToolbarDivider"
//#define kProfileMenuUnselectedButtonTextColorKey  @"menuUnselectedButtonTextColor"
//#define kProfileMenuPressedButtonImageKey         @"pressedButtonImage"
#define kProfileMenuPressedButtonImageKey           @"pressedButtonTextColor"
#define kProfileMenuSelectedButtonTextColorKey      @"selButtonTextColor"
//#define kProfileMenuSelectedButtonImageKey        @"selectedButtonImage"
#define kProfileServiceSplashBackgroundKey          @"serviceSplashBackground"
#define kProfileServiceSplashBackgroundColorKey     @"serviceSplashBackgroundColor"
#define kProfileServiceSplashLogoKey                @"serviceSplashLogo"
//#define kProfileMenuThemeIdKey                    @"theme_id"
#define kProfileMenuUnselectedButtonTextColorKey    @"unselButtonTextColor"
//#define kProfileMenuUnselectedButtonImageKey      @"unselectedButtonImage"
 
// button groups
#define kProfileButtonGroupsKey                     @"buttonGroups"
#define kProfileButtonsKey                          @"buttons"
#define kProfileButtonLabelKey                      @"buttonGroupLabel"
// button icons
#define kProfileButtonIconKey                       @"button_icon"
#define kProfileSelectedButtonIconKey               @"selected_button_icon"
//#define kProfileUnselectedButtonIconKey             @"unselected_button_icon"
// service information
#define kProfileServiceLabelKey                     @"label"
#define kProfileServiceIdKey                        @"service_id"
#define kProfileServiceUrlKey                       @"service_url"
#define kProfileServiceRegionKey                    @"service_region"
#define kProfileServiceTypeKey                      @"service_type_id"
#define kProfileServiceArgumentsKey                 @"exec_args"
#define kProfileBrowserUrlKey                       @"browser_url"
#define kProfileServiceGestureMapKey                @"gesture_map_id"
#define kProfileServiceKeyboardTypeKey              @"keyboard_type_id"
#define kProfileServiceLoginAssistantToggleKey      @"eli_mode"
#define kProfileServiceLoginAssistantAllowedKey     @"login_assistant_allowed"
#define kProfileServiceIsStaticKey                  @"is_static"

#endif