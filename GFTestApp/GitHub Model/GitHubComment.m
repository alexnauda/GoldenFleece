#import "GitHubComment.h"

@implementation GitHubComment

- (NSDictionary*)jsonMapping {
    // you only need a jsonMapping if your property names don't match the JSON keys
    return @{
             @"id": @"gistId"
             };
}

@end
