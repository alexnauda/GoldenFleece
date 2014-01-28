#import "GFGistWindowController.h"

@interface GFGistWindowController ()

@end

@implementation GFGistWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)findButtonClicked:(id)sender {
    NSLog(@"find gist %@", self.gistIdTextField.stringValue);
    [[GitHubApi sharedInstance] getGist:self.gistIdTextField.stringValue delegate:self];
    
}

- (void)getGistSucceeded:(GitHubGist *)gist {
    if (gist) {
        NSLog(@"gist: %@ with %ld forks", gist, [gist.forks count]);
        if ([gist.forks count]) {
            for (GitHubGist *fork in gist.forks) {
                NSLog(@"  fork: %@", fork);
            }
        }
    } else {
        NSLog(@"get gist result was nil");
    }
}

- (void)getGistError:(NSError *)error {
    NSLog(@"get gist failed: %@", [error localizedDescription]);
}

@end
