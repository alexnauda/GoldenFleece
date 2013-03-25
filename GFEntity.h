//
//  GFEntity.h
//  PurePractice
//
//  Created by Alex on 3/22/13.
//  Copyright (c) 2013 Electronic Remedy, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface GFEntity : NSObject
- (id)initWithClass:(Class)clazz;
- (void)addChild:(GFEntity*)childEntity forKey:(NSString*)key;
@property (atomic) Class clazz;
@property (strong, atomic) RKObjectMapping* responseMapping;
@property (strong, atomic) RKObjectMapping* requestMapping;
@end
