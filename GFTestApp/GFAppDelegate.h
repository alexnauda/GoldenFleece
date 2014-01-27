#import <Cocoa/Cocoa.h>
#import "GFFindUserWindowController.h"
#import "GFGistCommentWindowController.h"
#import "GFClient.h"

@interface GFAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) GFFindUserWindowController *findUserWindowController;
@property (nonatomic, strong) GFGistCommentWindowController *gistCommentWindowController;
- (IBAction)gitHubUserTestClicked:(id)sender;
- (IBAction)gistCommentTestClicked:(id)sender;
@end
