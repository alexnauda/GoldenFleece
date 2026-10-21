#import <Foundation/Foundation.h>
#import "NSObject+GFJson.h"
#import "GFDateFormatter.h"

@interface GFTestDiagnosis : NSObject
@property (nonatomic, copy) NSString *diagnosisCode;
@end
@implementation GFTestDiagnosis
@end

@interface GFTestService : NSObject
@property (nonatomic, copy) NSString *serviceCode;
@property (nonatomic, strong) NSDecimalNumber *amountBilled;
@property (nonatomic, strong) NSDate *startDateOfService;
@property (nonatomic, strong) NSArray *diagnosisList;
@property (nonatomic, copy) NSString *statusNote;
@end
@implementation GFTestService
@end

@interface GFTestRequest : NSObject
@property (nonatomic, strong) NSArray *serviceLineItem;
@property (nonatomic, strong) NSNumber *practitionerId;
@end
@implementation GFTestRequest
@end

// Reproduce a Foundation subclass taking precedence over an NSObject category.
@interface GFCollidingArray : NSArray
@property (nonatomic, copy) NSArray *values;
- (instancetype)initWithValues:(NSArray *)values;
- (id)jsonObject;
@end
@implementation GFCollidingArray
- (instancetype)initWithValues:(NSArray *)values {
    self = [super init];
    if (self) {
        _values = [values copy];
    }
    return self;
}
- (NSUInteger)count { return self.values.count; }
- (id)objectAtIndex:(NSUInteger)index { return self.values[index]; }
- (id)jsonObject { return @[]; }
@end

static NSUInteger failures;
static void check(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        failures++;
    }
}

int main(void) {
    @autoreleasepool {
        GFTestDiagnosis *diagnosis = [GFTestDiagnosis new];
        diagnosis.diagnosisCode = @"F3162";
        GFTestService *service = [GFTestService new];
        service.serviceCode = @"90834";
        service.amountBilled = [NSDecimalNumber decimalNumberWithString:@"150.25"];
        service.startDateOfService = [[[GFDateFormatter sharedInstance] formatter] dateFromString:@"2026-10-19"];
        service.diagnosisList = [[GFCollidingArray alloc] initWithValues:@[diagnosis]];

        GFCollidingArray *colliding = [[GFCollidingArray alloc] initWithValues:@[service]];
        check([[colliding jsonObject] count] == 0, @"collision fixture returns the failing empty array");

        NSArray *arrayVariants = @[@[service], [NSMutableArray arrayWithObject:service], colliding];
        for (NSArray *services in arrayVariants) {
            GFTestRequest *request = [GFTestRequest new];
            request.practitionerId = @814000000000000143LL;
            request.serviceLineItem = services;
            NSDictionary *json = [request gfJsonObject];
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
            check(data != nil && error == nil, @"request produces valid JSON bytes");
            if (!data) { continue; }
            NSDictionary *wire = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            check([wire[@"practitionerId"] isEqual:request.practitionerId], @"large integer ID survives wire serialization");
            NSArray *lines = wire[@"serviceLineItem"];
            check(lines.count == 1, @"service survives immutable, mutable, and colliding arrays");
            if (lines.count != 1) { continue; }
            NSDictionary *line = lines[0];
            check([line[@"serviceCode"] isEqual:@"90834"], @"service code survives");
            check([line[@"amountBilled"] isEqualToNumber:service.amountBilled], @"decimal fee survives");
            check([line[@"startDateOfService"] isEqual:@"2026-10-19"], @"date uses the configured wire format");
            check([line[@"statusNote"] isEqual:[NSNull null]], @"absent values remain JSON null");
            check([line[@"diagnosisList"] isEqual:@[@{@"diagnosisCode": @"F3162"}]], @"nested colliding diagnosis array survives");
        }
        check([[@[] gfJsonObject] isEqual:@[]], @"empty arrays remain empty");
        check([[[@[@"text", @1, @YES, [NSNull null]] mutableCopy] gfJsonObject] isEqual:@[@"text", @1, @YES, [NSNull null]]], @"primitive array values survive");
        GFTestDiagnosis *decoded = [[GFTestDiagnosis alloc] initWithJsonObject:@{@"diagnosisCode": @"F3162"}];
        check([decoded.diagnosisCode isEqual:@"F3162"], @"deserialization remains available");
        if (failures == 0) { puts("PASS: GoldenFleece serialization regression tests"); }
    }
    return failures == 0 ? 0 : 1;
}
