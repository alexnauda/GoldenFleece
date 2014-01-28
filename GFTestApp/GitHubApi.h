#import <Foundation/Foundation.h>
#import "GitHubComment.h"
#import "GitHubGist.h"
#import "GFClient.h"

@protocol GFPostGistCommentCaller <NSObject>
@required
- (void) postGistCommentSucceeded:(GitHubComment*)comments;
- (void) postGistCommentError:(NSError*)error;
@end

@protocol GFGetGistCaller <NSObject>
@required
- (void) getGistSucceeded:(GitHubGist*)gist;
- (void) getGistError:(NSError*)error;
@end

@interface GitHubApi : NSObject
@property (strong, nonatomic) GFClient *gf;
+ (id)sharedInstance;

- (void)postGistComment:(GitHubComment*)comment forGist:(NSString*)gistId delegate:(id<GFPostGistCommentCaller>)delegate;
- (void)getGist:(NSString*)gistId delegate:(id<GFGetGistCaller>)delegate;

@end
