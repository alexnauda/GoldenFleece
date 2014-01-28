#import "GitHubGist.h"

@implementation GitHubGist

- (NSDictionary*)jsonClasses {
    return @{
             @"forks" : [GitHubGist class]
             };
}

/*
// legacy method still supported for backward compatibility with GoldenFleece 0.4
- (Class)AMCElementClassForCollectionWithKey:(NSString*)key {
    if ([@"forks" isEqualToString:key]) {
        return [GitHubGist class];
    }
    return [NSObject class];
}
*/

@end
