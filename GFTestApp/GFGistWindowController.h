#import <Cocoa/Cocoa.h>
#import "GitHubApi.h"

@interface GFGistWindowController : NSWindowController <GFGetGistCaller>
@property (weak) IBOutlet NSTextField *gistIdTextField;
- (IBAction)findButtonClicked:(id)sender;
@end
