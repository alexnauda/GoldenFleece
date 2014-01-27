#import "GitHubApi.h"

@implementation GitHubApi

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    self = [super init];
    if (!self.gf) {
        self.gf = [GFClient sharedInstance];
    }
    return self;
}

- (id)initWithGFClient:(GFClient*)gfClient {
    self = [super init];
    [self setGf:gfClient];
    return self;
}

- (void)postGistComment:(GitHubComment*)comment forGist:(NSString*)gistId delegate:(id<GFPostGistCommentCaller>)delegate {
    [self.gf jsonRequestWithObject:comment // <-- this will be converted to JSON and sent as the request entity body
                               path:[NSString stringWithFormat:@"gists/%@/comments", gistId] // <-- this is relative to the baseUrl used when instantiating AFHTTPClient
                             method:@"POST"
                      expectedClass:[GitHubComment class] // <-- this request returns a JSON object; pass in the class to instantiate and populate from it
                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id object) {
                                GitHubComment *result = (GitHubComment*)object;
                                [delegate postGistCommentSucceeded:result];
                            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                [delegate postGistCommentError:error];
                            }
     ];
}

@end
