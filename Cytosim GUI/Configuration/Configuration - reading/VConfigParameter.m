//
//  VConfigParameter.m
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import "VConfigParameter.h"

@implementation VConfigParameter

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.variations = [[VParameterVariations alloc]init];
        
        self.ownerName = @"";
        self.ownerType = @"";
        self.paramName = @"";
        self.paramHelp = @"";
        
        self.paramNumValue = [NSNumber numberWithFloat:NAN];
        self.paramStringValue = @"";
        
        self.ownerIsInstance = NO;
        self.instanceCount = [NSNumber numberWithFloat:NAN];
    }
    return self;
}

//-------------------------------------------------------------------------------------------

- (instancetype) initWithName:(NSString*) paramName Type:(NSString*)type Value:(NSNumber*)value OwnerName:(NSString*)ownerName Instance:(BOOL)instance InstanceCount:(NSInteger)instanceCount HelpString:(NSString*) help {
    
    self = [super init];
    if (self) {
        
        NSNumber* targetValue;
        (instanceCount >0) ? (targetValue = [NSNumber numberWithInteger:instanceCount]) : (targetValue = value);
        
        self.paramName = paramName;
        self.ownerName = ownerName;
        self.ownerType = type;
        self.ownerIsInstance = instance;
        self.instanceCount = [NSNumber numberWithInteger:instanceCount];
        self.paramNumValue = targetValue;
        self.paramStringValue = targetValue.stringValue;
        self.paramHelp = help;
        self.variations = [[VParameterVariations alloc] initWithValue:targetValue];
    }
    return self;
}
//-------------------------------------------------------------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    
    VConfigParameter* paramCopy = [[VConfigParameter alloc]init];
    
    paramCopy.ownerName = [NSString stringWithString:self.ownerName];
    paramCopy.ownerIsInstance = self.ownerIsInstance;
    paramCopy.instanceCount = self.instanceCount;
    paramCopy.paramName = [NSString stringWithString:self.paramName];
    paramCopy.paramStringValue = [NSString stringWithString:self.paramStringValue];
    paramCopy.paramNumValue = self.paramNumValue;
    paramCopy.paramRange = self.paramRange;

    if (self.paramHelp != nil)
        paramCopy.paramHelp = [NSString stringWithString:self.paramHelp];

    paramCopy.variations = [[VParameterVariations alloc] initWithValue:self.paramNumValue];
    
    return paramCopy;
}

//-------------------------------------------------------------------------------------------

- (BOOL) validateDX {
    const float epsilon = 1e-4;
    BOOL ok = NO;
    
    if (self.variations.minX && self.variations.maxX) {
        ok =   (self.variations.minX.floatValue != NAN) &&
        (self.variations.maxX.floatValue != NAN) &&
        ((self.variations.maxX.floatValue - self.variations.minX.floatValue) > epsilon);
    }
    
    return ok;
}

//-------------------------------------------------------------------------------------------

- (BOOL) isNumeric {
    BOOL answer = NO;
    
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];
    
    NSNumber* num = nil;
    
    if (self.ownerIsInstance && ([self.ownerName isEqualToString:@"instance"])) {
        num = [form numberFromString:self.instanceCount.stringValue];
    } else {
        num = [form numberFromString:self.paramStringValue];
    }
    if (num != nil) {   // the parameter value should be strictly numeric
        answer = YES;
    }
    
    return answer;
}
//-------------------------------------------------------------------------------------------

- (void) copyContentsWithoutVariationsFrom:(VConfigParameter*) param {
    
    self.ownerName = [NSString stringWithString:param.ownerName];
    self.ownerType = [NSString stringWithString:param.ownerType];
    self.ownerIsInstance = param.ownerIsInstance;
    self.instanceCount = [param.instanceCount copy];
    
    self.paramName = [NSString stringWithString:param.paramName];
    self.paramHelp = [NSString stringWithString:param.paramHelp];
    self.paramStringValue = [NSString stringWithString:param.paramStringValue];
    self.paramNumValue = [param.paramNumValue copy];
    self.paramRange = param.paramRange;
}

- (VConfigParameter*) copyVariationIntoParameter {
    return [self.variations copyWithZone:nil];
}

//-------------------------------------------------------------------------------------------
// Check every content EXCEPT variations

- (BOOL) isEqualToParameter:(VConfigParameter*)param {
    
    BOOL answer = NO;
    
    if ([self.ownerName isEqualToString:param.ownerName]) {
        if ([self.ownerType isEqualToString:param.ownerType]) {
            if (self.ownerIsInstance == param.ownerIsInstance) {
                if (self.instanceCount.integerValue == param.instanceCount.integerValue) {
                    if ([self.paramName isEqualToString:param.paramName]) {
                        if (self.paramNumValue.floatValue == param.paramNumValue.floatValue) {
                            answer = YES;
                        }
                    }
                }
            }
        }
    }
    return answer;
}

//-------------------------------------------------------------------------------------------

- (void) changeValue:(NSNumber*) newValue {
    self.paramNumValue = [newValue copy];
    self.paramStringValue = [newValue.stringValue copy];
}

@end
