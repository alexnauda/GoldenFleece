#import <Cocoa/Cocoa.h>

@interface GFGistWindowController : NSWindowController
@property (weak) IBOutlet NSTextField *gistIdTextField;
- (IBAction)findButtonClicked:(id)sender;
@end
