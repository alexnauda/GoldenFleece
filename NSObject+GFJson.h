#import <Foundation/Foundation.h>

@interface NSObject (GFJson)
- (id)initWithDictionaryRepresentation:(NSDictionary*)dict;
- (NSDictionary*)dictionaryRepresentation;
@end
