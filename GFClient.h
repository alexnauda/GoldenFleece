//
//  GFClient.h
//  PurePractice
//
//  Created by Alex on 3/22/13.
//  Copyright (c) 2013 Electronic Remedy, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "GFEntity.h"

@interface GFClient : NSObject
+ (id)createWithHttpClient:(AFHTTPClient*)client;
+ (id) sharedInstance;

- (GFEntity*)addClass:(Class)clazz forKey:(NSString*)key;

- (void) jsonRequestWithObject:(NSObject*)object
                          path:(NSString*)path
                        method:(NSString*)method
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

@property (strong, atomic) RKObjectManager* objectManager;
@property (strong, atomic) AFHTTPClient* httpClient;
@end
