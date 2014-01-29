#import <Foundation/Foundation.h>

@interface GitHubGist : NSObject
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSArray *forks;
@property (strong, nonatomic) NSDate *created_at;
@end
