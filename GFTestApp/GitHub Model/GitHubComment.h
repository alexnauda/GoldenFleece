#import <Foundation/Foundation.h>

@interface GitHubComment : NSObject
@property (strong, nonatomic) NSNumber *gistId;
@property (strong, nonatomic) NSString *body;
@end
