#import "GFAppDelegate.h"

@implementation GFAppDelegate

@synthesize gistWindowController = _gistWindowController;
@synthesize gistCommentWindowController = _gistCommentWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // initialize HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"https://api.github.com"];
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    // initialize GoldenFleece
    GFClient __unused *gf = [GFClient createWithHttpClient:client];
}

- (GFGistWindowController*)gistWindowController {
    if (!_gistWindowController) {
        _gistWindowController = [[GFGistWindowController alloc] initWithWindowNibName:@"GFGistWindowController"];
    }
    return _gistWindowController;
}

- (GFGistCommentWindowController*)gistCommentWindowController {
    if (!_gistCommentWindowController) {
        _gistCommentWindowController = [[GFGistCommentWindowController alloc] initWithWindowNibName:@"GFGistCommentWindowController"];
    }
    return _gistCommentWindowController;
}

- (IBAction)gistTestClicked:(id)sender {
    [self.gistWindowController showWindow:self];
}

- (IBAction)gistCommentTestClicked:(id)sender {
    [self.gistCommentWindowController showWindow:self];
}
@end
