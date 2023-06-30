//
//  VParameterVariations.m
//  Cytosim GUI
//
//  Created by Chris on 12/01/2023.
//

#import "VParameterVariations.h"

@implementation VParameterVariations


- (instancetype) initWithValue:(NSNumber*) value {
    self = [super init];
    if (self) {
        self.active = @NO;
        self.variationType = linearType;
        self.minX = [NSNumber numberWithFloat:NAN];
        self.maxX = [NSNumber numberWithFloat:NAN];
        self.minY = value;
        self.maxY = value;
        self.p1 = @1.0;
        self.p2 = @0.0;
        self.p3 = @0.0;
        self.p4 = @0.0;
        self.variationValues = [NSMutableArray arrayWithCapacity:0];

        // Hold copies of minY = maxY into the variations array
        [self.variationValues addObject:[self.minY copy]];
        
        self.numberOfValues = [NSNumber numberWithInteger:self.variationValues.count];
    }
    return self;
}

//-----------------------------------------------------------------------------

-(void) collectValues {
    
    // xStep value for the inner points (without the 2 extremities)
    float xStep = self.maxX.floatValue - self.minX.floatValue;
    
    if (self.numberOfValues.integerValue >= 2) {
        
        xStep = (self.maxX.floatValue - self.minX.floatValue)/(self.numberOfValues.integerValue - 1);
        
        float x = self.minX.floatValue;
        int count = 0;
        
        [self.variationValues removeAllObjects];
        while (count < self.numberOfValues.integerValue) {
            NSNumber* valNum = [self valueForStep:[NSNumber numberWithFloat:x]];
            [self.variationValues addObject:valNum];
            x += xStep;
            count++;
        }
        
        self.minY = ((NSNumber*)self.variationValues.firstObject);
        self.maxY = ((NSNumber*)self.variationValues.lastObject);
    }
}

//-----------------------------------------------------------------------------

-(NSNumber*) valueForStep:(NSNumber*)x {
    
    NSNumber* output = nil;
    
    switch (self.variationType) {
            
        case linearType:
            if (self.p1)
                output = [NSNumber numberWithFloat: self.p1.floatValue * x.floatValue + self.p2.floatValue];
            break;
            
        case logType:
            if (self.p1)
                if (self.p1.floatValue > 0)
                    output = [NSNumber numberWithFloat:self.p1.floatValue * log10(x.floatValue) + self.p2.floatValue];
            break;
            
        case sqrtType:
            if (self.p1)
                if (self.p1.floatValue >= 0)
                output = [NSNumber numberWithFloat:self.p1.floatValue * sqrt(x.floatValue) + self.p2.floatValue];
            break;
            
        case exponentialType:
            if (self.p1 && self.p2)
                output = [NSNumber numberWithFloat:self.p1.floatValue * pow(10.0, self.p2.floatValue * x.floatValue) + self.p3.floatValue];
            break;
            
        case quadraticType:
            if (self.p1 && self.p2)
                output = [NSNumber numberWithFloat:self.p1.floatValue * x.floatValue*x.floatValue + self.p2.floatValue * x.floatValue + self.p3.floatValue];
            break;
            
        case cubicType:
            if (self.p1 && self.p2 && self.p3)
                output = [NSNumber numberWithFloat:self.p1.floatValue * x.floatValue*x.floatValue*x.floatValue + self.p2.floatValue * x.floatValue*x.floatValue + self.p3.floatValue * x.floatValue + self.p4.floatValue];
            break;
            
        case randomType:
            output = [NSNumber numberWithFloat:(float)[self randomBetweenMin:self.minX.doubleValue andMax:self.maxX.doubleValue]];
            break;
            
        default:
            output = x;
            break;
    }
    return output;
}
//-----------------------------------------------------------------------------

- (double) randomBetweenMin:(double)minD andMax:(double)maxD {
 return drand48() * (maxD - minD) + minD;
}

//-----------------------------------------------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    
    VParameterVariations* var = [[VParameterVariations alloc]init];
    var.variationType = self.variationType;
    var.active = [NSNumber numberWithBool:self.active.boolValue];
    var.numberOfValues = [NSNumber numberWithInteger:self.numberOfValues.integerValue];
    var.minX = [NSNumber numberWithFloat:self.minX.floatValue];
    var.maxX = [NSNumber numberWithFloat:self.maxX.floatValue];
    var.minY = [NSNumber numberWithFloat:self.minY.floatValue];
    var.maxY = [NSNumber numberWithFloat:self.maxY.floatValue];
    var.p1 = [NSNumber numberWithFloat:self.p1.floatValue];
    var.p2 = [NSNumber numberWithFloat:self.p2.floatValue];
    var.p3 = [NSNumber numberWithFloat:self.p3.floatValue];
    var.p4 = [NSNumber numberWithFloat:self.p4.floatValue];

    [var.variationValues removeAllObjects];
    for (NSInteger k=0; k< self.variationValues.count; k++) {
        NSNumber* vn = [[self.variationValues objectAtIndex:k] copy];
        [var.variationValues addObject:vn];
    }
    return var;
}


@end
