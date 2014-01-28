#import <Cocoa/Cocoa.h>
#import "GFGistWindowController.h"
#import "GFGistCommentWindowController.h"
#import "GFClient.h"

@interface GFAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) GFGistWindowController *gistWindowController;
@property (nonatomic, strong) GFGistCommentWindowController *gistCommentWindowController;
- (IBAction)gistTestClicked:(id)sender;
- (IBAction)gistCommentTestClicked:(id)sender;
@end
