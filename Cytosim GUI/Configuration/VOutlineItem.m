//
//  VOutlineItem.m
//  Cytosim GUI
//
//  Created by Chris on 27/02/2023.
//

#import "VOutlineItem.h"
#import "VConfigParameter.h"
#import "VConfigInstance.h"
#import "VConfigObject.h"

@implementation VOutlineItem

@synthesize expandable, parent, children, configParameter;

// config object's or instance's title ----------------------------------------

- (instancetype)initWithInstanceTitle:(VConfigInstance*)inst
{
    self = [super init];
    if (self) {
        self.expandable = YES;
        //self.model = nil;     // set upon the extraction in VConfigModel
        
        self.parent = nil;      // set upon the extraction in VConfigModel
        self.children = nil;    // set upon the extraction in VConfigModel
        
        self.configParameter = [[VConfigParameter alloc]initWithName:inst.instanceName Type:@"" Value:[NSNumber numberWithFloat:NAN] OwnerName:@"" Instance:YES InstanceCount:inst.instanceNumber.integerValue HelpString:@""];
    }
    return self;
}

//-----------------------------------------------------------------------------

- (instancetype)initWithObjectTitle:(VConfigObject*)object
{
    self = [super init];
    if (self) {
        self.expandable = YES;
        //self.model = nil;         // set upon the extraction in VConfigModel
        
        self.parent = nil;          // set upon the extraction in VConfigModel
        self.children = nil;        // set upon the extraction in VConfigModel
        
        self.configParameter = [[VConfigParameter alloc]initWithName:object.objName Type:object.objType Value:[NSNumber numberWithFloat:NAN] OwnerName:@"" Instance:NO InstanceCount:0 HelpString:@""];
    }
    return self;
}

//Internal parameter --------------------------------------------------------------------

- (instancetype) initWithParameter:(VConfigParameter*)param {
    self = [super init];
    if (self) {
        self.expandable = NO;
        //self.model = nil;         // set upon the extraction in VConfigModel
        
        self.parent = nil;
        self.children = nil;
        self.configParameter = [param copyWithZone:nil];
        self.configParameter.instanceCount = @0;
    }
    return self;
}

//------------------------------------------------------------------------------

- (NSInteger) numberOfChildren {
    //return (self.children.count == 0) ? (-1) : self.children.count; // This is apple's example but returning -1 causes crash when children.count == 0, so just return 0
    return self.children.count;
}

//------------------------------------------------------------------------------

- (VOutlineItem*) childAtIndex:(NSUInteger)n {
    return [self.children objectAtIndex:n];
}

//------------------------------------------------------------------------------

- (VOutlineItem*) ancestor {
    VOutlineItem *anc = nil, *nextAnc = nil;
    
    if (self.parent) {
        anc = self;
        while ((nextAnc = anc.parent)) {
            anc = nextAnc;
        }
    }
    return anc;
}

//------------------------------------------------------------------------------

- (BOOL) isParentObject {
    return (self.children != nil);
}

//------------------------------------------------------------------------------


@end
