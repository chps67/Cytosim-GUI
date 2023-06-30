//
//  VConfigModelCreator.m
//  Cytosim GUI
//
//  Created by Chris on 15/05/2023.
//

#import "VConfigModelCreator.h"
#import "VAppDelegate.h"

@implementation VConfigModelCreator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.configObjects = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
    
}



-(VConfigObject*) createSingle {
    
    VConfigObject* newSingle = [[VConfigObject alloc]init];
    newSingle.objType = @"single";
    newSingle.parent = nil;
    
    newSingle.children = [NSMutableArray arrayWithCapacity:0];
    VConfigObject* newHand = [[VConfigObject alloc]init];
    newHand.objType = @"hand";
    [newSingle.children addObject:newHand];
    newHand.parent = newSingle;
    
    [self.configObjects addObject:newSingle];
    
    return newSingle;
}

-(void) readParametersForObject:(VConfigObject*)object {
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    [del choseCommandAndObjectCombination:object];
    [del.configObjectCreator readPropFromObject:object];
}

-(void) writeParametersForObject:(VConfigObject*)object {
    
}

@end
