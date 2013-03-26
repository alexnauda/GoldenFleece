//
//  GFClient.m
//  PurePractice
//
//  Created by Alex on 3/22/13.
//  Copyright (c) 2013 Electronic Remedy, Inc. All rights reserved.
//

#import "GFClient.h"
#import "NSObject+AutoMagicCoding.h"
#import <JSONKit/JSONKit.h>
#import <NSDate+Helper.h>

@implementation GFClient

+ (id)createWithHttpClient:(AFHTTPClient*)client {
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    GFClient *gf = [GFClient sharedInstance];
    gf.httpClient = client;
    
    // initialize RestKit
    gf.objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    gf.objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    
    return gf;
}

+ (id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (GFEntity*)addClass:(Class)clazz forKey:(NSString*)key {
    GFEntity *entity = [[GFEntity alloc] initWithClass:clazz];
    if (entity.responseMapping) {
        [self autoResponseDescriptor:entity.responseMapping forKey:key];
    }
    if (entity.requestMapping) {
        [self autoRequestDescriptor:entity.requestMapping forClass:clazz];
    }
    return entity;
}

/**
 * Send a request with JSON in the response body, and deserialize the response body (also JSON) using the pre-configured entities
 */
- (void) jsonRequestWithObject:(NSObject*)object
                          path:(NSString*)path
                        method:(NSString*)method
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, RKMappingResult *result))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:nil];
    
    // convert the object into a JSON request body
    // RestKit doesn't like nested custom objects so I'm using AutomagicCoding and JSONKit
    NSDictionary *dict = [object dictionaryRepresentation];
    NSError *error = NULL;
    NSData *jsonData = [dict JSONDataWithOptions:JKSerializeOptionNone
           serializeUnsupportedClassesUsingBlock:^id(id object) {
               if([object isKindOfClass:[NSDate class]]) { return([NSDate stringFromDate:(NSDate*)object withFormat:@"yyyy-MM-dd"]); }
               return(NULL);
           }
                                           error:&error];
    if(jsonData == NULL) {
        NSLog(@"Unable to serialize request body.  Error: %@, info: %@", error, [error userInfo]);
        failure(request, nil, error);
    }
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"saveClientContact post data: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    // now run it
    RKObjectManager *objectManager = self.objectManager;
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:[objectManager responseDescriptors]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
                                        success([[operation HTTPRequestOperation] request], [[operation HTTPRequestOperation] response], [result firstObject]);
                                     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                         failure([[operation HTTPRequestOperation] request], [[operation HTTPRequestOperation] response], error);
                                     }];
    [operation start];
}

- (void)autoResponseDescriptor:(RKObjectMapping*)objectMapping forKey:(NSString*)key
{
    [self.objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:objectMapping pathPattern:nil keyPath:key statusCodes:[NSIndexSet indexSetWithIndex:200]]];
}

- (void)autoRequestDescriptor:(RKObjectMapping*)requestMapping forClass:(Class)clazz
{
    [self.objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:clazz rootKeyPath:nil]];
}

@end
