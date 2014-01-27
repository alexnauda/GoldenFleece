#import <Cocoa/Cocoa.h>

@interface GFFindUserWindowController : NSWindowController
@property (weak) IBOutlet NSTextField *usernameTextField;
- (IBAction)findButtonClicked:(id)sender;
@end
