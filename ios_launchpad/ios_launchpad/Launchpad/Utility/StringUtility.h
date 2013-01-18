//
//  StringUtility.h
//
//  String Utility Class
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

@interface NSString (URLEncoding)
@property (readonly) NSString *URLEncodedString;
@end

@implementation NSString (URLEncoding)
/*
 * URLEncodedString - replaces any spaces inside of
 * a string with %20 (e.g. to allow handling of graphics files
 * that contain spaces).
 */
- (NSString*)URLEncodedString
{
    NSString *result = [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return result;
}
@end