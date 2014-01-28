#import <Foundation/Foundation.h>

@interface GitHubGist : NSObject
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSArray *forks;
@end
