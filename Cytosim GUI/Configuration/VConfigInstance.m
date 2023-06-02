//
//  VConfigInstance.m
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import "VConfigInstance.h"
#import "VConfigParameter.h"

@implementation VConfigInstance

@synthesize instanceName, instanceNumber, instanceParameters;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.instanceName = @"";
        self.instanceNumber = @0;
        self.instanceParameters = [NSMutableArray arrayWithCapacity:0];
        self.instanceCode = @"";
        self.instanceRange = NSMakeRange(0, 0);
    }
    return self;
}

//-----------------------------------------------------------------------------

-(VConfigParameter*) parameterWithName:(NSString*)name {
   
    VConfigParameter* answer = nil;
    
    for (VConfigParameter* par in self.instanceParameters) {
        if ([par.paramName isEqualToString:name]){
            answer = par;
            break;
        }
    }
    return answer;
}

//-----------------------------------------------------------------------------

- (BOOL) canVary {
//    BOOL answer = NO;
//    for (VConfigParameter* param in self.instanceParameters) {
//        answer = [param isNumeric];
//        if (answer == YES)
//            break;
//    }
//    return answer;
    return YES; // variation of the instance number is always possible !
}

//-----------------------------------------------------------------------------

-(NSString*) codeFromInstance {
    
    // instance parameter extraction splits parameters with multiple variables separated by commas
    // into 'paramName[k] = kth' value to identify those that can vary numerically
    // This is the right place to do the reverse assembly and completely rebuild the code, including from these parameters
    // This would yield 'paramName = k0, k1, k2'

    NSCharacterSet* subArraySet = [NSCharacterSet characterSetWithCharactersInString:@"[0123456789]"];
    NSString* code = [@[@"new", self.instanceNumber, self.instanceName, @"\n"] componentsJoinedByString:@" "];
    NSString* open = @"{\n";
    NSString* close = @"}\n";
    
    code = [code stringByAppendingString:open];
    NSString* paramString = @"";
    NSString* prevIndexedName = @"";
    
    for (NSInteger k = 0; k < self.instanceParameters.count; k ++) {
        VConfigParameter* p = [self.instanceParameters objectAtIndex:k];
        if ([p.paramName containsString:@"["]) {
            NSString* newIndexedName = [p.paramName stringByTrimmingCharactersInSet:subArraySet];
            if ([newIndexedName isEqualToString:prevIndexedName]) {
                paramString = [paramString stringByAppendingString:@", "];
                paramString = [paramString stringByAppendingString:p.paramStringValue];
                paramString = [paramString stringByAppendingString:@"\n"];
                k++;
            } else {
                paramString = [@[@"\t",newIndexedName,@"=",p.paramStringValue] componentsJoinedByString:@" "];
            }
            prevIndexedName = [newIndexedName copy];
        } else {
            paramString = [@[@"\t",p.paramName,@"=",p.paramStringValue,@"\n"] componentsJoinedByString:@" "];
        }
        code = [code stringByAppendingString:paramString];
        paramString = @"";
    }
    code = [code stringByAppendingString:close];
    return code;
}

//-----------------------------------------------------------------------------

- (void) changeParameterNamed:(NSString*)paramName WithValue:(NSNumber*) newValue {
    
    for (VConfigParameter* param in self.instanceParameters) {
        if ([param.paramName isEqualToString:paramName]) {
            param.paramNumValue = [newValue copy];
            param.paramStringValue = param.paramNumValue.stringValue;
        }
    }
}

-(void) changeCountWithValue:(NSNumber*) newValue {
    self.instanceNumber = [newValue copy];
}

@end
