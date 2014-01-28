#import "GitHubGist.h"

@implementation GitHubGist

- (NSDictionary*)jsonClasses {
    return @{
             @"forks" : [GitHubGist class]
             };
}

@end
