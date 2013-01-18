//
//  ProfileStorageManagement.m
//  Launchpad
//
//  Created by Hursh Prasad on 8/8/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "ProfileStorageManagement.h"
#import "CommandCenter.h"

@implementation ProfileStorageManagement
+(void)storeProfile:(NSNumber *)profileId{

    [File createDirectory:[NSString stringWithFormat:@"%@",profileId]]; //make sure directory is created
    
    NSArray *assetContainers = [NSArray arrayWithObjects:@"buttons",@"skin",nil]; 
    NSDictionary *currProfile = [[CommandCenter get] getCurrentProfile];
    
    //assume only two level hierarchy
    for (NSString *key in currProfile) {
       // DLog(@"key %@ type %@",key,[[currProfile objectForKey:key] class]);
        if ([[currProfile objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            
            for (NSString *assetKey in assetContainers) {
                
                if ([key isEqualToString:assetKey]) {
                    [self downloadAssetsFor:[currProfile objectForKey:key]
                                   assetUrl:launchpadServiceUrl
                                    profileID:profileId];
                }
            }
            
        }else if ([[currProfile objectForKey:key] isKindOfClass:[NSArray class]]){ //Assume nested is in Array
                for (NSDictionary *assetDict in [currProfile objectForKey:key]) {
                    for (NSString *nestedKey in assetDict) {
                        for (NSString *assetKey in assetContainers) {
                            
                            if ([nestedKey isEqualToString:assetKey]) {
                                [self downloadAssetsFor:[assetDict objectForKey:nestedKey]
                                               assetUrl:launchpadServiceUrl
                                                profileID:profileId];
                            }
                        }
                    }
                }
        }
    }
    
    return;
}
+(void)deleteProfile:(NSString *)profileId{
    
    [File deleteDirectory:[NSString stringWithFormat:@"%@",profileId]];
    
    return;
}
+(void)downloadAssetsFor:(id)assetDictionary assetUrl:(NSString *)baseUrl profileID:(NSNumber *)profileId{
    
    if([assetDictionary isKindOfClass:[NSArray class]]){
        for (NSDictionary *dict in (NSArray *)assetDictionary) {
            for (NSString *key in dict) {
                if ([[dict objectForKey:key] isKindOfClass:[NSString class]])
                    if ([[[dict objectForKey:key] pathExtension] isEqualToString:@"png"] ||
                        [[[dict objectForKey:key] pathExtension] isEqualToString:@"jpg"]) {
                         //DLog(@"FILE: %@",[dict objectForKey:key]);
                        [self downLoadAssetToFile:[dict objectForKey:key]
                                        profileID:profileId];
                    }
                }
            }
    }else{
        for (NSString *key in (NSDictionary *)assetDictionary) {
                if ([[(NSDictionary *)assetDictionary objectForKey:key] isKindOfClass:[NSString class]])
                    if ([[[(NSDictionary *)assetDictionary objectForKey:key] pathExtension] isEqualToString:@"png"] ||
                        [[[(NSDictionary *)assetDictionary objectForKey:key] pathExtension] isEqualToString:@"jpg"]) {
                          //DLog(@"FILE: %@",[(NSDictionary *)assetDictionary objectForKey:key]);
                        [self downLoadAssetToFile:
                                        [(NSDictionary *)assetDictionary objectForKey:key]
                                        profileID:
                                            profileId];
        
            }
        }
    }
}
+(void)downLoadAssetToFile:(NSString *)url profileID:(NSNumber *)profileId{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"GET"];
    
        NSError  *err = nil;
        NSData *data = nil;
    
        NSHTTPURLResponse* response = nil;
    
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
                   
        if (err != nil) {
            DLog(@"URL ERROR .... %@ %@",url,err);
            return;
        } // Download error
        
        if ([response respondsToSelector:@selector(statusCode)])
        {
            int statusCode = [ response statusCode ];
            if (statusCode == 404)
            {
                DLog(@"404 response from %@ ",url);
            }
        }
        //DLog(@"%@",[[NSString stringWithFormat:@"%@/%@%@",[File getDocumentPath],profileId,[[NSURL URLWithString:url] path]] stringByReplacingOccurrencesOfString:[url lastPathComponent] withString:@""]);
        
        [[NSFileManager defaultManager]
         createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@%@",[File getDocumentPath],profileId,[[[NSURL URLWithString:url] path] stringByReplacingOccurrencesOfString:[url lastPathComponent] withString:@""]]
         withIntermediateDirectories:YES attributes:nil error:nil];
        
        if ([File writeFile:data fileName:[NSString stringWithFormat:@"/%@%@",profileId,[[NSURL URLWithString:url] path]]] != NO) {
            DLog(@"Downloaded and Saved file.... %@",[NSString stringWithFormat:@"/%@%@",profileId,[[NSURL URLWithString:url] path]]);
        }else{
            DLog(@"Failed to save file.... %@",[NSString stringWithFormat:@"/%@%@",profileId,[[NSURL URLWithString:url] path]]);
        }
    });
}
@end
