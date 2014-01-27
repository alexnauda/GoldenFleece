#import <Cocoa/Cocoa.h>
#import "GitHubApi.h"

@interface GFGistCommentWindowController : NSWindowController <GFPostGistCommentCaller>
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *commentTextField;
@property (weak) IBOutlet NSTextField *gistIdTextField;
- (IBAction)postButtonClicked:(id)sender;
@end
