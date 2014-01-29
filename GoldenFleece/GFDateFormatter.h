#import <Foundation/Foundation.h>
#import <ISO8601DateFormatter.h>

@interface GFDateFormatter : NSObject
+ (id) sharedInstance;
@property (strong, nonatomic) ISO8601DateFormatter *formatter;
@end
