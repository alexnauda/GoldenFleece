//
//  GFEntity.m
//  PurePractice
//
//  Created by Alex on 3/22/13.
//  Copyright (c) 2013 Electronic Remedy, Inc. All rights reserved.
//

#import "GFEntity.h"
#import <objc/runtime.h>

@implementation GFEntity

- (id)initWithClass:(Class)clazz {
    self = [super init];
    self.clazz = clazz;
    NSLog(@"Adding response mapping for class %@", clazz);
    RKObjectMapping* responseMapping = [RKObjectMapping mappingForClass:clazz];
    [self autoAddAttributes:responseMapping];
    self.responseMapping = responseMapping;
    
    if ([clazz respondsToSelector:@selector(AMCEnabled)]) {
        NSLog(@"Adding request mapping for class %@", clazz);
        RKObjectMapping* requestMapping = [RKObjectMapping requestMapping];
        [self autoAddAttributes:requestMapping];
        self.requestMapping = requestMapping;
    } else {
        NSLog(@"Class %@ does not respond to selector AMCEnabled", clazz);
        NSLog(@"If you want to serialize this class as JSON in a request body, please add this to your .m:");
        NSLog(@"+ (BOOL)AMCEnabled { return YES; }");
    }
    return self;
}

- (void)addChild:(GFEntity*)childEntity forKey:(NSString *)key {
    RKObjectMapping* childMapping = childEntity.responseMapping;
    [self.responseMapping removePropertyMapping:[[self.responseMapping propertyMappingsBySourceKeyPath] valueForKey:key]];
    [self.responseMapping addRelationshipMappingWithSourceKeyPath:key mapping:childMapping];
}

- (void)autoAddAttributes:(RKObjectMapping*)mapping {
    // dynamically introspect the class and add attribute mappings identical to its properties
    NSMutableArray *propertyArray;
    propertyArray = [self copyPropertiesFromClass:self.clazz];
    // add the properties to the mapping
    [mapping addAttributeMappingsFromArray:propertyArray];
}

- (NSMutableArray *)copyPropertiesFromClass:(Class)clazz {
    // build an array of all this class's properties
    u_int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
    }
    free(properties);
    
    // add properties from the super as well
    Class superclazz = class_getSuperclass(clazz);
    if (superclazz != [NSObject class]) {
        [propertyArray addObjectsFromArray:[self copyPropertiesFromClass:[clazz superclass]]];
    }
    
    return propertyArray;
}

@end
