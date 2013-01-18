//
//  File.h
//
//  File Utility Class
//
//  Created by Hursh Prasad on 3/29/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

@interface File : NSObject
//Directory create and delete, used for profiles
+(BOOL)createDirectory:(NSString*)path;
+(BOOL)deleteDirectory:(NSString *)path;

//Strictly for getting current profile storage
+(NSString *)getProfileImagePath:(NSString *)imageName;

+(BOOL)checkFileExists:(NSString*)path;
+(NSString *)getDocumentPath;
+(NSString *)getFilePath:(NSString *)name;

+(BOOL)writeFile:(id)data fileName:(NSString*)name;
+(NSDictionary *)readFile:(NSString *)name;
+(id)readData:(NSString *)name;
@end