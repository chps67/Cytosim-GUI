//
//  VCymParameter.m
//  OutlineView SampleCode From Apple
//
//  Created by Chris on 06/07/2022.
//

#import "VCymParameter.h"

@implementation VCymParameter

//----------------------------------------------------------------------------------------------------------------------------

@synthesize used, cymKey, cymKeyHelpString, cymValueObject, cymValueString;

//----------------------------------------------------------------------------------------------------------------------------

+ (VCymParameter*)initWithKey:(NSString*)aKey HelpString:(NSString * _Nullable)aHelpStr Value:(id)aValue {
    VCymParameter* cP = [[VCymParameter alloc]init];
    cP.cymKey = aKey;
    cP.cymKeyHelpString = aHelpStr;
    cP.cymValueObject = aValue;
    [cP cymValueFromObject];
    cP.parent = nil;
    cP.children = nil;
    cP.used = @NO;
    return cP;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSInteger)numberOfChildren {
    // As 'numberOfChildren' is called first upon NSOutlineView filling, extract the children and place parents before anything else...
    // [self extractChildren];
    //
    //return (self.children.count == 0) ? (-1) : self.children.count;
    
    if (self.children.count == 0)
        return -1; // also returned when self.children == nil
    else
        return self.children.count;
}

//----------------------------------------------------------------------------------------------------------------------------

- (VCymParameter*)childAtIndex:(NSUInteger)n {;
    return [self.children objectAtIndex:n];
}

//----------------------------------------------------------------------------------------------------------------------------

- (VCymParameter*)ancestor {
    VCymParameter *anc = nil, *nextAnc = nil;
    
    if (self.parent) {
        anc = self;
        while ((nextAnc = anc.parent)) {
            anc = nextAnc;
        }
    }
    return anc;
}

//----------------------------------------------------------------------------------------------------------------------------
- (BOOL)isParentObject {
    return (self.children != nil);
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) cymValueFromObject {

    id obj = self.cymValueObject;
    if([obj isKindOfClass:[NSNumber class]]) {
        self.cymValueString = [(NSNumber*)obj stringValue];
    }
    if([obj isKindOfClass:[NSString class]]) {
        self.cymValueString = (NSString*)obj;
    }
    if([obj isKindOfClass:[OrderedDictionary class]]) {
        self.cymValueString = @"";
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*)cymParameterToString {
    return [@[@"    ", self.cymKey, @" = ", self.cymValueString, @"\n"] componentsJoinedByString:@""];
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*)trimmedCymKey {
    NSArray* components = [self.cymKey componentsSeparatedByString:@" "];
    NSString* cleanKeyName = [NSString stringWithString:[components firstObject]];
    return cleanKeyName;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*) ownerName {
    NSArray* components = [self.cymKey componentsSeparatedByString:@" "];
    NSString* owner = [NSString stringWithString:[components lastObject]];
    owner = [owner stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    return owner;
}

//--- OVERRIDE ---------------------------------------------------------------------------------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    VCymParameter* copiedObj = [[VCymParameter alloc]init];
    copiedObj.used = [NSNumber numberWithBool: self.used.boolValue];
    copiedObj.cymKey = [NSString stringWithString:self.cymKey];
    copiedObj.cymValueObject = [self.cymValueObject copyWithZone:nil];
    copiedObj.cymValueString = [NSString stringWithString:self.cymValueString];
    copiedObj.cymKeyHelpString = [NSString stringWithString:self.cymKeyHelpString];
    copiedObj.parent = [self.parent copyWithZone:nil];
    copiedObj.children = [self.children copyWithZone:nil];
    return copiedObj;
}

@end
