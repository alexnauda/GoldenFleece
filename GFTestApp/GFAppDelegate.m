#import "GFAppDelegate.h"

@implementation GFAppDelegate

@synthesize findUserWindowController = _findUserWindowController;
@synthesize gistCommentWindowController = _gistCommentWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // initialize HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"https://api.github.com"];
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    // initialize GoldenFleece
    GFClient __unused *gf = [GFClient createWithHttpClient:client];
}

- (GFFindUserWindowController*)findUserWindowController {
    if (!_findUserWindowController) {
        _findUserWindowController = [[GFFindUserWindowController alloc] initWithWindowNibName:@"GFFindUserWindowController"];
    }
    return _findUserWindowController;
}

- (GFGistCommentWindowController*)gistCommentWindowController {
    if (!_gistCommentWindowController) {
        _gistCommentWindowController = [[GFGistCommentWindowController alloc] initWithWindowNibName:@"GFGistCommentWindowController"];
    }
    return _gistCommentWindowController;
}

- (IBAction)gitHubUserTestClicked:(id)sender {
    [self.findUserWindowController showWindow:self];
}

- (IBAction)gistCommentTestClicked:(id)sender {
    [self.gistCommentWindowController showWindow:self];
}
@end
