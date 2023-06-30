//
//  VConfigModelCreator.m
//  Cytosim GUI
//
//  Created by Chris on 15/05/2023.
//

#import "VConfigModelCreator.h"
#import "VAppDelegate.h"
#import "VConfigObjectCreator.h"
#import "VCymParameter.h"
#import "VConfigParameter.h"

@implementation VConfigModelCreator

@synthesize currObj;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.configObjects = [NSMutableArray arrayWithCapacity:0];
        self.configInstances = [NSMutableArray arrayWithCapacity:0];
        self.currObj = nil;
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

-(void) readParametersFromCurrentObject {
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSOutlineView* ov = del.paramOutlineView;
    [del choseCommandAndObjectCombination:self.currObj];
    //[ov reloadData];
    for (VConfigParameter* src in self.currObj.objParameters) {
    }
}

-(void) writeParametersToCurrentObject{
    [self.currObj.objParameters removeAllObjects];
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSOutlineView* ov = del.paramOutlineView;
    for (NSInteger k =0; k < ov.numberOfRows; k++ ) {
        VCymParameter* p = [ov itemAtRow:k];
        if (p.used.boolValue == YES) {
            VConfigObjectCreator* oc = del.configObjectCreator;
            VConfigParameter* cp = [[VConfigParameter alloc]initWithName:[oc trimmedName:p.parent.cymKey] Type:[oc trimmedName:p.parent.cymKey] Value:p.cymValueObject OwnerName:p.parent.cymKey Instance:NO InstanceCount:0 HelpString:@""];
            [self.currObj.objParameters addObject:cp];
        }
    }

}

@end
