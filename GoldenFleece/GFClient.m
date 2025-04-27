/*
 Copyright 2014 Alex Nauda
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
#import "GFClient.h"
#import "NSDate+Helper.h"
#import "NSObject+GFJson.h"

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by a compilation flag
#ifdef GF_DEBUG
#   define debug(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define debug(...)
#endif
// info() always displays
#define info(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@implementation GFClient {
    dispatch_queue_t backgroundQueue;
}

+ (id)createWithHttpClient:(AFHTTPSessionManager*)client {
    GFClient *gf = [GFClient sharedInstance];
    return [gf initWithHttpClient:client];
}

- (id)initWithHttpClient:(AFHTTPSessionManager*)client {
    if (self = [super init]){
        [self setup];
        [[client requestSerializer] setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        // [client setDefaultHeader:@"Accept" value:@"application/json"];
        self.httpClient = client;
#if GF_ALLOW_INVALID_CERT
        
        AFSecurityPolicy *sec=[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        [sec setAllowInvalidCertificates:YES];
        [sec setValidatesDomainName:NO];
        self.httpClient.securityPolicy=sec;
#endif
        
        if (!self.cacheResponses) {
            [self.httpClient setDataTaskWillCacheResponseBlock:^NSCachedURLResponse * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSCachedURLResponse * _Nonnull proposedResponse) {
                return nil;
            }];
            
            [self.httpClient.session.configuration setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData ];
            self.httpClient.session.configuration.URLCache = nil;
        }
        
        if (self.additionalAcceptableContentTypes) {
            self.httpClient.responseSerializer.acceptableContentTypes = [self.httpClient.responseSerializer.acceptableContentTypes setByAddingObjectsFromSet:self.additionalAcceptableContentTypes];
        }
        
    }
    return self;
}

- (id)init {
    return [self initWithHttpClient:[AFHTTPSessionManager manager]];
}

- (void)setup {
    backgroundQueue = dispatch_queue_create("GFClient", 0);
    _cacheResponses = YES;
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
                       success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                       failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure {
    [self jsonRequestWithObject:object path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithObject:(NSObject*)object
                          path:(NSString*)path
                        method:(NSString*)method
                 expectedClass:(Class)class
                       success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                       failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure
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
                     success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                     failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure {
    [self jsonRequestWithData:data path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithData:(NSData*)data
                        path:(NSString*)path
                      method:(NSString*)method
               expectedClass:(Class)class
                     success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                     failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure
                  background:(BOOL)background {
    
    NSString* baseURL = [self.httpClient.baseURL absoluteString];
    
    NSMutableURLRequest *request = [[self.httpClient requestSerializer] requestWithMethod:method URLString:[NSString stringWithFormat:@"%@/%@",baseURL,path] parameters:nil error:nil];
    
    // NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:nil];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // debug(@"post data: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    if (background) {
        [self.httpClient setCompletionQueue:backgroundQueue];
    }
    
    NSURLSessionDataTask* dataTask = [self.httpClient dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable json, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(request,response, error);
            }
        } else {
            if (success) {
                id object = [[class alloc] initWithJsonObject:json];
                success(request,response, object);
            }
        }
        
    }];
    
    
    
    
    [dataTask resume];
    
    
    
    
}

- (void) jsonRequestWithParameters:(NSDictionary*)parameters
                              path:(NSString*)path
                            method:(NSString*)method
                     expectedClass:(Class)class
                           success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                           failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure {
    [self jsonRequestWithParameters:parameters path:path method:method expectedClass:class success:success failure:failure background:NO];
}

- (void) jsonRequestWithParameters:(NSDictionary*)parameters
                              path:(NSString*)path
                            method:(NSString*)method
                     expectedClass:(Class)class
                           success:(void (^)(NSURLRequest *request, NSURLResponse *response, id object))success
                           failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error))failure
                        background:(BOOL)background {
    NSString* baseURL = [self.httpClient.baseURL absoluteString];
    NSMutableURLRequest *request = [[self.httpClient requestSerializer] requestWithMethod:method URLString:[NSString stringWithFormat:@"%@/%@",baseURL,path] parameters:parameters error:nil];
    
    
    
    if (background) {
        [self.httpClient setCompletionQueue:backgroundQueue];
    }
    
    NSURLSessionDataTask* dataTask = [self.httpClient dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable json, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(request,response, error);
            }
        } else {
            if (success) {
                id object = [[class alloc] initWithJsonObject:json];
                success(request,response, object);
            }
        }
        
    }];
    
    [dataTask resume];
    
}

@end
