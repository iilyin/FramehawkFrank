//
//  File.m
//
//  Created by Hursh Prasad on 3/29/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//
#import "MenuCommands.h"
#import "SettingsUtils.h"
#import "File.h"

@implementation File

+(NSString *)getDocumentPath{
    //return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
    //        stringByReplacingOccurrencesOfString:@" " withString:@"\\ " ];
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            //        stringByReplacingOccurrencesOfString:@" " withString:@"\\ " ];
}
+(BOOL)createDirectory:(NSString*)path{
    
    DLog(@"%@",[[self getDocumentPath] stringByAppendingPathComponent:path]);
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[self getDocumentPath] stringByAppendingPathComponent:path]])  //Does directory already exist?
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[[self getDocumentPath] stringByAppendingPathComponent:path]
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error])
        {
            NSAssert(error != nil, @"Document Directory Can not be written to.");
        }
    }
    
    return YES;
}
+(BOOL)deleteDirectory:(NSString *)path{
    NSString *deletedPath = [[self getDocumentPath] stringByAppendingPathComponent:path];
    return [[NSFileManager defaultManager] removeItemAtPath:deletedPath error:nil];
}
+(NSString *)getFilePath:(NSString *)name{
    
    NSString* path = [[self getDocumentPath] stringByAppendingPathComponent:name];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        
        return path;
    
    }else if([[NSFileManager defaultManager] fileExistsAtPath:
              [[[NSBundle mainBundle] bundlePath] 
               stringByAppendingPathComponent:name]]){
                  
                  return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:name];
    }
    
    return nil;
}
+(NSString *)getProfileImagePath:(NSString *)imageName{
    
    // Assume I can always get current profileID
    NSString    *defaultProfileId = [SettingsUtils getSelectedProfileId];
    
    if (!imageName || [[imageName description] length] < 1) {
        DLog(@"Empty Images %@",imageName);
        return nil;
    }
    
    if ([imageName characterAtIndex:0] == '/'){
        //DLog(@"Image Pulled:%@",[[self getDocumentPath] stringByAppendingFormat:@"/%@%@",defaultProfileId,imageName]);
               return [[self getDocumentPath] stringByAppendingFormat:@"/%@%@",defaultProfileId,imageName];
    }
    
    //DLog(@"Image Pulled:%@",[[self getDocumentPath] stringByAppendingFormat:@"/%@/%@",defaultProfileId,imageName]);
    return [[self getDocumentPath] stringByAppendingFormat:@"/%@/%@",defaultProfileId,imageName];
}
+(NSDictionary *)readFile:(NSString *)name{
    
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[File getFilePath:name]];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    NSDictionary *unarchivedData = [unarchiver decodeObjectForKey:@"data"];
    [unarchiver finishDecoding];
    
    return unarchivedData;
}
+(id)readData:(NSString *)name{
    
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[File getFilePath:name]];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    id unarchivedData = [unarchiver decodeObjectForKey:@"data"];
    [unarchiver finishDecoding];
    
    return unarchivedData;
}
+(BOOL)checkFileExists:(NSString*)path{
    //DLog(@"Checking File:%@",path);
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}
+(BOOL)writeFile:(id)filedata fileName:(NSString*)name{
    // get graphic path
    NSString* path = [[self getDocumentPath] stringByAppendingPathComponent:name];
    // get graphic file extension
    NSString* pathExtension = [[name pathExtension] lowercaseString];
    // check graphic file format is supported by iOS
    if ([pathExtension isEqualToString:@"png"]
        || [pathExtension isEqualToString:@"tif"]
        || [pathExtension isEqualToString:@"tiff"]
        || [pathExtension isEqualToString:@"jpeg"]
        || [pathExtension isEqualToString:@"jpg"]
        || [pathExtension isEqualToString:@"gif"]
        || [pathExtension isEqualToString:@"bmp"]
        || [pathExtension isEqualToString:@"bmpf"]
        || [pathExtension isEqualToString:@"ico"]
        || [pathExtension isEqualToString:@"cur"]
        || [pathExtension isEqualToString:@"xbm"]
        ){
        UIImage *image = [[UIImage alloc] initWithData:filedata];
        NSData *imgData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            if (![imgData writeToFile:path atomically:YES]) {
                DLog(@"Could Not Save File... %@",path);
                return NO;
            }
    }
    else{
    
    //for saving Dictionary or plists
    NSMutableData *archivedData = [[NSMutableData alloc]init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
    [archiver encodeObject:filedata forKey:@"data"];
    [archiver finishEncoding];
    
    if (![archivedData writeToFile:path atomically:YES]){
        return NO;
    }
    }
    
    //DLog(@"SAVED >>> %@",path);
    return YES;
}
@end