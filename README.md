GoldenFleece
============

On a quest for a better JSON API

GoldenFleece is a JSON helper for Objective-C, inspired by [Jackson](http://wiki.fasterxml.com/JacksonHome).
* It serializes your custom Objective-C objects to JSON, and it deserializes JSON into your custom Objective-C objects.
* It uses plain old Objective-C objects (any subclass of NSObject) and does not require you to extend any base object.
* It includes GFClient, a JSON API client helper based on the excellent and popular AFNetworking.

In addition to the examples below, this repository includes a minimal Mac app that runs a few test requests against GitHub's public API and serves as an example of how to write an API using GoldenFleece.

## Quick Example

Let's say you are consuming (or want to generate) JSON that looks like this:
```
{
    "itemId":"8675309",
    "widgetCount":42
}
```
Code an Objective-C object like this:
```objective-c
/*
 * Item.h
 */
@interface Item : NSObject

@property (strong, nonatomic) NSString *itemId;
@property (strong, nonatomic) NSNumber *widgetCount;

@end
```
```objective-c
/*
 * Item.m
 */
#import "Item.h"

@implementation Item

@end
```
GoldenFleece will then serialize and deserialize this to/from JSON with a one liner. If you have your JSON in an NSString, it might look like this:
```objective-c
Item *item = [[Item alloc] initWithJsonObject:[NSJSONSerialization JSONObjectWithData:[yourJsonString dataUsingEncoding:NSUTF8StringEncoding]]];
```
If you're getting your JSON from a REST API call, continue reading for an example of how to make a call.

GoldenFleece also has some more sophisticated features, including support for nested custom objects in properties, custom objects in NSArray and NSDictionary (values only) as well as ISO 8601 string formats to and from NSDate.

## Installation

We recommend [CocoaPods](http://cocoapods.org/).
```
pod 'GoldenFleece', '~> 1.1'
```

If you'd rather install GoldenFleece manually in your project, include all the *.m and *.h files under the GoldenFleece subdirectory.

## Use

Initialize it once, somewhere in your app (for example, in your app delegate):
```objective-c
#import <GFClient.h>

/* ... */

// initialize HTTPClient
NSURL *baseURL = [NSURL URLWithString:@"https://api.github.com"]; // the base URL of your API
AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
// initialize GoldenFleece
[GFClient createWithHttpClient:client];
```

Make a call to an API:
```objective-c
[[GFClient sharedInstance] jsonRequestWithObject:nil
                                            path:[NSString stringWithFormat:@"gists/%@", gistId]
                                          method:@"GET"
                                   expectedClass:[GitHubGist class]
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id object) {
                                             GitHubGist *result = (GitHubGist*)object;
                                             [delegate getGistSucceeded:result];
                                         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                             [delegate getGistError:error];
                                         }
];
```
After executing the request, GoldenFleece will alloc your custom object (in this example, GitHubGist) and populate it from the JSON response. If the response contains an array, it will create an NSArray of your custom object.

You can also pass JSON in the request body:
```objective-c
[[GFClient sharedInstance] jsonRequestWithObject:comment // <-- this will be converted to JSON and sent as the request entity body
                                            path:[NSString stringWithFormat:@"gists/%@/comments", gistId]
                                          method:@"POST"
                                   expectedClass:[GitHubComment class]
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id object) {
                                             GitHubComment *result = (GitHubComment*)object;
                                             [delegate postGistCommentSucceeded:result];
                                         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                             [delegate postGistCommentError:error];
                                         }
];
```

##Nested Custom Objects
GoldenFleece uses Objective-C introspection to look inside your custom objects and instantiate the proper class for each property. If you have a property that is an NSArray or NSDictionary, you can instruct GoldenFleece to instantiate a custom object of your choice for the elements/values therein:
```objective-c
- (NSDictionary*)jsonClasses {
    return @{
             @"forks" : [GitHubGist class]
             };
}
```

##Optional Mapping
By default, GoldenFleece relies on the convention that the properties in your custom objects match the keys in JSON objects verbatim. If this isn't the case, or if the JSON you're working with happens to collide with some Objective-C reserved words, you can specify a custom mapping:
```objective-c
- (NSDictionary*)jsonMapping {
    return @{
             // JSON key : property name
             @"id": @"gistId"
             };
}
```
