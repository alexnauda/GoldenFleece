#import "NSObject+GFJson.h"
#import <objc/runtime.h>

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by a compilation flag
#ifdef DEBUG
#   define debug(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define debug(...)
#endif
// info() always displays
#define info(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


@implementation NSObject (GFJson)

/*
 Populates an NSObject from a JSON object
 */
- (id)initWithJsonObject:(id)jsonObject {
    debug(@"examining jsonObject of class %@", [jsonObject class]);
    if ([self isJsonPrimitive] && [jsonObject isJsonPrimitive]) {
        /*
         * JSON primitive (return the primitive)
         */
        debug(@"returning object of class %@", [jsonObject class]);
        return jsonObject;
    } else if ([jsonObject isKindOfClass:[NSArray class]] && ![self isKindOfClass:[NSArray class]]) {
        /*
         * JSON array (return an NSArray)
         */
        // the JSON contained an array, but I'm not an array; we'll instantate an array with my class as elements
        NSArray *jsonArray = (NSArray*)jsonObject;
        NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
        for (id jsonElem in jsonArray) {
            id elem = [[[self class] alloc] initWithJsonObject:jsonElem];
            [results addObject:elem];
        }
        debug(@"returning object of class %@", [results class]);
        return results;
    } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        /*
         * JSON object
         */
        if ([self isKindOfClass:[NSDictionary class]]) {
            // a dictionary is expected so pass through the jsonObject dictionary unchanged
            debug(@"returning object of class %@", [jsonObject class]);
            return jsonObject;
        } else {
            NSDictionary *dict = (NSDictionary*)jsonObject;
            // populate self from this dictionary, which represents self in JSON object notation
            NSDictionary *props = [self getPropertiesAndClasses];
            for (NSString *jsonName in [dict allKeys]) {
                NSString *mappingPropertyName = [[self jsonMapping] objectForKey:jsonName];
                NSString *propertyName;
                if (mappingPropertyName) {
                    propertyName = mappingPropertyName;
                } else {
                    propertyName = jsonName;
                }
                Class propertyClass = [props objectForKey:propertyName];
                if (propertyClass) {
                    id propertyValue = [[propertyClass alloc] initWithJsonObject:[dict objectForKey:jsonName]];
                    [self setValue:propertyValue forKey:propertyName];
                } else {
                    debug(@"did not find a property in class %@ that matches JSON name %@", [self class], jsonName);
                }
            }
            debug(@"returning object of class %@", [self class]);
            return self;
        }
    } else {
        NSLog(@"unsupported JSON object class %@", [jsonObject class]);
        debug(@"returning nil");
        return nil;
    }
}

/*
 Converts an NSObject to a JSON object, which Apple defines as...
 
 "An object that may be converted to JSON must have the following properties:
 The top level object is an NSArray or NSDictionary.
 All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
 All dictionary keys are instances of NSString.
 Numbers are not NaN or infinity."
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
        NSDictionary *reverseMapping = [self reverseMapping];
        for (NSString *propName in [props allKeys]) {
            NSString *jsonName = [reverseMapping objectForKey:propName];
            if (!jsonName) {
                jsonName = propName;
            }
            id propValue = [self valueForKeyPath:propName];
            if (propValue) {
                [result setObject:[propValue jsonObject] forKey:jsonName];
            } else {
                [result setObject:[NSNull null] forKey:jsonName];
            }
        }
        return result;
    }
}

- (NSDictionary*)reverseMapping {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[[self jsonMapping] count]];
    for (NSString *jsonName in [self jsonMapping]) {
        [result setObject:jsonName forKey:[[self jsonMapping] objectForKey:jsonName]];
    }
    return result;
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
        } else if ([@"@\"NSString\"" isEqualToString:propertyType] || [@"@\"NSNumber\"" isEqualToString:propertyType] || [@"@\"NSNull\"" isEqualToString:propertyType] || strcmp(rawPropertyType, @encode(id)) == 0) {
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

/*
 Override this method if the properties in your custom object do not match the keys in
 the JSON object. For example, if the JSON object contains keys that are disallowed in
 Objective-C, you may need to names those properties differently in your object.
 
 Return an NSDictionary in which the keys correspond to the JSON keys and the values
 correspond to your property names.
 
 Example:
 - (NSDictionary*)jsonMapping {
    return @{
             @"signed" : @"isSigned"
             }
 }
 */
- (NSDictionary*)jsonMapping {
    return @{};
}

@end
