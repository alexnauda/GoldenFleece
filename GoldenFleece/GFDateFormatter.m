#import "GFDateFormatter.h"

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by a compilation flag
#ifdef DEBUG
#   define debug(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define debug(...)
#endif
// info() always displays
#define info(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@implementation GFDateFormatter
+ (id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        _formatter = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

- (NSDate*)dateFromString:(NSString*)dateString {
    if ([dateString isKindOfClass:[NSString class]]) {
        return [self.formatter dateFromString:dateString];
    } else {
        info(@"could not convert this string to a date: %@", dateString);
        return NULL;
    }
}

- (NSString*)stringFromDate:(NSDate*)date {
    if([date isKindOfClass:[NSDate class]]) {
        return [self.formatter stringFromDate:date];
    } else {
        info(@"could not convert this date to a string: %@", date);
        return NULL;
    }
}

@end
