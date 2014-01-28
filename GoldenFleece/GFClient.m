//
//  GFClient.m
//  PurePractice
//
//  Created by Alex on 3/22/13.
//  Copyright (c) 2013 Electronic Remedy, Inc. All rights reserved.
//

#import "GFClient.h"
#import <NSDate+Helper.h>
#import <ISO8601DateFormatter.h>
#import "NSObject+GFJson.h"

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by a compilation flag
#ifdef DEBUG
#   define debug(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define debug(...)
#endif
// info() always displays
#define info(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

static ISO8601DateFormatter *formatter;

@implementation GFClient {
    dispatch_queue_t backgroundQueue;
}

+ (id)createWithHttpClient:(AFHTTPClient*)client {
    GFClient *gf = [GFClient sharedInstance];
    return [gf initWithHttpClient:client];
}

- (id)initWithHttpClient:(AFHTTPClient*)client {
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    self.httpClient = client;
    return self;
}

+ (void)initialize {
    formatter = [[ISO8601DateFormatter alloc] init];
}

- (id)init {
    if (self = [super init]){
        backgroundQueue = dispatch_queue_create("com.proj.myClass", 0);
    }
    self.dateToStringBlock = ^NSString*(NSDate* date) {
        if([date isKindOfClass:[NSDate class]]) {
            return([formatter stringFromDate:date]);
        }
        return nil;
    };
    return self;
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
    [self jsonRequestWithObject:object path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithObject:(NSObject*)object
                          path:(NSString*)path
                        method:(NSString*)method
                 expectedClass:(Class)class
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                    background:(BOOL)background {
    // convert the object into a JSON request body
    NSDictionary *dict = [object jsonObject];
    NSError *error = NULL;
    NSData* jsonData = NULL;
    if (object) {
        jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if(jsonData == NULL) {
            info(@"Unable to serialize request body.  Error: %@, info: %@", error, [error userInfo]);
            failure(nil, nil, error);
        } else {
            debug(@"Sending JSON data: %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        }
    }
    [self jsonRequestWithData:jsonData path:path method:method expectedClass:class success:success failure:failure background:background];
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
    [self jsonRequestWithData:data path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithData:(NSData*)data
                        path:(NSString*)path
                      method:(NSString*)method
               expectedClass:(Class)class
                     success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                  background:(BOOL)background {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:nil];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // debug(@"post data: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    // now run it
    AFJSONRequestOperation *operation =
        [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
                                                            id object = [[class alloc] initWithJsonObject:json];
                                                            debug(@"Received JSON object %@", json);
                                                            success(request, response, object);
                                                        }
                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
                                                            failure(request, response, error);
                                                        }];
    if (self.additionalAcceptableContentTypes) {
        [AFJSONRequestOperation addAcceptableContentTypes:self.additionalAcceptableContentTypes];
    }
    if (background) {
        [operation setSuccessCallbackQueue:backgroundQueue];
    }
    [operation start];
}

- (void) jsonRequestWithParameters:(NSDictionary*)parameters
                              path:(NSString*)path
                            method:(NSString*)method
                     expectedClass:(Class)class
                           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                           failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure {
    [self jsonRequestWithParameters:parameters path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithParameters:(NSDictionary*)parameters
                              path:(NSString*)path
                            method:(NSString*)method
                     expectedClass:(Class)class
                           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id object))success
                           failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                        background:(BOOL)background {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:parameters];
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
                                                        id object = [[class alloc] initWithJsonObject:json];
                                                        debug(@"Received JSON object %@", json);
                                                        success(request, response, object);
                                                    }
                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
                                                        failure(request, response, error);
                                                    }];
    if (self.additionalAcceptableContentTypes) {
        [AFJSONRequestOperation addAcceptableContentTypes:self.additionalAcceptableContentTypes];
    }
    if (background) {
        [operation setSuccessCallbackQueue:backgroundQueue];
    }
    [operation start];
}

@end
