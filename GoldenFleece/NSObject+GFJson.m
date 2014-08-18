/*
 Copyright 2014 Alex Nauda
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
#import "NSObject+GFJson.h"
#import <objc/runtime.h>
#import "GFDateFormatter.h"

// log macros (adding features to NSLog) that output the code line number
// debug() is enabled by a compilation flag
#ifdef GF_DEBUG
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
        if ([self isKindOfClass:[NSDecimalNumber class]]) {
            return [NSDecimalNumber decimalNumberWithDecimal:[jsonObject decimalValue]];
        } else {
            /*
             * JSON primitive (return the primitive)
             */
            debug(@"returning object of class %@", [jsonObject class]);
            return jsonObject;
        }
    } else if ([self isKindOfClass:[NSDate class]]) {
        if ([jsonObject isKindOfClass:[NSString class]]) {
            self = [self initWithDateString:(NSString*)jsonObject];
        }
        debug(@"returning object of class %@", [self class]);
        return self;
    } else if ([jsonObject isKindOfClass:[NSArray class]]) {
        /*
         * JSON array (return an NSArray)
         */
        if ([self isKindOfClass:[NSArray class]]) {
            // return the array plain and simple
            return jsonObject;
        } else {
            // the JSON contained an array, but I'm not an array; we'll instantate an array with my class as elements
            NSArray *jsonArray = (NSArray*)jsonObject;
            NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
            for (id jsonElem in jsonArray) {
                id elem = [[[self class] alloc] initWithJsonObject:jsonElem];
                [results addObject:elem];
            }
            debug(@"returning object of class %@", [results class]);
            return results;
        }
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
                // check jsonMapping for any special configuration on this field
                NSString *mappingPropertyName = [[self jsonMapping] objectForKey:jsonName];
                NSString *propertyName;
                if (mappingPropertyName) {
                    propertyName = mappingPropertyName;
                } else {
                    propertyName = jsonName;
                }
                
                // look at the class of the property itself
                Class propertyClass = [props objectForKey:propertyName];

                // check jsonClasses for any special configuration on this field
                Class jsonClass = [self getJsonClass:propertyName];
                Class instantiateClass = jsonClass ? jsonClass : propertyClass;
                if (propertyClass) {
                    if ([propertyClass isSubclassOfClass:[NSDictionary class]] && jsonClass && ![jsonClass isSubclassOfClass:[NSDictionary class]]) {
                        // special case: normally we try to instantiate an NSDictionary as a custom class
                        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
                        for (NSString *key in [dict allKeys]) {
                            id customValue = [[instantiateClass alloc] initWithJsonObject:[dict objectForKey:jsonName]];
                            [result setObject:customValue forKey:key];
                        }
                        debug(@"returning object of class %@", result);
                        return result;
                    } else {
                        // this block handles both custom classes and NSArrays
                        if ([[dict objectForKey:jsonName] isKindOfClass:[NSNull class]] || ![dict objectForKey:jsonName]) {
                            // do nothing; accept default value of property, which should be nil or zero or false
                        } else {
                            id propertyValue = [[instantiateClass alloc] initWithJsonObject:[dict objectForKey:jsonName]];
                            [self setValue:propertyValue forKey:propertyName];
                        }
                    }
                } else {
                    debug(@"did not find a property in class %@ that matches JSON name %@", [self class], jsonName);
                }
            }
            debug(@"returning object of class %@", [self class]);
            return self;
        }
    } else if ([jsonObject isKindOfClass:[NSNull class]]) {
        // do nothing; leave this property nil
        return nil;
    } else {
        NSLog(@"unsupported JSON object class %@", [jsonObject class]);
        debug(@"returning nil");
        return nil;
    }
}

- (id)initWithDateString:(NSString*)dateString {
    return [[GFDateFormatter sharedInstance] dateFromString:dateString];
}

- (Class)getJsonClass:(NSString*)propertyName {
    Class jsonClass = [[self jsonClasses] objectForKey:propertyName];
    if (!jsonClass) {
        // support legacy GoldenFleece functionality that was based on NSObject+AutomagicCoding
        SEL selector = sel_registerName("AMCElementClassForCollectionWithKey:");
        if ([self respondsToSelector:selector]) {
            
            // if you don't understand this part, please read http://stackoverflow.com/a/20058585/318912
            IMP imp = [self methodForSelector:selector];
            Class (*func)(id, SEL, NSString*) = (void *)imp;
            jsonClass = func(self, selector, propertyName);
            
            if (jsonClass == [NSObject class]) {
                // the legacy method returned NSObject as the default, but here we expect nil as the default
                jsonClass = nil;
            }
        }
    }
    return jsonClass;
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
        return [[GFDateFormatter sharedInstance] stringFromDate:(NSDate*)self];
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
    return [self getPropertiesAndClasses:[self class]];
}


- (NSDictionary*)getPropertiesAndClasses:(Class)clazz {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    if (!([clazz superclass] == [NSObject class])) {
        [result addEntriesFromDictionary:[self getPropertiesAndClasses:[clazz superclass]]];
    }
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(clazz, &count);
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
        
        if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 1) {
            NSString * className = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  // remove T@"..."
            debug(@"property %@ has class %@", propertyName, className);
            Class clazz = NSClassFromString(className);
            if (clazz != nil) {
                [result setObject:clazz forKey:propertyName];
            } else {
                debug(@"ERROR could not get class of property %@", propertyName);
            }
        } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
            debug(@"ERROR property %@ has type int, which is not supported", propertyName);
        } else if (strcmp(rawPropertyType, @encode(BOOL)) == 0) {
            [result setObject:[NSNumber class] forKey:propertyName];
        } else if (strcmp(rawPropertyType, @encode(long long)) == 0) {
            [result setObject:[NSNumber class] forKey:propertyName];
        } else if (strcmp(rawPropertyType, @encode(float)) == 0) {
            debug(@"ERROR property %@ has type float, which is not supported", propertyName);
        }  else {
            debug(@"ERROR property %@ has unrecognized type %s", propertyName, rawPropertyType);
        }
    }
    free(props);
    
    return result;
}

- (BOOL)isJsonPrimitive {
    return
    [self isKindOfClass:[NSString class]] ||
    [self isKindOfClass:[NSNumber class]] ||
    [self isKindOfClass:[NSNull class]];
}

/*
 Override this method to specify an element class for NSArray or NSDictionary contents.
 
 Return an NSDictionary of NSString : Class. While deserializing JSON, if GoldenFleece
 encounters an NSArray or NSDictionary property with a name matching the key, it will
 deserialize the contents by instantiating and populting the specified Class as a nested 
 custom object for each element in the JSON array. Please note that the keys in this
 dictionary correspond to the property names (not the JSON keys).
 
 Example:
 - (NSDictionary*)jsonClasses {
    return @{
             @"comments" : [MyComment class],
             @"addresses" : [MyAddress class]
             };
 }
 */
- (NSDictionary*)jsonClasses {
    return @{};
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
