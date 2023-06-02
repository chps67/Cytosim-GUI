//
//  VConfigObject.m
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import "VConfigObject.h"
#import "VConfigParameter.h"

@implementation VConfigObject

@synthesize objType, objName, objParameters;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.objType = @"";
        self.objName = @"";
        self.objParameters = [NSMutableArray arrayWithCapacity:0];
        self.objCode = @"";
        self.objRange = NSMakeRange(0, 0);
    }
    return self;
}

//-----------------------------------------------------------------------------

-(VConfigParameter*) parameterWithName:(NSString*)name {
   
    VConfigParameter* answer = nil;
    
    for (VConfigParameter* par in self.objParameters) {
        if ([par.paramName isEqualToString:name]){
            answer = par;
            break;
        }
    }
    return answer;
}

//-----------------------------------------------------------------------------

- (BOOL) canVary {
    BOOL answer = NO;
    
    for (VConfigParameter* param in self.objParameters) {
        answer = [param isNumeric];
        if (answer == YES)
            break;
    }
    return answer;
}
//-----------------------------------------------------------------------------

- (void) changeParameterNamed:(NSString*)paramName WithValue:(NSNumber*)newValue {

    for (VConfigParameter* param in self.objParameters) {
        if ([param.paramName isEqualToString:paramName]) {
            param.paramNumValue = [newValue copy];
            param.paramStringValue = param.paramNumValue.stringValue;
        }
    }
}

//-----------------------------------------------------------------------------

-(NSString*) codeFromObject {
    
    // object parameter extraction splits parameters with multiple variables separated by commas
    // into 'paramName[k] = kth' value to identify those that can vary numerically
    // This is the right place to do the reverse assembly and completely rebuild the code, including from these parameters
    // This would yield 'paramName = k0, k1, k2'
    
    NSCharacterSet* subArraySet = [NSCharacterSet characterSetWithCharactersInString:@"[0123456789]"];

    NSString* code = [@[@"set", self.objType, self.objName, @"\n"] componentsJoinedByString:@" "];
    NSString* open = @"{\n";
    NSString* close = @"}\n";
    
    code = [code stringByAppendingString:open];
    NSString* paramString = @"";
    NSString* prevIndexedName = @"";
    
    for (NSInteger k = 0; k < self.objParameters.count; k ++) {
        VConfigParameter* p = [self.objParameters objectAtIndex:k];
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


@end
