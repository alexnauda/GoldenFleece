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
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    GFClient *gf = [GFClient sharedInstance];
    gf.httpClient = client;
    
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

/**
 * Send a request with the object serialized into JSON in the response body, 
 * and deserialize the response body (also JSON) using the pre-configured entities
 */
- (void) jsonRequestWithObject:(NSObject*)object
                          path:(NSString*)path
                        method:(NSString*)method
                 expectedClass:(Class)class
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure {    
    // convert the object into a JSON request body
    // RestKit doesn't like nested custom objects so I'm using AutomagicCoding and JSONKit
    NSDictionary *dict = [object dictionaryRepresentation];
    NSError *error = NULL;
    NSData* jsonData = NULL;
    if (object) {
        jsonData = [dict JSONDataWithOptions:JKSerializeOptionNone
               serializeUnsupportedClassesUsingBlock:^id(id object) {
                   if([object isKindOfClass:[NSDate class]]) { return([NSDate stringFromDate:(NSDate*)object withFormat:@"yyyy-MM-dd"]); }
                   return(NULL);
               }
                                               error:&error];
        if(jsonData == NULL) {
            NSLog(@"Unable to serialize request body.  Error: %@, info: %@", error, [error userInfo]);
            failure(nil, nil, error);
        } else {
            NSLog(@"JSON data: %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        }
    }
    [self jsonRequestWithData:jsonData path:path method:method expectedClass:class success:success failure:failure];
}

/**
 * Send a request with the provided JSON data in the response body,
 * and deserialize the response body (also JSON) using the pre-configured entities
 */
- (void) jsonRequestWithData:(NSData*)data
                        path:(NSString*)path
                      method:(NSString*)method
               expectedClass:(Class)class
                     success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:nil];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"saveClientContact post data: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    // now run it
    AFJSONRequestOperation *operation =
        [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                            id object = [[class alloc] initWithDictionaryRepresentation:(NSDictionary*)JSON];
                                                            success(request, response, object);
                                                        }
                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                            failure(request, response, error);
                                                        }];
    [operation start];
}

@end
