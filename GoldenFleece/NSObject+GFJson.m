#import "NSObject+GFJson.h"
#import <objc/runtime.h>

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by the DEBUG compilation flag, which is set by default when you run in Xcode
#ifdef DEBUG
#   define debug(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define debug(...)
#endif
// info() always displays
#define info(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


@implementation NSObject (GFJson)

- (id)initWithJsonObject:(id)jsonObject {

    
    return NULL;
}

/*
 An object that may be converted to JSON must have the following properties:
 
 The top level object is an NSArray or NSDictionary.
 All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
 All dictionary keys are instances of NSString.
 Numbers are not NaN or infinity.
 */
- (id)jsonObject {
    if ([self isKindOfClass:[NSArray class]]) {
        return [self toJsonArray];
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        return [self toJsonDictionary];
    } else if ([self isJsonPrimitive]) {
        return self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [self dateToJsonString];
    } else {
        return [self toJsonDictionary]; // any other NSObject subclass
    }
}

- (NSMutableArray*)toJsonArray {
    NSArray *array = (NSArray*)self;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSObject *elem in array) {
        [result addObject:[elem jsonObject]];
    }
    return result;
}

- (NSMutableDictionary*)toJsonDictionary {
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary*)self;
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
        for (id key in [dict allKeys]) {
            [result setValue:[dict objectForKey:key] forKey:key];
        }
        return result;
    } else {
        // any NSObject subclass
        NSDictionary *props = [self getPropertiesAndClasses];
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[props count]];
        for (NSString *propName in [props allKeys]) {
            id propValue = [props objectForKey:propName];
            if (propValue) {
                [result setObject:propValue forKey:propName];
            } else {
                [result setObject:[NSNull null] forKey:propName];
            }
        }
        return result;
    }
}

- (NSDictionary*)getPropertiesAndClasses {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    unsigned int count;
    objc_property_t *props = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        const char *type = property_getAttributes(property);
        NSString *typeString = [NSString stringWithUTF8String:type];
        NSArray *attributes = [typeString componentsSeparatedByString:@","];
        NSString *typeAttribute = [attributes objectAtIndex:0];
        NSString *propertyType = [typeAttribute substringFromIndex:1];
        const char *rawPropertyType = [propertyType UTF8String];
        
        if (strcmp(rawPropertyType, @encode(float)) == 0) {
            debug(@"ERROR property %@ has type float, which is not supported", propertyName);
        } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
            debug(@"ERROR property %@ has type int, which is not supported", propertyName);
        } else if (strcmp(rawPropertyType, @encode(id)) == 0) {
            if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 1) {
                NSString * className = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  // remove @"..."
                debug(@"property %@ has class %@", propertyName, className);
                Class clazz = NSClassFromString(className);
                if (clazz != nil) {
                    [result setObject:clazz forKey:propertyName];
                } else {
                    debug(@"ERROR could not get class of property %@", propertyName);
                }
            }
        } else {
            debug(@"ERROR property %@ has unrecognized type %s", propertyName, rawPropertyType);
        }
    }
    free(props);
    
    return result;
}

- (NSString*)dateToJsonString {
    return NULL;
}

- (BOOL)isJsonPrimitive {
    return
    [self isKindOfClass:[NSString class]] ||
    [self isKindOfClass:[NSNumber class]] ||
    [self isKindOfClass:[NSNull class]];
}

@end
